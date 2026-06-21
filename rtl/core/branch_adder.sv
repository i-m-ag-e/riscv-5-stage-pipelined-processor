module branch_adder (
    input logic [31:0] i_base,
    input logic [31:0] i_imm,

    output logic [31:0] o_target_addr
);

    assign o_target_addr = i_base + i_imm;

endmodule
