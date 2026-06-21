import alu_definitions::*;

module alu (
    input alu_control_t i_alu_control,
    input logic [31:0] i_operand_a,
    input logic [31:0] i_operand_b,
    output logic [31:0] o_result
);

    logic result;
    always_comb begin
        result = 1'b0;

        case (i_alu_control)
            ALUConAdd: o_result = i_operand_a + i_operand_b;
            ALUConSubtract: o_result = i_operand_a - i_operand_b;
            ALUConAnd: o_result = i_operand_a & i_operand_b;
            ALUConOr: o_result = i_operand_a | i_operand_b;
            ALUConSll: o_result = i_operand_a << i_operand_b[4:0];
            ALUConSlt: begin
                result = (i_operand_a[31] != i_operand_b[31]) ?
                    i_operand_a[31] : (i_operand_a < i_operand_b);
                o_result = {31'b0, result};
            end
            ALUConSltu: o_result = {31'd0, i_operand_a < i_operand_b};
            ALUConSrl: o_result = i_operand_a >> i_operand_b[4:0];
            ALUConSra: o_result = $unsigned($signed(i_operand_a) >>> $signed(i_operand_b[4:0]));
            ALUConXor: o_result = i_operand_a ^ i_operand_b;
            default: o_result = 'bx;
        endcase
    end

endmodule
