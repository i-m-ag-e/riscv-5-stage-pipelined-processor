module data_memory #(
    parameter int RAM_ADDR_WIDTH = 16,
    parameter string INIT_FILE = ""
) (
    input logic clk,

    input logic i_mem_read,
    input logic i_mem_write,

    input  logic [31:0] i_addr,
    input  logic [31:0] i_write_data,
    input  logic [ 3:0] i_byte_en,
    output logic [31:0] o_data
);

    logic [31:0] ram[(1 << RAM_ADDR_WIDTH)];

    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, ram);
        end
    end

    wire [RAM_ADDR_WIDTH - 1:0] word_addr = i_addr[RAM_ADDR_WIDTH+1:2];

    always_ff @(posedge clk) begin
        if (i_mem_read) o_data <= ram[word_addr];
        if (i_mem_write) begin
            if (i_byte_en[0]) ram[word_addr][7:0] <= i_write_data[7:0];
            if (i_byte_en[1]) ram[word_addr][15:8] <= i_write_data[15:8];
            if (i_byte_en[2]) ram[word_addr][23:16] <= i_write_data[23:16];
            if (i_byte_en[3]) ram[word_addr][31:24] <= i_write_data[31:24];
        end
    end

endmodule
