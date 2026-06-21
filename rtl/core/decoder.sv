import instruction_type::*;
import riscv_opcodes::*;

module decoder (
    input logic [31:0] i_instruction,

    output instruction_type_t o_inst_type,
    output logic [6:0] o_opcode,
    output logic [4:0] o_rs1,
    output logic [4:0] o_rs2,
    output logic [4:0] o_rd,
    output logic [2:0] o_funct3,
    output logic [6:0] o_funct7
);

    assign o_opcode = i_instruction[6:0];
    assign o_rs1    = i_instruction[19:15];
    assign o_rs2    = i_instruction[24:20];
    assign o_rd     = i_instruction[11:7];

    assign o_funct3 = i_instruction[14:12];
    assign o_funct7 = i_instruction[31:25];

    always_comb begin
        casez (i_instruction)
            ADD, AND, OR, SUB, XOR: o_inst_type = InstRType;

            ADDI, ANDI, JALR, LB, LH, LW,  //
            LBU, LHU, ORI, SLTI, SLTIU, SLLI, SRLI, SRAI, XORI: begin
                o_inst_type = InstIType;
            end

            SB, SH, SW: o_inst_type = InstSType;
            BEQ, BNE, BLT, BGE, BLTU, BGEU: o_inst_type = InstBType;
            LUI, AUIPC: o_inst_type = InstUType;
            JAL: o_inst_type = InstJType;
            default: o_inst_type = InstRType;
        endcase
    end

endmodule
