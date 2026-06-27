import forward_type::*;

module forwarding_unit (
    input logic [4:0] i_rs1,
    input logic [4:0] i_rs2,

    input logic [31:0] i_rs1_data,
    input logic [31:0] i_rs2_data,

    input logic i_mem_reg_write,
    input logic [4:0] i_mem_rd,
    input logic [31:0] i_mem_alu_result,

    input logic i_wb_reg_write,
    input logic [4:0] i_wb_rd,
    input logic [31:0] i_wb_data,

    output logic [31:0] o_forwarded_a,
    output logic [31:0] o_forwarded_b
);

    forward_t forward_a, forward_b;

    always_comb begin
        forward_a = FwdNormal;
        forward_b = FwdNormal;

        if (i_mem_reg_write && i_rs1 != 5'b0 && i_rs1 == i_mem_rd) begin
            forward_a = FwdMem;
        end
        else if (i_wb_reg_write && i_rs1 != 5'b0 && i_rs1 == i_wb_rd) begin
            forward_a = FwdWB;
        end

        if (i_mem_reg_write && i_rs2 != 5'b0 && i_rs2 == i_mem_rd) begin
            forward_b = FwdMem;
        end
        else if (i_wb_reg_write && i_rs2 != 5'b0 && i_rs2 == i_wb_rd) begin
            forward_b = FwdWB;
        end
    end

    always_comb begin
        o_forwarded_a = i_rs1_data;
        o_forwarded_b = i_rs2_data;

        unique case (forward_a)
            FwdNormal: o_forwarded_a = i_rs1_data;
            FwdMem: o_forwarded_a = i_mem_alu_result;
            FwdWB: o_forwarded_a = i_wb_data;
        endcase

        unique case (forward_b)
            FwdNormal: o_forwarded_b = i_rs2_data;
            FwdMem: o_forwarded_b = i_mem_alu_result;
            FwdWB: o_forwarded_b = i_wb_data;
        endcase
    end


endmodule
