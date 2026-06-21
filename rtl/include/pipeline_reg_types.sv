package pipeline_reg_types;
    import alu_definitions::alu_op_t;

    typedef struct packed {
        logic [31:0] pc;
        // logic [31:0] instruction;
        logic        valid;
    } if_id_reg_t;

    typedef struct packed {
        logic reg_write;
        logic mem_to_reg;
        logic mem_read;
        logic mem_write;
        logic pc_result_to_reg;

        alu_op_t alu_op;
        logic    alu_src;

        logic [2:0] funct3;
        logic [6:0] funct7;

        logic [31:0] rs1_data;
        logic [31:0] rs2_data;
        logic [31:0] imm;
        logic [31:0] pc_rel_addr;

        logic [4:0] rs1;
        logic [4:0] rs2;
        logic [4:0] rd;
    } id_ex_reg_t;

    typedef struct packed {
        logic       reg_write;
        logic       mem_to_reg;
        logic       mem_read;
        logic       mem_write;
        logic       pc_result_to_reg;
        logic [2:0] funct3;

        logic [31:0] alu_result;
        logic [31:0] rs2_data;
        logic [31:0] pc_rel_addr;

        logic [4:0] rd;
    } ex_mem_reg_t;

    typedef struct packed {
        logic reg_write;
        logic mem_to_reg;
        logic pc_result_to_reg;

        logic [31:0] alu_result;
        logic [2:0]  funct3;
        logic [31:0] pc_rel_addr;
        logic        valid;

        logic [4:0] rd;
    } mem_wb_reg_t;


endpackage
