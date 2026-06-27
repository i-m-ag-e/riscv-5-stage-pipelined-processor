module wishbone_ibus (
    input logic clk,
    input logic rst_n,

    input  logic [31:0] i_core_addr,
    output logic [31:0] o_core_inst,
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

    assign o_wb_we    = 1'b0;
    assign o_wb_dat_w = 32'b0;
    assign o_wb_sel   = 4'b1111;
    assign o_wb_adr   = i_core_addr[31:2];

    // Latch the instruction so it doesn't disappear if waiting on D-Bus
    logic [31:0] inst_q;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) inst_q <= 32'h00000013;  // NOP
        else if (i_wb_ack) inst_q <= i_wb_dat_r;
    end
    assign o_core_inst = (i_wb_ack) ? i_wb_dat_r : inst_q;

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

        case (state)
            IDLE: begin
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
                o_core_stall = 1'b0;  // We are ready, just waiting for D-Bus
                if (i_pipeline_advance) next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end
endmodule
