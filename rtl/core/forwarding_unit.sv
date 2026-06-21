import forward_type::*;

module forwarding_unit (
    input logic [4:0] i_rs1,
    input logic [4:0] i_rs2,

    input logic i_mem_reg_write,
    input logic [4:0] i_mem_rd,

    input logic i_wb_reg_write,
    input logic [4:0] i_wb_rd,

    output forward_t o_forward_a,
    output forward_t o_forward_b
);

    always_comb begin
        o_forward_a = FwdNormal;
        o_forward_b = FwdNormal;

        if (i_mem_reg_write && i_rs1 != 5'b0 && i_rs1 == i_mem_rd) begin
            o_forward_a = FwdMem;
        end
        else if (i_wb_reg_write && i_rs1 != 5'b0 && i_rs1 == i_wb_rd) begin
            o_forward_a = FwdWB;
        end

        if (i_mem_reg_write && i_rs2 != 5'b0 && i_rs2 == i_mem_rd) begin
            o_forward_b = FwdMem;
        end
        else if (i_wb_reg_write && i_rs2 != 5'b0 && i_rs2 == i_wb_rd) begin
            o_forward_b = FwdWB;
        end
    end

endmodule
