import pipeline_reg_types::*;
import riscv_opcodes::*;
import alu_definitions::*;
import instruction_type::*;
import forward_type::*;

module datapath (
    input logic clk,
    input logic rst_n,

    input logic [31:0] i_imem_instr,
    input logic [31:0] i_dmem_rdata,

    output logic [31:0] o_imem_addr,

    output logic [31:0] o_dmem_addr,
    output logic o_dmem_read,
    output logic o_dmem_write,
    output logic [31:0] o_dmem_wdata,
    output logic [3:0] o_dmem_byte_en
);

    logic [31:0] pc, next_pc;
    logic pc_stall, if_id_stall, if_id_flush, id_ex_flush;

    always_ff @(posedge clk) begin
        if (!rst_n) pc <= 32'd0;
        else if (!pc_stall) begin
            pc <= next_pc;
        end
    end

    if_id_reg_t if_id_in, if_id_out;
    id_ex_reg_t id_ex_in, id_ex_out;
    ex_mem_reg_t ex_mem_in, ex_mem_out;
    mem_wb_reg_t mem_wb_in, mem_wb_out;

    // // -------------- IF STAGE --------------
    // logic [31:0] current_inst;

    // assign if_id_in.pc    = pc;
    // assign if_id_in.valid = 1;

    // assign o_imem_addr    = pc;
    // assign current_inst   = i_imem_instr;

    // // -------------- IF STAGE --------------
    // logic [31:0] current_inst;
    // logic [31:0] hold_inst;
    // logic was_stalled;

    // // Latch the instruction unless we are stalled
    // always_ff @(posedge clk) begin
    //     if (!rst_n) begin
    //         hold_inst   <= 32'd0;
    //         was_stalled <= 1'b0;
    //     end
    //     else begin
    //         was_stalled <= if_id_stall;
    //         if (!if_id_stall) begin
    //             hold_inst <= i_imem_instr;
    //         end
    //     end
    // end

    // // The BRAM is synchronous and cannot be stopped.
    // // If we stalled, the BRAM already output the next instruction. Use the hold register!
    // assign current_inst   = was_stalled ? hold_inst : i_imem_instr;

    // assign if_id_in.pc    = pc;
    // assign if_id_in.valid = 1;

    // assign o_imem_addr    = pc;

    // -------------- IF STAGE --------------
    logic [31:0] current_inst;
    logic [31:0] hold_inst;
    logic was_stalled;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            was_stalled <= 1'b0;
            hold_inst   <= 32'd0;
        end
        else begin
            was_stalled <= if_id_stall;

            // TRIPWIRE: Only capture the BRAM output on the exact edge the stall begins!
            if (if_id_stall && !was_stalled) begin
                hold_inst <= i_imem_instr;
            end
        end
    end

    // If we are currently stalled, OR if we just finished stalling (recovering), use the held instruction.
    // Otherwise, perfectly align with the live synchronous BRAM output.
    assign current_inst   = was_stalled ? hold_inst : i_imem_instr;

    assign if_id_in.pc    = pc;
    assign if_id_in.valid = 1;

    assign o_imem_addr    = pc;

    reg_if_id reg_if_id (
        .clk   (clk),
        .rst_n (rst_n),
        .flush (if_id_flush),
        .stall (if_id_stall),
        .i_data(if_id_in),
        .o_data(if_id_out)
    );

    // ++++++++++++++++++++++++++++++++++++++

    // -------------- ID STAGE --------------
    wire [6:0] opcode;
    wire [4:0] rs1, rs2, rd;
    wire [2:0] funct3;
    wire [6:0] funct7;

    logic
        is_branch,
        is_mem_read,
        is_mem_write,
        is_mem_to_reg,
        is_reg_write,
        is_jump,
        is_jump_reg,
        is_pc_result_to_reg,
        is_rs1_zero;
    alu_op_t alu_op;
    instruction_type_t inst_type;

    logic [31:0] imm, rs1_data, rs2_data;

    decoder decoder (
        .i_instruction(current_inst),
        .o_inst_type  (inst_type),
        .o_opcode     (opcode),
        .o_rs1        (rs1),
        .o_rs2        (rs2),
        .o_rd         (rd),
        .o_funct3     (funct3),
        .o_funct7     (funct7)
    );

    control_unit control_unit (
        .i_opcode          (opcode),
        .o_branch          (is_branch),
        .o_jump            (is_jump),
        .o_jump_reg        (is_jump_reg),
        .o_pc_result_to_reg(is_pc_result_to_reg),
        .o_mem_read        (is_mem_read),
        .o_mem_to_reg      (is_mem_to_reg),
        .o_mem_write       (is_mem_write),
        .o_reg_write       (is_reg_write),
        .o_rs1_zero        (is_rs1_zero),
        .o_alu_op          (alu_op)
    );

    imm_generator imm_generator (
        .i_instruction(current_inst),
        .i_inst_type  (inst_type),
        .o_imm        (imm)
    );

    logic [31:0] formatted_dmem_rdata;
    logic [31:0] wb_data;
    reg_file reg_file (
        .clk         (clk),
        .i_read_reg1 (is_rs1_zero ? 5'b0 : rs1),
        .i_read_reg2 (rs2),
        .i_write_reg (mem_wb_out.rd),
        .i_write_data(wb_data),
        .i_reg_write (mem_wb_out.valid & mem_wb_out.reg_write),
        .o_read_data1(rs1_data),
        .o_read_data2(rs2_data)
    );

    logic [31:0] adder_base, target_addr, final_jump_target;
    assign adder_base = is_jump_reg ? rs1_data : if_id_out.pc;
    branch_adder branch_adder (
        .i_base       (adder_base),
        .i_imm        (imm),
        .o_target_addr(target_addr)
    );

    wire is_unsigned = is_branch && (funct3 == 3'b110 || funct3 == 3'b111);
    logic branch_eq, branch_lt, branch_taken;

    branch_comparator branch_comparator (
        .i_data_A       (rs1_data),
        .i_data_B       (rs2_data),
        .i_unsigned_comp(is_unsigned),
        .o_branch_eq    (branch_eq),
        .o_branch_lt    (branch_lt)
    );

    always_comb begin
        case (funct3)
            3'b000: branch_taken = branch_eq;
            3'b001: branch_taken = ~branch_eq;
            3'b100, 3'b110: branch_taken = branch_lt;
            3'b101, 3'b111: branch_taken = ~branch_lt;
            default: branch_taken = 1'b0;
        endcase
    end

    assign final_jump_target = is_jump_reg ? {target_addr[31:1], 1'b0} : target_addr;
    assign next_pc = (if_id_out.valid && (is_jump || (is_branch && branch_taken))) ?
        final_jump_target : (pc + 4);

    logic [31:0] pc_rel_addr;
    assign pc_rel_addr = (opcode == OPCODE_AUIPC) ? target_addr : (if_id_out.pc + 4);
    always_comb begin
        if (if_id_out.valid) begin
            id_ex_in = '{
                reg_write: is_reg_write,
                mem_read: is_mem_read,
                mem_write: is_mem_write,
                mem_to_reg: is_mem_to_reg,
                pc_result_to_reg: is_pc_result_to_reg,
                alu_src: inst_type != InstRType,
                alu_op: alu_op,
                funct3: funct3,
                funct7: funct7,
                rs1_data: rs1_data,
                rs2_data: rs2_data,
                imm: imm,
                pc_rel_addr: pc_rel_addr,
                rs1: rs1,
                rs2: rs2,
                rd: rd
            };
        end
        else id_ex_in = {$bits(id_ex_reg_t) {1'b0}};
    end

    hazard_unit hazard_unit (
        .i_rs1                 (rs1),
        .i_rs2                 (rs2),
        .i_instr_branch_or_jalr(if_id_out.valid && (is_branch || is_jump_reg)),
        .i_ex_mem_write        (id_ex_out.mem_read),
        .i_ex_reg_write        (id_ex_out.reg_write),
        .i_ex_rd               (id_ex_out.rd),
        .i_mem_reg_write       (ex_mem_out.reg_write),
        .i_mem_rd              (ex_mem_out.rd),
        .i_branch_or_jump      (if_id_out.valid && ((is_branch && branch_taken) || is_jump)),
        .o_stall_pc            (pc_stall),
        .o_stall_if_id         (if_id_stall),
        .o_flush_if_id         (if_id_flush),
        .o_flush_id_ex         (id_ex_flush)
    );

    reg_id_ex reg_id_ex (
        .clk   (clk),
        .rst_n (rst_n),
        .flush (id_ex_flush),
        .i_data(id_ex_in),
        .o_data(id_ex_out)
    );

    // ++++++++++++++++++++++++++++++++++++++

    // -------------- EX STAGE --------------

    alu_control_t alu_ctrl;

    alu_controller alu_controller (
        .i_alu_op     (id_ex_out.alu_op),
        .i_funct3     (id_ex_out.funct3),
        .i_funct7     (id_ex_out.funct7),
        .o_alu_control(alu_ctrl)
    );

    forward_t forward_a, forward_b;
    forwarding_unit forwarding_unit (
        .i_rs1          (id_ex_out.rs1),
        .i_rs2          (id_ex_out.rs2),
        .i_mem_reg_write(ex_mem_out.reg_write),
        .i_mem_rd       (ex_mem_out.rd),
        .i_wb_reg_write (mem_wb_out.reg_write),
        .i_wb_rd        (mem_wb_out.rd),
        .o_forward_a    (forward_a),
        .o_forward_b    (forward_b)
    );

    logic [31:0] ex_rs1_data, ex_rs2_data;
    always_comb begin
        ex_rs1_data = id_ex_out.rs1_data;
        ex_rs2_data = id_ex_out.rs2_data;

        unique case (forward_a)
            FwdNormal: ex_rs1_data = id_ex_out.rs1_data;
            FwdMem: ex_rs1_data = ex_mem_out.alu_result;
            FwdWB: ex_rs1_data = wb_data;
        endcase

        unique case (forward_b)
            FwdNormal: ex_rs2_data = id_ex_out.rs2_data;
            FwdMem: ex_rs2_data = ex_mem_out.alu_result;
            FwdWB: ex_rs2_data = wb_data;
        endcase
    end

    logic [31:0] alu_operand_2, alu_result;

    assign alu_operand_2 = id_ex_out.alu_src ? id_ex_out.imm : ex_rs2_data;

    alu alu (
        .i_alu_control(alu_ctrl),
        .i_operand_a  (ex_rs1_data),
        .i_operand_b  (alu_operand_2),
        .o_result     (alu_result)
    );

    always_comb begin
        ex_mem_in = '{
            alu_result: alu_result,
            reg_write: id_ex_out.reg_write,
            mem_read: id_ex_out.mem_read,
            mem_to_reg: id_ex_out.mem_to_reg,
            pc_result_to_reg: id_ex_out.pc_result_to_reg,
            mem_write: id_ex_out.mem_write,
            funct3: id_ex_out.funct3,
            rd: id_ex_out.rd,
            rs2_data: ex_rs2_data,
            pc_rel_addr: id_ex_out.pc_rel_addr
        };
    end

    reg_ex_mem reg_ex_mem (
        .clk   (clk),
        .rst_n (rst_n),
        .i_data(ex_mem_in),
        .o_data(ex_mem_out)
    );

    // ++++++++++++++++++++++++++++++++++++++

    // -------------- MEM STAGE --------------

    logic [31:0] wdata;
    logic [ 3:0] byte_en;

    store_formatter store_formatter (
        .i_addr_offset(ex_mem_out.alu_result[1:0]),
        .i_funct3     (ex_mem_out.funct3),
        .i_mem_wdata  (ex_mem_out.rs2_data),
        .i_mem_write  (ex_mem_out.mem_write),
        .o_mem_wdata  (wdata),
        .o_mem_byte_en(byte_en)
    );

    assign o_dmem_addr    = ex_mem_out.alu_result;
    assign o_dmem_byte_en = byte_en;
    assign o_dmem_read    = ex_mem_out.mem_read;
    assign o_dmem_write   = ex_mem_out.mem_write;
    assign o_dmem_wdata   = wdata;

    always_comb begin
        mem_wb_in = '{
            alu_result: ex_mem_out.alu_result,
            mem_to_reg: ex_mem_out.mem_to_reg,
            pc_result_to_reg: ex_mem_out.pc_result_to_reg,
            pc_rel_addr: ex_mem_out.pc_rel_addr,
            rd: ex_mem_out.rd,
            reg_write: ex_mem_out.reg_write,
            funct3: ex_mem_out.funct3,
            valid: 1'b1
        };
    end

    reg_mem_wb reg_mem_wb (
        .clk   (clk),
        .rst_n (rst_n),
        .i_data(mem_wb_in),
        .o_data(mem_wb_out)
    );

    // ++++++++++++++++++++++++++++++++++++++

    // -------------- WB STAGE --------------

    load_formatter load_formatter (
        .i_read_data  (i_dmem_rdata),
        .i_funct3     (mem_wb_out.funct3),
        .i_addr_offset(mem_wb_out.alu_result[1:0]),
        .o_result     (formatted_dmem_rdata)
    );

    always_comb begin
        if (mem_wb_out.pc_result_to_reg) wb_data = mem_wb_out.pc_rel_addr;
        else if (mem_wb_out.mem_to_reg) wb_data = formatted_dmem_rdata;
        else wb_data = mem_wb_out.alu_result;
    end

    // Writeback handled above in register file

endmodule
