import alu_definitions::*;

module alu_controller (
    input alu_op_t i_alu_op,
    input logic [2:0] i_funct3,
    input logic [6:0] i_funct7,
    output alu_control_t o_alu_control
);

    always_comb begin

        case (i_alu_op)
            ALUOpJLType: o_alu_control = ALUConAdd;
            ALUOpBType: o_alu_control = ALUConSubtract;
            ALUOpRType, ALUOpIType:
            unique case (i_funct3)
                3'b111: o_alu_control = ALUConAnd;
                3'b110: o_alu_control = ALUConOr;
                3'b001: o_alu_control = ALUConSll;
                3'b010: o_alu_control = ALUConSlt;
                3'b011: o_alu_control = ALUConSltu;
                3'b101: o_alu_control = i_funct7[5] ? ALUConSra : ALUConSrl;
                3'b100: o_alu_control = ALUConXor;
                3'b000: begin
                    if (i_alu_op == ALUOpIType) o_alu_control = ALUConAdd;
                    else o_alu_control = i_funct7[5] ? ALUConSubtract : ALUConAdd;
                end
            endcase
            default: o_alu_control = ALUConAdd;
        endcase

    end

endmodule
