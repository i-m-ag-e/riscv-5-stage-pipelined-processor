module top_wb (
    input logic clk,
    input logic rst_n,

    output logic [ 3:0] o_ibus_sel,
    output logic        o_ibus_cyc,
    output logic        o_ibus_stb,
    output logic        o_ibus_we,
    input  logic        i_ibus_ack,
    input  logic        i_ibus_err,
    output logic [29:0] o_ibus_adr,
    output logic [31:0] o_ibus_dat_w,
    input  logic [31:0] i_ibus_dat_r,

    // Data Memory Bus (D-Bus) - Wishbone Master
    input  logic [31:0] i_dbus_dat_r,
    output logic [ 3:0] o_dbus_sel,
    output logic        o_dbus_cyc,
    output logic        o_dbus_stb,
    output logic        o_dbus_we,
    input  logic        i_dbus_ack,
    input  logic        i_dbus_err,
    output logic [29:0] o_dbus_adr,
    output logic [31:0] o_dbus_dat_w
);

    logic [31:0] imem_addr;
    logic [31:0] imem_instr;

    /* verilator lint_off UNOPTFLAT */
    logic ibus_stall;
    /* lint_on */

    logic [31:0] dmem_addr;
    logic dmem_read;
    logic dmem_write;
    logic [31:0] dmem_rdata;
    logic [31:0] dmem_wdata;
    logic [3:0] dmem_byte_en;
    logic dbus_stall;

    logic pipeline_advance;
    assign pipeline_advance = ~(ibus_stall | dbus_stall);

    datapath_wb datapath (
        .clk           (clk),
        .rst_n         (rst_n),
        .i_stall       (ibus_stall | dbus_stall),
        .i_imem_instr  (imem_instr),
        .i_dmem_rdata  (dmem_rdata),
        .o_imem_addr   (imem_addr),
        .o_dmem_addr   (dmem_addr),
        .o_dmem_read   (dmem_read),
        .o_dmem_write  (dmem_write),
        .o_dmem_wdata  (dmem_wdata),
        .o_dmem_byte_en(dmem_byte_en)
    );

    wishbone_ibus wishbone_ibus (
        .clk               (clk),
        .rst_n             (rst_n),
        .i_pipeline_advance(pipeline_advance),  // NEW PORT
        .i_core_addr       (imem_addr),
        .o_core_inst       (imem_instr),
        .o_core_stall      (ibus_stall),
        .o_wb_adr          (o_ibus_adr),
        .o_wb_dat_w        (o_ibus_dat_w),
        .i_wb_dat_r        (i_ibus_dat_r),
        .o_wb_sel          (o_ibus_sel),
        .o_wb_cyc          (o_ibus_cyc),
        .o_wb_stb          (o_ibus_stb),
        .o_wb_we           (o_ibus_we),
        .i_wb_ack          (i_ibus_ack),
        .i_wb_err          (i_ibus_err)
    );

    wishbone_dbus wishbone_dbus (
        .clk               (clk),
        .rst_n             (rst_n),
        .i_pipeline_advance(pipeline_advance),  // NEW PORT
        .i_core_addr       (dmem_addr),
        .i_core_wdata      (dmem_wdata),
        .o_core_rdata      (dmem_rdata),
        .i_core_byte_en    (dmem_byte_en),
        .i_core_read       (dmem_read),
        .i_core_write      (dmem_write),
        .o_core_stall      (dbus_stall),
        .o_wb_adr          (o_dbus_adr),
        .o_wb_dat_w        (o_dbus_dat_w),
        .i_wb_dat_r        (i_dbus_dat_r),
        .o_wb_sel          (o_dbus_sel),
        .o_wb_cyc          (o_dbus_cyc),
        .o_wb_stb          (o_dbus_stb),
        .o_wb_we           (o_dbus_we),
        .i_wb_ack          (i_dbus_ack),
        .i_wb_err          (i_dbus_err)
    );

endmodule
