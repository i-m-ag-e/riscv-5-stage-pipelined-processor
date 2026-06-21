module reg_file (
    input wire clk,
    input logic [4:0] i_read_reg1,
    input logic [4:0] i_read_reg2,
    input logic [4:0] i_write_reg,
    input logic [31:0] i_write_data,
    input logic i_reg_write,

    output logic [31:0] o_read_data1,
    output logic [31:0] o_read_data2
);

    reg [31:0] registers[1:31];

    // assign o_read_data1 = (i_read_reg1 == 5'd0) ? 32'd0 : registers[i_read_reg1];
    // assign o_read_data2 = (i_read_reg2 == 5'd0) ? 32'd0 : registers[i_read_reg2];
    // If we are writing to the register we are currently reading, bypass the array and output the write data directly!
    assign o_read_data1 = (i_reg_write && (i_write_reg == i_read_reg1) && (i_read_reg1 != 5'd0)) ?
        i_write_data : ((i_read_reg1 == 5'd0) ? 32'd0 : registers[i_read_reg1]);

    assign o_read_data2 = (i_reg_write && (i_write_reg == i_read_reg2) && (i_read_reg2 != 5'd0)) ?
        i_write_data : ((i_read_reg2 == 5'd0) ? 32'd0 : registers[i_read_reg2]);

    always_ff @(posedge clk) begin
        if (i_reg_write && i_write_reg != 5'b00000) begin
            registers[i_write_reg] <= i_write_data;
        end
    end

endmodule
