# I used GenAI to help with the creation and formatting of this file
# This is used by the make verify* and make run targets

# With --run option:
# - compiles given C/ASM file and links it with firmware/crt0.s
# - executes it 
# - prints out a dump showing all registers and non-zero memory locations in the RAM
#   (actually handled by the testbench invoked by this file)

# Without that:
# - reads a *.json config passed as argument
# - compiles file given in the "assembly" entry in the json file
# - executes and prints the dump
# - compares the dump against the assertions given under "checks" in the JSON file

import json
import subprocess
import sys
import re
import os
import argparse

ARCH_EXECUTABLES = {
    "tcm":  "./obj_dir/Vtb_top_tcm",
    "wb":   "./obj_dir/Vtb_wb",
    "mega": "./obj_dir/Vtb_mega",
}

def compile_firmware(asm_or_c_file):
    """Compile an assembly or C file to firmware.mem."""
    cmd = (
        f"riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles "
        f"-T firmware/linker.ld firmware/crt0.S -o firmware.elf {asm_or_c_file} && "
        f"riscv64-unknown-elf-objcopy -O binary firmware.elf firmware.bin && "
        f"hexdump -v -e '1/4 \"%08x\" \"\\n\"' firmware.bin > firmware.mem"
    )
    try:
        subprocess.run(cmd, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError as e:
        print(f"Compilation failed:\n{e.stderr.decode()}")
        sys.exit(1)

def run_simulation(arch):
    """Run the Verilator executable for the given architecture."""
    exe = ARCH_EXECUTABLES[arch]
    if not os.path.exists(exe):
        print(f"Verilator executable not found: {exe}")
        print(f"Please run 'make test_top_tcm', 'make test_wb', or 'make test_mega' first.")
        sys.exit(1)
    return subprocess.run([exe], capture_output=True, text=True)

def parse_state(output):
    """Parse === FINAL STATE === block from simulation output."""
    state = {}
    in_state = False
    for line in output.splitlines():
        if line == "=== FINAL STATE ===":
            in_state = True
            continue
        if line == "===================":
            in_state = False
            continue
        if in_state:
            match = re.match(r"(REG|DMEM)\[(\d+)\]\s*=\s*(-?\d+)", line.strip())
            if match:
                typ, idx, val = match.groups()
                if typ == "REG":
                    state[f"x{idx}"] = int(val)
                else:
                    state[f"dmem[{idx}]"] = int(val)
    return state

register_mapping = {
    "ra": "x1",
    "sp": "x2",
    "gp": "x3",
    "tp": "x4",
    "t0": "x5",
    "t1": "x6",
    "t2": "x7",
    "s0": "x8",
    "fp": "x8",
    "s1": "x9",
    "a0": "x10",
    "a1": "x11",
    "a2": "x12",
    "a3": "x13",
    "a4": "x14",
    "a5": "x15",
    "a6": "x16",
    "a7": "x17",
    "s2": "x18",
    "s3": "x19",
    "s4": "x20",
    "s5": "x21",
    "s6": "x22",
    "s7": "x23",
    "s8": "x24",
    "s9": "x25",
    "s10": "x26",
    "s11": "x27",
    "t3": "x28",
    "t4": "x29",
    "t5": "x30",
    "t6": "x31"
}

def run_test(config_file, arch):
    with open(config_file, 'r') as f:
        config = json.load(f)
    
    asm_file = config['assembly']
    checks = config['checks']
    
    print(f"--- Running Test: {config_file} ({arch}) ---")
    
    compile_firmware(asm_file)
    res = run_simulation(arch)
    out = res.stdout
    
    # Check for timeout
    if "TIMEOUT" in out:
        print("Simulation TIMED OUT! The CPU never reached the success/halt state.")
        sys.exit(1)
    
    # Parse register/memory state
    state = parse_state(out)
    
    # Check expected values
    errors = 0
    for key, expected in checks.items():
        hex_match = re.match(r"dmem\[0x([0-9a-fA-F]+)\]", key)
        if hex_match:
            key = f"dmem[{int(hex_match.group(1), 16)}]"
        actual = state.get(register_mapping.get(key, key), 0)
        if type(expected) == str and expected.startswith("0x"):
            expected = int(expected[2:], 16)
        if actual != expected:
            print(f"[FAIL] {key} expected {expected}, got {actual}")
            errors += 1
        else:
            print(f"[PASS] {key} == {expected}")

    # For mega mode, also check for architecture comparison result
    if arch == "mega":
        if "MISMATCH" in out:
            print("[FAIL] TCM vs WB state mismatch detected")
            errors += 1
        elif "Both architectures match" in out:
            print("[PASS] TCM == WB (all registers and memory match)")

    if errors == 0:
        print(f"--- Result: ALL PASSED ---\n")
    else:
        print(f"--- Result: {errors} FAILED ---\n")
        sys.exit(1)

def run_program(source_file, arch):
    """Compile and run a program, printing the final state without any checks."""
    print(f"--- Running: {source_file} ({arch}) ---")
    compile_firmware(source_file)
    res = run_simulation(arch)
    # Print full simulation output
    print(res.stdout)
    if res.returncode != 0:
        print(res.stderr)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="RISC-V Processor Test Runner")
    parser.add_argument("config", nargs="?", help="Path to test config JSON file")
    parser.add_argument("--arch", choices=["tcm", "wb", "mega"], default="tcm",
                        help="Architecture to test (default: tcm)")
    parser.add_argument("--run", metavar="FILE",
                        help="Run a program (assembly or C) without checks, just dump state")
    
    args = parser.parse_args()
    
    if args.run:
        run_program(args.run, args.arch)
    elif args.config:
        run_test(args.config, args.arch)
    else:
        parser.print_help()
        sys.exit(1)
