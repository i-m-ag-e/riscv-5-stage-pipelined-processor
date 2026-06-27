import pipeline_reg_types::mem_wb_reg_t;

module reg_mem_wb (
    input logic clk,
    input logic rst_n,
    input logic stall,

    input  mem_wb_reg_t i_data,
    output mem_wb_reg_t o_data
);

    always_ff @(posedge clk) begin
        if (!rst_n) o_data <= {$bits(mem_wb_reg_t) {1'b0}};
        else if (!stall) o_data <= i_data;
    end

endmodule
