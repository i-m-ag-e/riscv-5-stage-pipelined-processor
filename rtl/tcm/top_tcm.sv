module top_tcm #(
    parameter int ROM_ADDR_WIDTH = 9,
    parameter string ROM_INIT_FILE = "firmware.mem",
    parameter int RAM_ADDR_WIDTH = 12,
    parameter string RAM_INIT_FILE = ""
) (
    input logic clk,
    input logic rst_n
);

    logic [31:0] imem_addr;
    logic [31:0] imem_instr;

    logic [31:0] dmem_addr;
    logic dmem_read;
    logic dmem_write;
    logic [31:0] dmem_rdata;
    logic [31:0] dmem_wdata;
    logic [3:0] dmem_byte_en;

    instruction_memory #(
        .INST_ADDR_WIDTH(ROM_ADDR_WIDTH),
        .INIT_FILE      (ROM_INIT_FILE)
    ) instruction_memory (
        .clk          (clk),
        .i_addr       (imem_addr),
        .o_instruction(imem_instr)
    );

    data_memory #(
        .RAM_ADDR_WIDTH(RAM_ADDR_WIDTH),
        .INIT_FILE     (RAM_INIT_FILE)
    ) data_memory (
        .clk         (clk),
        .i_mem_read  (dmem_read),
        .i_mem_write (dmem_write),
        .i_addr      (dmem_addr),
        .i_write_data(dmem_wdata),
        .i_byte_en   (dmem_byte_en),
        .o_data      (dmem_rdata)
    );

    datapath_tcm datapath (
        .clk           (clk),
        .rst_n         (rst_n),
        .i_imem_instr  (imem_instr),
        .i_dmem_rdata  (dmem_rdata),
        .o_imem_addr   (imem_addr),
        .o_dmem_addr   (dmem_addr),
        .o_dmem_read   (dmem_read),
        .o_dmem_write  (dmem_write),
        .o_dmem_wdata  (dmem_wdata),
        .o_dmem_byte_en(dmem_byte_en)
    );

endmodule
