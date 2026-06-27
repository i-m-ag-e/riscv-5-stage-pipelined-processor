`timescale 1ns / 1ps

module tb_branch_comparator ();

    logic [31:0] i_data_A;
    logic [31:0] i_data_B;
    logic i_unsigned_comp;
    logic o_branch_eq;
    logic o_branch_lt;

    branch_comparator uut (
        .i_data_A(i_data_A),
        .i_data_B(i_data_B),
        .i_unsigned_comp(i_unsigned_comp),
        .o_branch_eq(o_branch_eq),
        .o_branch_lt(o_branch_lt)
    );

    int errors = 0;

    task check(input logic [31:0] a, input logic [31:0] b, input logic u, input logic exp_eq,
               input logic exp_lt);
        i_data_A        = a;
        i_data_B        = b;
        i_unsigned_comp = u;
        #1;
        if (o_branch_eq !== exp_eq || o_branch_lt !== exp_lt) begin
            $display("ERROR: a=%0d b=%0d unsigned=%0b exp_eq=%0b got_eq=%0b exp_lt=%0b got_lt=%0b",
                     a, b, u, exp_eq, o_branch_eq, exp_lt, o_branch_lt);
            errors++;
        end
    endtask

    initial begin
        $dumpfile("sim/tb_branch_comparator.vcd");
        $dumpvars(0, tb_branch_comparator);

        // Signed comparisons
        check(10, 20, 0, 0, 1);
        check(20, 10, 0, 0, 0);
        check(10, 10, 0, 1, 0);
        check(-10, 20, 0, 0, 1);
        check(20, -10, 0, 0, 0);
        check(-20, -10, 0, 0, 1);

        // Unsigned comparisons
        check(10, 20, 1, 0, 1);
        check(20, 10, 1, 0, 0);
        check(10, 10, 1, 1, 0);
        check(-10, 20, 1, 0, 0);  // -10 is large positive
        check(20, -10, 1, 0, 1);  // 20 is smaller than large positive

        if (errors == 0) $display("tb_branch_comparator: PASS");
        else $display("tb_branch_comparator: FAIL with %0d errors", errors);

        $finish;
    end

endmodule
