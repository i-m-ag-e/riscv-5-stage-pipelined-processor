import json
import subprocess
import sys
import re
import os

def run_test(config_file):
    with open(config_file, 'r') as f:
        config = json.load(f)
    
    asm_file = config['assembly']
    checks = config['checks']
    
    print(f"--- Running Test: {config_file} ---")
    
    # Compile the specific assembly file to firmware.mem
    cmd = f"riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -T firmware/linker.ld firmware/crt0.S -o firmware.elf {asm_file} && riscv64-unknown-elf-objcopy -O binary firmware.elf firmware.bin && hexdump -v -e '1/4 \"%08x\" \"\\n\"' firmware.bin > firmware.mem"
    
    try:
        subprocess.run(cmd, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError as e:
        print(f"Assembly compilation failed:\n{e.stderr.decode()}")
        sys.exit(1)
    
    # Run the top level simulation executable
    # Assumes 'make sim' or at least 'make test_top' was previously run so ./obj_dir/Vtb_top exists.
    if not os.path.exists("./obj_dir/Vtb_top"):
        print("Verilator executable not found. Please run 'make test_top' first.")
        sys.exit(1)

    res = subprocess.run(["./obj_dir/Vtb_top"], capture_output=True, text=True)
    out = res.stdout
    
    # Check for timeout or failure to finish
    if "TIMEOUT" in out:
        print("Simulation TIMED OUT! The CPU never reached the success/halt state.")
        sys.exit(1)
    
    # Parse state
    state = {}
    in_state = False
    for line in out.splitlines():
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
                    
    errors = 0
    for key, expected in checks.items():
        actual = state.get(key, 0) # Defaults to 0 if not dumped
        if actual != expected:
            print(f"[FAIL] {key} expected {expected}, got {actual}")
            errors += 1
        else:
            print(f"[PASS] {key} == {expected}")
            
    if errors == 0:
        print(f"--- Result: ALL PASSED ---\n")
    else:
        print(f"--- Result: {errors} FAILED ---\n")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 run_test.py <path_to_config.json>")
        sys.exit(1)
    run_test(sys.argv[1])
