import riscv_opcodes::OPCODE_AUIPC;

module branch_unit (
    input logic i_jump_reg,
    input logic i_branch,
    input logic [2:0] i_funct3,
    input logic [6:0] i_opcode,

    input logic [31:0] i_pc,
    input logic [31:0] i_imm,

    input logic [31:0] i_rs1_data,
    input logic [31:0] i_rs2_data,

    output logic o_branch_taken,
    output logic [31:0] o_pc_rel_addr,
    output logic [31:0] o_target_addr
);

    logic [31:0] adder_base, adder_target;

    assign adder_base = i_jump_reg ? i_rs1_data : i_pc;

    branch_adder branch_adder (
        .i_base       (adder_base),
        .i_imm        (i_imm),
        .o_target_addr(adder_target)
    );

    logic branch_eq, branch_lt, is_unsigned;
    assign is_unsigned = i_branch && (i_funct3 == 3'b110 || i_funct3 == 3'b111);

    branch_comparator branch_comparator (
        .i_data_A       (i_rs1_data),
        .i_data_B       (i_rs2_data),
        .i_unsigned_comp(is_unsigned),
        .o_branch_eq    (branch_eq),
        .o_branch_lt    (branch_lt)
    );

    always_comb begin
        case (i_funct3)
            3'b000: o_branch_taken = branch_eq;
            3'b001: o_branch_taken = ~branch_eq;
            3'b100, 3'b110: o_branch_taken = branch_lt;
            3'b101, 3'b111: o_branch_taken = ~branch_lt;
            default: o_branch_taken = 1'b0;
        endcase
    end

    assign o_target_addr = i_jump_reg ? {adder_target[31:1], 1'b0} : adder_target;
    assign o_pc_rel_addr = (i_opcode == OPCODE_AUIPC) ? adder_target : (i_pc + 4);

endmodule
