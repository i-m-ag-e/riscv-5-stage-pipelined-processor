module wishbone_memory #(
    parameter int    MEM_ADDR_WIDTH = 12,  // 16KB default
    parameter string INIT_FILE      = ""   // Optional firmware file
) (
    input logic clk,
    input logic rst_n,

    // Wishbone Slave Interface
    input  logic [29:0] i_wb_adr,
    input  logic [31:0] i_wb_dat_w,
    input  logic [ 3:0] i_wb_sel,
    input  logic        i_wb_cyc,
    input  logic        i_wb_stb,
    input  logic        i_wb_we,
    output logic [31:0] o_wb_dat_r,
    output logic        o_wb_ack
);

    // The actual memory array
    logic [31:0] ram[(1 << MEM_ADDR_WIDTH)];

    // Load firmware if a file is provided
    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, ram);
        end
    end

    wire [MEM_ADDR_WIDTH - 1:0] word_addr = i_wb_adr[MEM_ADDR_WIDTH-1:0];

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            o_wb_ack   <= 1'b0;
            o_wb_dat_r <= 32'd0;
        end
        else begin
            // Default state: drop ACK so we don't hold the bus hostage
            o_wb_ack <= 1'b0;

            // If the CPU is requesting a valid transaction, AND we haven't acked yet
            if (i_wb_cyc && i_wb_stb && !o_wb_ack) begin

                // Handle Writes
                if (i_wb_we) begin
                    if (i_wb_sel[0]) ram[word_addr][7:0] <= i_wb_dat_w[7:0];
                    if (i_wb_sel[1]) ram[word_addr][15:8] <= i_wb_dat_w[15:8];
                    if (i_wb_sel[2]) ram[word_addr][23:16] <= i_wb_dat_w[23:16];
                    if (i_wb_sel[3]) ram[word_addr][31:24] <= i_wb_dat_w[31:24];
                end

                // Handle Reads (We always read the word, even on a write cycle)
                o_wb_dat_r <= ram[word_addr];

                // Assert ACK to tell the CPU the data is ready!
                // Because this is inside an always_ff, it takes 1 clock cycle to happen.
                o_wb_ack   <= 1'b1;
            end
        end
    end

endmodule
