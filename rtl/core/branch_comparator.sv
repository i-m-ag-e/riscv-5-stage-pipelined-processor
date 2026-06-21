module branch_comparator (
    input logic [31:0] i_data_A,
    input logic [31:0] i_data_B,
    input logic i_unsigned_comp,

    output logic o_branch_eq,
    output logic o_branch_lt
);

    always_comb begin
        o_branch_eq = i_data_A == i_data_B;

        if (!i_unsigned_comp && i_data_A[31] != i_data_B[31]) o_branch_lt = i_data_A[31];
        else o_branch_lt = i_data_A < i_data_B;
    end

endmodule
