import alu_definitions::*;
import riscv_opcodes::*;

module control_unit (
    input logic [6:0] i_opcode,

    output logic o_branch,
    output logic o_jump,
    output logic o_jump_reg,
    output logic o_pc_result_to_reg,
    output logic o_mem_read,
    output logic o_mem_to_reg,
    output logic o_mem_write,
    output logic o_reg_write,
    output logic o_rs1_zero,

    output alu_op_t o_alu_op
);

    always_comb begin
        o_branch           = 1'b0;
        o_jump             = 1'b0;
        o_jump_reg         = 1'b0;
        o_pc_result_to_reg = 1'b0;
        o_mem_read         = 1'b0;
        o_mem_to_reg       = 1'b0;
        o_mem_write        = 1'b0;
        o_reg_write        = 1'b0;
        o_rs1_zero         = 1'b0;
        o_alu_op           = ALUOpRType;

        casez (i_opcode)
            OPCODE_RTYPE: begin
                o_reg_write = 1'b1;
                o_alu_op    = ALUOpRType;
            end
            OPCODE_IMM: begin
                o_reg_write = 1'b1;
                o_alu_op    = ALUOpIType;
            end
            OPCODE_JAL: begin
                o_jump             = 1'b1;
                o_reg_write        = 1'b1;
                o_pc_result_to_reg = 1'b1;

                o_alu_op           = ALUOpJLType;
            end
            OPCODE_JALR: begin
                o_jump             = 1'b1;
                o_reg_write        = 1'b1;
                o_pc_result_to_reg = 1'b1;
                o_jump_reg         = 1'b1;

                o_alu_op           = ALUOpJLType;
            end
            OPCODE_BRANCH: begin
                o_branch = 1'b1;

                o_alu_op = ALUOpBType;
            end
            OPCODE_LOAD: begin
                o_mem_read   = 1'b1;
                o_mem_to_reg = 1'b1;
                o_reg_write  = 1'b1;

                o_alu_op     = ALUOpJLType;
            end
            OPCODE_LUI: begin
                o_rs1_zero  = 1'b1;
                o_reg_write = 1'b1;

                o_alu_op    = ALUOpJLType;
            end
            OPCODE_AUIPC: begin
                o_reg_write        = 1'b1;
                o_pc_result_to_reg = 1'b1;

                o_alu_op           = ALUOpJLType;
            end
            OPCODE_STORE: begin
                o_mem_write = 1'b1;

                o_alu_op    = ALUOpJLType;
            end
            default: ;
        endcase
    end

endmodule
