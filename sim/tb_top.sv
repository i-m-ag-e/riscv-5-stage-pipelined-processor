`timescale 1ns / 1ps

module tb_top();

    logic clk;
    logic rst_n;

    top uut (
        .clk(clk),
        .rst_n(rst_n)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("sim/tb_top.vcd");
        $dumpvars(0, tb_top);
        rst_n = 0;
        #20;
        rst_n = 1;
        
        // Timeout
        #10000;
        $display("tb_top: TIMEOUT - Test failed to complete.");
        $finish;
    end

    task dump_state();
        integer i;
        $display("=== FINAL STATE ===");
        $display("REG[0] = 0");
        for (i=1; i<32; i++) begin
            // Cast to signed integer for proper negative number printing
            $display("REG[%0d] = %0d", i, $signed(uut.datapath.reg_file.registers[i]));
        end
        for (i=0; i<(1<<16); i++) begin
            if (uut.data_memory.ram[i] !== 32'd0 && uut.data_memory.ram[i] !== 32'bx) begin
                $display("DMEM[%0d] = %0d", i*4, $signed(uut.data_memory.ram[i]));
            end
        end
        $display("===================");
    endtask

    // Self-checking monitor
    always @(posedge clk) begin
        if (rst_n && uut.dmem_write) begin
            if (uut.dmem_addr == 32'h2000) begin
                dump_state();
                if (uut.dmem_wdata == 32'h1) begin
                    $display("tb_top: PASS - Processor reached success state.");
                end else begin
                    $display("tb_top: FAIL - Processor reported failure (code: %0h).", uut.dmem_wdata);
                end
                $finish;
            end
        end
    end

endmodule
