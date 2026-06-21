import pipeline_reg_types::id_ex_reg_t;

module reg_id_ex (
    input logic clk,
    input logic rst_n,
    input logic flush,

    input  id_ex_reg_t i_data,
    output id_ex_reg_t o_data
);

    always_ff @(posedge clk) begin
        if (!rst_n || flush) begin
            o_data <= {$bits(id_ex_reg_t) {1'b0}};
        end
        else o_data <= i_data;
    end

endmodule
