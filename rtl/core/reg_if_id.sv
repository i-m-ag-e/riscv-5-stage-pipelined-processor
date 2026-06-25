import pipeline_reg_types::if_id_reg_t;

module reg_if_id (
    input logic clk,
    input logic rst_n,
    input logic flush,
    input logic stall,

    input  if_id_reg_t i_data,
    output if_id_reg_t o_data
);
    always_ff @(posedge clk) begin
        if (!rst_n || (!stall && flush)) o_data <= {$bits(if_id_reg_t) {1'b0}};
        else if (!stall) begin
            o_data <= i_data;
        end
    end

endmodule
