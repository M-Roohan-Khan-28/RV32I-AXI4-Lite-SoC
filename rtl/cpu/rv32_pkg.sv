package rv32_pkg;
  typedef enum logic [3:0] {ALU_ADD, ALU_SUB, ALU_AND, ALU_OR, ALU_XOR,
    ALU_SLT, ALU_SLTU, ALU_SLL, ALU_SRL, ALU_SRA} alu_op_t;
  typedef enum logic [2:0] {IMM_I, IMM_S, IMM_B, IMM_U, IMM_J} imm_t;
  typedef enum logic [1:0] {WB_ALU, WB_MEM, WB_PC4, WB_IMM} wb_t;
endpackage
