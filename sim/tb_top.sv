`timescale 1ns / 1ps

module tb_top();

    // Clock and reset
    logic clk;
    logic rst_n;

    // Instantiate the top level module
    top uut (
        .clk(clk),
        .rst_n(rst_n)
    );

    // Clock generation (100 MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Simulation sequence
    initial begin
        // Setup waveform dumping
        $dumpfile("sim/tb_top.vcd");
        $dumpvars(0, tb_top);

        // Apply reset
        rst_n = 0;
        #20;
        
        // Release reset
        rst_n = 1;

        // Run simulation for a sufficient amount of time
        // Modify this value based on how long your program runs
        #10000;
        
        $display("Simulation complete.");
        $finish;
    end

endmodule
