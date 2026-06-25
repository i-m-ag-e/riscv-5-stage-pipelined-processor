module wishbone_dbus (
    input logic clk,
    input logic rst_n,

    input  logic [31:0] i_core_addr,
    input  logic [31:0] i_core_wdata,
    output logic [31:0] o_core_rdata,
    input  logic [ 3:0] i_core_byte_en,
    input  logic        i_core_read,
    input  logic        i_core_write,
    output logic        o_core_stall,

    output logic [29:0] o_wb_adr,
    output logic [31:0] o_wb_dat_w,
    input  logic [31:0] i_wb_dat_r,
    output logic [ 3:0] o_wb_sel,
    output logic        o_wb_cyc,
    output logic        o_wb_stb,
    output logic        o_wb_we,
    input  logic        i_wb_ack,
    input  logic        i_wb_err,

    input logic i_pipeline_advance
);

    assign o_wb_adr = i_core_addr[31:2];
    logic bus_request;
    assign bus_request = i_core_read | i_core_write;

    // Latch read data for stability
    logic [31:0] rdata_q;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) rdata_q <= 32'b0;
        else if (i_wb_ack && i_core_read) rdata_q <= i_wb_dat_r;
    end
    assign o_core_rdata = (i_wb_ack) ? i_wb_dat_r : rdata_q;

    typedef enum logic [1:0] {
        IDLE,
        ACTIVE,
        DONE
    } state_t;
    state_t state, next_state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else state <= next_state;
    end

    always_comb begin
        next_state   = state;
        o_wb_cyc     = 1'b0;
        o_wb_stb     = 1'b0;
        o_core_stall = 1'b0;

        o_wb_dat_w   = i_core_wdata;
        o_wb_sel     = i_core_byte_en;
        o_wb_we      = i_core_write;

        case (state)
            IDLE: begin
                if (bus_request) begin
                    o_wb_cyc     = 1'b1;
                    o_wb_stb     = 1'b1;
                    o_core_stall = 1'b1;
                    if (i_wb_ack) begin
                        o_core_stall = 1'b0;
                        if (i_pipeline_advance) next_state = IDLE;
                        else next_state = DONE;
                    end
                    else begin
                        next_state = ACTIVE;
                    end
                end
            end

            ACTIVE: begin
                o_wb_cyc     = 1'b1;
                o_wb_stb     = 1'b1;
                o_core_stall = 1'b1;
                if (i_wb_ack) begin
                    o_core_stall = 1'b0;
                    if (i_pipeline_advance) next_state = IDLE;
                    else next_state = DONE;
                end
            end

            DONE: begin
                o_core_stall = 1'b0;
                if (i_pipeline_advance) next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end
endmodule
