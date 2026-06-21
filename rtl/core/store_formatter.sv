module store_formatter (
    input logic [1:0] i_addr_offset,
    input logic [2:0] i_funct3,
    input logic [31:0] i_mem_wdata,
    input logic i_mem_write,

    output logic [31:0] o_mem_wdata,
    output logic [ 3:0] o_mem_byte_en
);

    always_comb begin
        if (!i_mem_write) begin
            o_mem_wdata   = 32'd0;
            o_mem_byte_en = 4'b0000;
        end
        else begin
            case (i_funct3)
                3'b000: begin
                    o_mem_wdata   = {4{i_mem_wdata[7:0]}};
                    o_mem_byte_en = 4'b0001 << i_addr_offset;
                end
                3'b001: begin
                    o_mem_wdata   = {2{i_mem_wdata[15:0]}};
                    o_mem_byte_en = i_addr_offset[1] ? 4'b1100 : 4'b0011;
                end
                3'b010: begin
                    o_mem_wdata   = i_mem_wdata;
                    o_mem_byte_en = 4'b1111;
                end
                default: begin
                    o_mem_wdata   = 32'd0;
                    o_mem_byte_en = 4'b0000;
                end
            endcase
        end
    end

endmodule
