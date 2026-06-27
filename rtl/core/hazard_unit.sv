module hazard_unit (
    input logic [4:0] i_rs1,
    input logic [4:0] i_rs2,
    input logic i_instr_branch_or_jalr,

    input logic i_ex_mem_read,
    input logic i_ex_reg_write,
    input logic [4:0] i_ex_rd,

    input logic i_mem_reg_write,
    input logic [4:0] i_mem_rd,

    input logic i_branch_or_jump,

    output logic o_stall_pc,
    output logic o_stall_if_id,
    output logic o_flush_if_id,
    output logic o_flush_id_ex
);
    logic ex_hazard, mem_hazard;

    always_comb begin
        ex_hazard     = 1'b0;
        mem_hazard    = 1'b0;

        o_stall_pc    = 1'b0;
        o_stall_if_id = 1'b0;
        o_flush_if_id = 1'b0;
        o_flush_id_ex = 1'b0;

        if (i_ex_mem_read && i_ex_rd != 5'b0 && (i_ex_rd == i_rs1 || i_ex_rd == i_rs2)) begin
            o_stall_pc    = 1'b1;
            o_stall_if_id = 1'b1;
            o_flush_id_ex = 1'b1;
        end
        else if (i_instr_branch_or_jalr) begin
            ex_hazard = i_ex_reg_write && i_ex_rd != 5'b0 && (i_ex_rd == i_rs1 || i_ex_rd == i_rs2);
            mem_hazard = i_mem_reg_write && i_mem_rd != 5'b0 &&
                (i_mem_rd == i_rs1 || i_mem_rd == i_rs2);

            if (ex_hazard || mem_hazard) begin
                o_stall_pc    = 1'b1;
                o_stall_if_id = 1'b1;
                o_flush_id_ex = 1'b1;
            end
        end


        if (!o_stall_pc && i_branch_or_jump) begin
            o_flush_if_id = 1'b1;
        end
    end

endmodule
