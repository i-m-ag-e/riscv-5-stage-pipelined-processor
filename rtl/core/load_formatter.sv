module load_formatter (
    input logic [31:0] i_read_data,
    input logic [ 2:0] i_funct3,
    input logic [ 1:0] i_addr_offset,

    output logic [31:0] o_result
);

    always_comb begin
        logic [ 7:0] read_byte;
        logic [15:0] read_hw;

        case (i_addr_offset)
            2'b00:   read_byte = i_read_data[7:0];
            2'b01:   read_byte = i_read_data[15:8];
            2'b10:   read_byte = i_read_data[23:16];
            2'b11:   read_byte = i_read_data[31:24];
            default: read_byte = 8'b0;  // shows warning otherwise
        endcase

        read_hw = (i_addr_offset[1]) ? i_read_data[31:16] : i_read_data[15:0];

        case (i_funct3)
            3'b000:  o_result = {{24{read_byte[7]}}, read_byte};
            3'b001:  o_result = {{16{read_hw[15]}}, read_hw};
            3'b010:  o_result = i_read_data;
            3'b100:  o_result = {24'b0, read_byte};
            3'b101:  o_result = {16'b0, read_hw};
            default: o_result = i_read_data;
        endcase
    end

endmodule
