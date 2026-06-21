module instruction_memory #(
    parameter int INST_ADDR_WIDTH = 16,
    parameter string INIT_FILE = "firmware.mem"
) (
    input logic clk,

    input  logic [31:0] i_addr,
    output logic [31:0] o_instruction
);

    reg [31:0] mem[(1 << INST_ADDR_WIDTH)];

    wire [INST_ADDR_WIDTH - 1:0] word_addr = i_addr[INST_ADDR_WIDTH+1 : 2];

    initial begin
        $readmemh(INIT_FILE, mem);
    end

    always_ff @(posedge clk) begin
        o_instruction <= mem[word_addr];
    end

endmodule
