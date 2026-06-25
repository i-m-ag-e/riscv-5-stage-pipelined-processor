`timescale 1ns / 1ps

// Runs the same firmware on both TCM and Wishbone SoC architectures simultaneously,
// then compares final register and memory state to verify equivalence.

module tb_mega ();

    logic clk;
    logic rst_n;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("sim/tb_mega.vcd");
        $dumpvars(0, tb_mega);
        rst_n = 0;
        #20 rst_n = 1;

        #50000;
        $display("tb_mega: TIMEOUT - Simulation exceeded maximum time.");
        $finish;
    end

    top_tcm #(
        .RAM_INIT_FILE("firmware.mem")
    ) uut_tcm (
        .clk  (clk),
        .rst_n(rst_n)
    );

    // Wishbone Instruction Bus (I-Bus)
    logic [3:0] ibus_sel;
    logic ibus_cyc;
    logic ibus_stb;
    logic ibus_we;
    logic ibus_ack;
    logic ibus_err = 1'b0;
    logic [29:0] ibus_adr;
    logic [31:0] ibus_dat_w;
    logic [31:0] ibus_dat_r;

    // Wishbone Data Bus (D-Bus)
    logic [3:0] dbus_sel;
    logic dbus_cyc;
    logic dbus_stb;
    logic dbus_we;
    logic dbus_ack;
    logic dbus_err = 1'b0;
    logic [29:0] dbus_adr;
    logic [31:0] dbus_dat_w;
    logic [31:0] dbus_dat_r;

    top_wb uut_wb (
        .clk  (clk),
        .rst_n(rst_n),

        .o_ibus_sel(ibus_sel),
        .o_ibus_cyc(ibus_cyc),
        .o_ibus_stb(ibus_stb),
        .o_ibus_we(ibus_we),
        .i_ibus_ack(ibus_ack),
        .i_ibus_err(ibus_err),
        .o_ibus_adr(ibus_adr),
        .o_ibus_dat_w(ibus_dat_w),
        .i_ibus_dat_r(ibus_dat_r),

        .i_dbus_dat_r(dbus_dat_r),
        .o_dbus_sel(dbus_sel),
        .o_dbus_cyc(dbus_cyc),
        .o_dbus_stb(dbus_stb),
        .o_dbus_we(dbus_we),
        .i_dbus_ack(dbus_ack),
        .i_dbus_err(dbus_err),
        .o_dbus_adr(dbus_adr),
        .o_dbus_dat_w(dbus_dat_w)
    );

    // ==========================================
    // Wishbone Memory Slaves
    // ==========================================
    wishbone_memory #(
        .MEM_ADDR_WIDTH(10),
        .INIT_FILE     ("firmware.mem")
    ) wb_imem (
        .clk(clk),
        .rst_n(rst_n),
        .i_wb_adr(ibus_adr),
        .i_wb_dat_w(ibus_dat_w),
        .i_wb_sel(ibus_sel),
        .i_wb_cyc(ibus_cyc),
        .i_wb_stb(ibus_stb),
        .i_wb_we(ibus_we),
        .o_wb_dat_r(ibus_dat_r),
        .o_wb_ack(ibus_ack)
    );

    wishbone_memory #(
        .MEM_ADDR_WIDTH(12),
        .INIT_FILE     ("firmware.mem")
    ) wb_dmem (
        .clk(clk),
        .rst_n(rst_n),
        .i_wb_adr(dbus_adr),
        .i_wb_dat_w(dbus_dat_w),
        .i_wb_sel(dbus_sel),
        .i_wb_cyc(dbus_cyc),
        .i_wb_stb(dbus_stb),
        .i_wb_we(dbus_we),
        .o_wb_dat_r(dbus_dat_r),
        .o_wb_ack(dbus_ack)
    );

    logic tcm_done = 1'b0;
    logic wb_done = 1'b0;
    logic [31:0] tcm_exit_code;
    logic [31:0] wb_exit_code;

    // TCM monitor: watch for DMEM write to halt address 0x2000
    always @(posedge clk) begin
        if (rst_n && !tcm_done && uut_tcm.dmem_write) begin
            if (uut_tcm.dmem_addr == 32'h2000) begin
                tcm_done      <= 1'b1;
                tcm_exit_code <= uut_tcm.dmem_wdata;
            end
        end
    end

    // WB monitor: watch for D-Bus acked write to halt address (WB word 0x800)
    always @(posedge clk) begin
        if (rst_n && !wb_done && dbus_ack && dbus_we) begin
            if (dbus_adr == 32'h800) begin
                wb_done      <= 1'b1;
                wb_exit_code <= dbus_dat_w;
            end
        end
    end

    always @(posedge clk) begin
        if (tcm_done && wb_done) begin
            integer i;
            integer mismatches;
            mismatches = 0;

            // Dump TCM state (used by run_test.py for register/DMEM checks)
            $display("=== FINAL STATE ===");
            $display("REG[0] = 0");
            for (i = 1; i < 32; i++) begin
                $display("REG[%0d] = %0d", i, $signed(uut_tcm.datapath.reg_file.registers[i]));
            end
            for (i = 0; i < (1 << 12); i++) begin
                if (uut_tcm.data_memory.ram[i] !== 32'd0 &&
                    uut_tcm.data_memory.ram[i] !== 32'bx) begin
                    $display("DMEM[%0d] = %0d", i * 4, $signed(uut_tcm.data_memory.ram[i]));
                end
            end
            $display("===================");

            // Compare register files
            for (i = 1; i < 32; i++) begin
                if (uut_tcm.datapath.reg_file.registers[i] !==
                    uut_wb.datapath.reg_file.registers[i]) begin
                    $display("MISMATCH REG[%0d]: TCM=%0d WB=%0d", i,
                             $signed(uut_tcm.datapath.reg_file.registers[i]),
                             $signed(uut_wb.datapath.reg_file.registers[i]));
                    mismatches++;
                end
            end

            // Compare data memory contents
            for (i = 0; i < 4096; i++) begin
                logic [31:0] tcm_val, soc_val;
                tcm_val = uut_tcm.data_memory.ram[i];
                soc_val = wb_dmem.ram[i];
                // Treat X as 0 for comparison (uninitialized memory)
                if (tcm_val === 32'bx) tcm_val = 32'd0;
                if (soc_val === 32'bx) soc_val = 32'd0;
                if (tcm_val !== soc_val) begin
                    $display("MISMATCH DMEM[%0d]: TCM=%0d WB=%0d", i * 4, $signed(tcm_val),
                             $signed(soc_val));
                    mismatches++;
                end
            end

            // Report
            if (mismatches == 0 && tcm_exit_code == 32'h1 && wb_exit_code == 32'h1) begin
                $display("tb_mega: PASS - Both architectures match and reported success.");
            end
            else begin
                if (tcm_exit_code != 32'h1)
                    $display("tb_mega: FAIL - TCM exit code: %0h", tcm_exit_code);
                if (wb_exit_code != 32'h1)
                    $display("tb_mega: FAIL - WB exit code: %0h", wb_exit_code);
                if (mismatches > 0)
                    $display(
                        "tb_mega: FAIL - %0d state mismatches between TCM and WB.", mismatches
                    );
            end

            $finish;
        end
    end

endmodule
