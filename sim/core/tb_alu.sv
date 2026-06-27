`timescale 1ns / 1ps

import alu_definitions::*;

module tb_alu ();

    alu_control_t i_alu_control;
    logic [31:0] i_operand_a;
    logic [31:0] i_operand_b;
    logic [31:0] o_result;

    alu uut (
        .i_alu_control(i_alu_control),
        .i_operand_a(i_operand_a),
        .i_operand_b(i_operand_b),
        .o_result(o_result)
    );

    int errors = 0;

    task check(input alu_control_t op, input logic [31:0] a, input logic [31:0] b,
               input logic [31:0] exp);
        i_alu_control = op;
        i_operand_a   = a;
        i_operand_b   = b;
        #1;
        if (o_result !== exp) begin
            $display("ERROR: op=%0d a=%0d b=%0d expected=%0d got=%0d", op, a, b, exp, o_result);
            errors++;
        end
    endtask

    initial begin
        $dumpfile("sim/tb_alu.vcd");
        $dumpvars(0, tb_alu);

        check(ALUConAdd, 10, 20, 30);
        check(ALUConSubtract, 20, 10, 10);
        check(ALUConAnd, 32'h00FF_00FF, 32'h0F0F_0F0F, 32'h000F_000F);
        check(ALUConOr, 32'h00FF_00FF, 32'h0F0F_0F0F, 32'h0FFF_0FFF);
        check(ALUConXor, 32'h00FF_00FF, 32'h0F0F_0F0F, 32'h0FF0_0FF0);
        check(ALUConSll, 32'h0000_0001, 4, 32'h0000_0010);
        check(ALUConSrl, 32'h0000_0010, 4, 32'h0000_0001);
        check(ALUConSra, 32'hF000_0000, 4, 32'hFF00_0000);
        check(ALUConSlt, -10, 20, 1);
        check(ALUConSlt, 20, -10, 0);
        check(ALUConSltu, -10, 20, 0);
        check(ALUConSltu, 20, -10, 1);

        if (errors == 0) $display("tb_alu: PASS");
        else $display("tb_alu: FAIL with %0d errors", errors);

        $finish;
    end

endmodule
