import pipeline_reg_types::ex_mem_reg_t;

module reg_ex_mem (
    input clk,
    input rst_n,
    input ex_mem_reg_t i_data,
    output ex_mem_reg_t o_data
);

    always_ff @(posedge clk) begin
        if (!rst_n) o_data <= {$bits(ex_mem_reg_t) {1'b0}};
        else o_data <= i_data;
    end

endmodule
