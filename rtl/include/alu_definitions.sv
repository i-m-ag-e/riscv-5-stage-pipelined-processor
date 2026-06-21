package alu_definitions;

    typedef enum logic [1:0] {
        ALUOpJLType,
        ALUOpBType,
        ALUOpRType,
        ALUOpIType
    } alu_op_t;

    typedef enum logic [6:0] {
        ALUFunct7Base = 7'b0000000,
        ALUFunct7Alt  = 7'b0100000
    } alu_funct7_t;

    typedef enum logic [2:0] {
        ALUFunct3AddSub = 3'b000,
        ALUFunct3And    = 3'b111,
        ALUFunct3Or     = 3'b110,
        ALUFunct3Sll    = 3'b001,
        ALUFunct3Slt    = 3'b010,
        ALUFunct3Sltu   = 3'b011,
        ALUFunct3Sr     = 3'b101,
        ALUFunct3Xor    = 3'b100
    } alu_funct3_t;

    typedef enum logic [3:0] {
        ALUConAdd,
        ALUConSubtract,
        ALUConAnd,
        ALUConOr,
        ALUConSll,
        ALUConSlt,
        ALUConSltu,
        ALUConSrl,
        ALUConSra,
        ALUConXor
    } alu_control_t;

endpackage
