import instruction_type::*;

module imm_generator (
    input logic [31:0] i_instruction,
    input instruction_type_t i_inst_type,
    output logic [31:0] o_imm
);

    always_comb begin
        case (i_inst_type)
            InstRType: o_imm = 32'd0;

            InstIType: o_imm = {{20{i_instruction[31]}}, i_instruction[31:20]};
            InstSType: o_imm = {{20{i_instruction[31]}}, i_instruction[31:25], i_instruction[11:7]};
            InstBType:
            o_imm = {
                {20{i_instruction[31]}},
                i_instruction[7],
                i_instruction[30:25],
                i_instruction[11:8],
                1'b0
            };
            InstUType: o_imm = {i_instruction[31:12], 12'b0};
            InstJType:
            o_imm = {
                {12{i_instruction[31]}},
                i_instruction[19:12],
                i_instruction[20],
                i_instruction[30:21],
                1'b0
            };

            default: o_imm = 32'd0;
        endcase
    end

endmodule
