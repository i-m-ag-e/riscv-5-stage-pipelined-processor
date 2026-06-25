module tb_wb;
    logic clk;
    logic rst_n;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("sim/tb_wb.vcd");
        $dumpvars(0, tb_wb);
        rst_n = 0;
        #20 rst_n = 1;

        #10000;
        $display("tb_wb: TIMEOUT - Simulation exceeded maximum time.");
        $finish;
    end

    // Wishbone Instruction Bus (I-Bus)
    logic [3:0] ibus_sel;
    logic ibus_cyc;
    logic ibus_stb;
    logic ibus_we;
    logic ibus_ack;
    logic ibus_err;
    logic [29:0] ibus_adr;
    logic [31:0] ibus_dat_w;
    logic [31:0] ibus_dat_r;

    // Wishbone Data Bus (D-Bus)
    logic [3:0] dbus_sel;
    logic dbus_cyc;
    logic dbus_stb;
    logic dbus_we;
    logic dbus_ack;
    logic dbus_err;
    logic [29:0] dbus_adr;
    logic [31:0] dbus_dat_w;
    logic [31:0] dbus_dat_r;

    top_wb uut (
        .clk(clk),
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

    // Wishbone Memory Slaves
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

    task dump_state();
        integer i;
        $display("=== FINAL STATE ===");
        $display("REG[0] = 0");
        for (i = 1; i < 32; i++) begin
            $display("REG[%0d] = %0d", i, $signed(uut.datapath.reg_file.registers[i]));
        end
        for (i = 0; i < 4096; i++) begin
            if (wb_dmem.ram[i] !== 32'd0 && wb_dmem.ram[i] !== 32'bx) begin
                $display("DMEM[%0d] = %0d", i * 4, $signed(wb_dmem.ram[i]));
            end
        end
        $display("===================");
    endtask

    // Self-checking monitor: watch for D-Bus write to halt address (0x2000 = WB word 0x800)
    always @(posedge clk) begin
        if (rst_n && dbus_ack && dbus_we) begin
            if (dbus_adr == 32'h800) begin
                dump_state();
                if (dbus_dat_w == 32'h1) begin
                    $display("tb_wb: PASS - Processor reached success state.");
                end
                else begin
                    $display("tb_wb: FAIL - Processor reported failure (code: %0h).", dbus_dat_w);
                end
                $finish;
            end
        end
    end
endmodule
