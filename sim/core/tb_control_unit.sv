`timescale 1ns / 1ps

import alu_definitions::*;
import riscv_opcodes::*;

module tb_control_unit ();

    logic [6:0] i_opcode;
    logic o_branch;
    logic o_jump;
    logic o_jump_reg;
    logic o_pc_result_to_reg;
    logic o_mem_read;
    logic o_mem_to_reg;
    logic o_mem_write;
    logic o_reg_write;
    logic o_rs1_zero;
    alu_op_t o_alu_op;

    control_unit uut (
        .i_opcode(i_opcode),
        .o_branch(o_branch),
        .o_jump(o_jump),
        .o_jump_reg(o_jump_reg),
        .o_pc_result_to_reg(o_pc_result_to_reg),
        .o_mem_read(o_mem_read),
        .o_mem_to_reg(o_mem_to_reg),
        .o_mem_write(o_mem_write),
        .o_reg_write(o_reg_write),
        .o_rs1_zero(o_rs1_zero),
        .o_alu_op(o_alu_op)
    );

    int errors = 0;

    task check(input logic [6:0] op, input logic [8:0] expected_flags, input alu_op_t expected_alu);
        logic [8:0] actual_flags;
        i_opcode = op;
        #1;
        // pack outputs into a single vector for easy comparison
        // {branch, jump, jump_reg, pc_res, mem_r, mem_to_reg, mem_w, reg_w, rs1_z}
        actual_flags = {
            o_branch,
            o_jump,
            o_jump_reg,
            o_pc_result_to_reg,
            o_mem_read,
            o_mem_to_reg,
            o_mem_write,
            o_reg_write,
            o_rs1_zero
        };

        if (actual_flags !== expected_flags || o_alu_op !== expected_alu) begin
            $display("ERROR for opcode %b: expected flags=%b alu=%0d, got flags=%b alu=%0d", op,
                     expected_flags, expected_alu, actual_flags, o_alu_op);
            errors++;
        end
    endtask

    initial begin
        $dumpfile("sim/tb_control_unit.vcd");
        $dumpvars(0, tb_control_unit);

        // check(opcode, expected_flags, expected_alu)
        // flags: {branch, jump, jump_reg, pc_res, mem_r, mem_to_reg, mem_w, reg_w, rs1_z}
        check(OPCODE_RTYPE, 9'b000_000_010, ALUOpRType);
        check(OPCODE_IMM, 9'b000_000_010, ALUOpIType);
        check(OPCODE_JAL, 9'b010_100_010, ALUOpJLType);
        check(OPCODE_JALR, 9'b011_100_010, ALUOpJLType);
        check(OPCODE_BRANCH, 9'b100_000_000, ALUOpBType);
        check(OPCODE_LOAD, 9'b000_011_010, ALUOpJLType);
        check(OPCODE_LUI, 9'b000_000_011, ALUOpJLType);
        check(OPCODE_AUIPC, 9'b000_100_010, ALUOpJLType);
        check(OPCODE_STORE, 9'b000_000_100, ALUOpJLType);
        check(7'b0000000, 9'b000_000_000, ALUOpJLType);  // Invalid

        if (errors == 0) $display("tb_control_unit: PASS");
        else $display("tb_control_unit: FAIL with %0d errors", errors);

        $finish;
    end

endmodule
