`timescale 1ns / 1ps

module tb_alu_controller;

    // --- Signal Declarations ---
    // Inputs prefixed with i_
    logic [1:0] i_alu_op;
    logic [2:0] i_funct3;
    logic [6:0] i_funct7;

    // Outputs prefixed with o_
    logic [3:0] o_alu_control;

    // --- Device Under Test (DUT) Instantiation ---
    // Assuming the module is named alu_controller
    alu_controller dut (
        .i_alu_op(i_alu_op),
        .i_funct3(i_funct3),
        .i_funct7(i_funct7),
        .o_alu_control(o_alu_control)
    );

    // --- Helper Task for Output Verification ---
    task automatic check_expected_output;
        input [3:0] expected_control;
        input string instruction_name;
        begin
            #10;  // Wait 10ns for combinational logic to settle

            if (o_alu_control !== expected_control) begin
                $display({"[FAIL] %s | Expected: %4b | Got: %4b | i_alu_op: %2b, i_funct3: %3b, ",
                          "i_funct7: %7b"}, instruction_name, expected_control, o_alu_control,
                             i_alu_op, i_funct3, i_funct7);
            end else begin
                $display("[PASS] %s | ALU Control: %4b", instruction_name, o_alu_control);
            end
        end
    endtask

    // --- Test Stimulus ---
    initial begin
        $display("=========================================================");
        $display(" RISC-V ALU Control Unit Testbench (Patterson & Hennessy)");
        $display("=========================================================");

        // 1. Load / Store Instructions (lw / sw)
        // ALUOp = 00. funct3 and funct7 are "Don't Care" (X).
        // Expected ALU Control = 0010 (Add)
        i_alu_op = 2'b00;
        i_funct3 = 3'bxxx;
        i_funct7 = 7'bxxxxxxx;
        check_expected_output(4'b0010, "Load/Store (lw/sw) ");

        // 2. Branch Instruction (beq)
        // ALUOp = 01. funct3 and funct7 are "Don't Care" (X).
        // Expected ALU Control = 0110 (Subtract)
        i_alu_op = 2'b01;
        i_funct3 = 3'bxxx;
        i_funct7 = 7'bxxxxxxx;
        check_expected_output(4'b0110, "Branch (beq)       ");

        // 3. R-Type Instruction: ADD
        // ALUOp = 10, funct3 = 000, funct7 bit 5 = 0
        // Expected ALU Control = 0010 (Add)
        i_alu_op = 2'b10;
        i_funct3 = 3'b000;
        i_funct7 = 7'b0000000;
        check_expected_output(4'b0010, "R-Type (add)       ");

        // 4. R-Type Instruction: SUB
        // ALUOp = 10, funct3 = 000, funct7 bit 5 = 1
        // Expected ALU Control = 0110 (Subtract)
        i_alu_op = 2'b10;
        i_funct3 = 3'b000;
        i_funct7 = 7'b0100000;
        check_expected_output(4'b0110, "R-Type (sub)       ");

        // 5. R-Type Instruction: AND
        // ALUOp = 10, funct3 = 111, funct7 bit 5 = X
        // Expected ALU Control = 0000 (AND)
        i_alu_op = 2'b10;
        i_funct3 = 3'b111;
        i_funct7 = 7'b0000000;
        check_expected_output(4'b0000, "R-Type (and)       ");

        // 6. R-Type Instruction: OR
        // ALUOp = 10, funct3 = 110, funct7 bit 5 = X
        // Expected ALU Control = 0001 (OR)
        i_alu_op = 2'b10;
        i_funct3 = 3'b110;
        i_funct7 = 7'b0000000;
        check_expected_output(4'b0001, "R-Type (or)        ");

        // 7. R-Type Instruction: Set Less Than (SLT)
        // ALUOp = 10, funct3 = 010, funct7 bit 5 = X
        // Expected ALU Control = 0111 (SLT)
        i_alu_op = 2'b10;
        i_funct3 = 3'b010;
        i_funct7 = 7'b0000000;
        check_expected_output(4'b0111, "R-Type (slt)       ");

        // 8. R-Type Instruction: XOR
        // ALUOp = 10, funct3 = 100, funct7 bit 5 = X
        // Expected ALU Control = 1100 (XOR)
        i_alu_op = 2'b10;
        i_funct3 = 3'b100;
        i_funct7 = 7'b0000000;
        check_expected_output(4'b0100, "R-Type (xor)       ");

        // 9. R-Type Instruction: XOR (with funct7 bit 5 = 1, should still be XOR)
        // ALUOp = 10, funct3 = 100, funct7 bit 5 = 1 (doesn't matter for XOR)
        // Expected ALU Control = 1100 (XOR)
        i_alu_op = 2'b10;
        i_funct3 = 3'b100;
        i_funct7 = 7'b0100000;
        check_expected_output(4'b0100, "R-Type (xor alt)   ");

        $display("=========================================================");
        $finish;
    end

endmodule
