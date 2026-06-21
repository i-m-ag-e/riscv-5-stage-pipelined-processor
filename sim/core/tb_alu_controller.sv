`timescale 1ns / 1ps

import alu_definitions::*;
import pipeline_reg_types::*;
import riscv_opcodes::*;
import instruction_type::*;
import forward_type::*;

module tb_alu_controller();

    alu_op_t i_alu_op;
    logic [2:0] i_funct3;
    logic [6:0] i_funct7;
    alu_control_t o_alu_control;

    alu_controller uut (
        .i_alu_op(i_alu_op),
        .i_funct3(i_funct3),
        .i_funct7(i_funct7),
        .o_alu_control(o_alu_control)
    );

    int errors = 0;

    task check(input alu_op_t op, input logic [2:0] f3, input logic [6:0] f7, input alu_control_t exp);
        i_alu_op = op;
        i_funct3 = f3;
        i_funct7 = f7;
        #1;
        if (o_alu_control !== exp) begin
            $display("ERROR: op=%0d funct3=%b funct7=%b expected=%0d got=%0d", op, f3, f7, exp, o_alu_control);
            errors++;
        end
    endtask

    initial begin
        $dumpfile("sim/tb_alu_controller.vcd");
        $dumpvars(0, tb_alu_controller);
        
        // J/L Types (Load/Store/Jal/etc)
        check(ALUOpJLType, 3'b000, 7'b0000000, ALUConAdd);
        
        // B Types (Branch)
        check(ALUOpBType,  3'b000, 7'b0000000, ALUConSubtract);
        
        // R Types
        check(ALUOpRType,  3'b000, 7'b0000000, ALUConAdd);
        check(ALUOpRType,  3'b000, 7'b0100000, ALUConSubtract);
        check(ALUOpRType,  3'b111, 7'b0000000, ALUConAnd);
        check(ALUOpRType,  3'b110, 7'b0000000, ALUConOr);
        check(ALUOpRType,  3'b100, 7'b0000000, ALUConXor);
        check(ALUOpRType,  3'b001, 7'b0000000, ALUConSll);
        check(ALUOpRType,  3'b101, 7'b0000000, ALUConSrl);
        check(ALUOpRType,  3'b101, 7'b0100000, ALUConSra);
        check(ALUOpRType,  3'b010, 7'b0000000, ALUConSlt);
        check(ALUOpRType,  3'b011, 7'b0000000, ALUConSltu);

        // I Types
        check(ALUOpIType,  3'b000, 7'b0000000, ALUConAdd);
        check(ALUOpIType,  3'b000, 7'b0100000, ALUConAdd); // addi ignores funct7[5]
        check(ALUOpIType,  3'b111, 7'b0000000, ALUConAnd);
        check(ALUOpIType,  3'b110, 7'b0000000, ALUConOr);
        check(ALUOpIType,  3'b100, 7'b0000000, ALUConXor);
        check(ALUOpIType,  3'b001, 7'b0000000, ALUConSll);
        check(ALUOpIType,  3'b101, 7'b0000000, ALUConSrl);
        check(ALUOpIType,  3'b101, 7'b0100000, ALUConSra);
        check(ALUOpIType,  3'b010, 7'b0000000, ALUConSlt);
        check(ALUOpIType,  3'b011, 7'b0000000, ALUConSltu);

        if (errors == 0) $display("tb_alu_controller: PASS");
        else $display("tb_alu_controller: FAIL with %0d errors", errors);
        
        $finish;
    end

endmodule
