`timescale 1ns / 1ps

module tb_branch_adder ();

    logic [31:0] i_base;
    logic [31:0] i_imm;
    logic [31:0] o_target_addr;

    branch_adder uut (
        .i_base(i_base),
        .i_imm(i_imm),
        .o_target_addr(o_target_addr)
    );

    int errors = 0;

    task check(input logic [31:0] base, input logic [31:0] imm, input logic [31:0] exp);
        i_base = base;
        i_imm  = imm;
        #1;
        if (o_target_addr !== exp) begin
            $display("ERROR: base=%0d imm=%0d exp=%0d got=%0d", base, imm, exp, o_target_addr);
            errors++;
        end
    endtask

    initial begin
        $dumpfile("sim/tb_branch_adder.vcd");
        $dumpvars(0, tb_branch_adder);

        check(100, 20, 120);
        check(200, -50, 150);
        check(32'hFFFF_FFFF, 2, 1);
        check(0, 0, 0);

        if (errors == 0) $display("tb_branch_adder: PASS");
        else $display("tb_branch_adder: FAIL with %0d errors", errors);

        $finish;
    end

endmodule
