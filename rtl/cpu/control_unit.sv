module control_unit (
  input logic [6:0] opcode, funct7,
  input logic [2:0] funct3,
  output rv32_pkg::alu_op_t alu_operation,
  output rv32_pkg::imm_t immediate_type,
  output rv32_pkg::wb_t writeback_source,
  output logic alu_pc, alu_immediate, reg_write, mem_read, mem_write,
  output logic branch, jump, jalr, illegal
);
  import rv32_pkg::*;
  always_comb begin
    alu_operation=ALU_ADD; immediate_type=IMM_I; writeback_source=WB_ALU;
    alu_pc=0; alu_immediate=0; reg_write=0; mem_read=0; mem_write=0;
    branch=0; jump=0; jalr=0; illegal=0;
    case (opcode)
      7'h33,7'h13: begin
        reg_write=1; alu_immediate=(opcode==7'h13);
        case (funct3)
          0: begin
            if (opcode==7'h13 || funct7==0) alu_operation=ALU_ADD;
            else if (funct7==7'h20) alu_operation=ALU_SUB;
            else illegal=1;
          end
          1: begin alu_operation=ALU_SLL; if(funct7!=0) illegal=1; end
          2: alu_operation=ALU_SLT;
          3: alu_operation=ALU_SLTU;
          4: alu_operation=ALU_XOR;
          5: begin
            if(funct7==0) alu_operation=ALU_SRL;
            else if(funct7==7'h20) alu_operation=ALU_SRA;
            else illegal=1;
          end
          6: alu_operation=ALU_OR;
          7: alu_operation=ALU_AND;
        endcase
        if(opcode==7'h33 && funct3!=0 && funct3!=5 && funct7!=0) illegal=1;
      end
      7'h03: begin alu_immediate=1; mem_read=1; reg_write=1; writeback_source=WB_MEM; if(funct3!=2) illegal=1; end
      7'h23: begin alu_immediate=1; mem_write=1; immediate_type=IMM_S; if(funct3!=2) illegal=1; end
      7'h63: begin
        branch=1; immediate_type=IMM_B;
        if(funct3==2 || funct3==3) illegal=1;
      end
      7'h6f: begin jump=1; reg_write=1; immediate_type=IMM_J; writeback_source=WB_PC4; end
      7'h67: begin jump=1; jalr=1; reg_write=1; writeback_source=WB_PC4; if(funct3!=0) illegal=1; end
      7'h37: begin reg_write=1; immediate_type=IMM_U; writeback_source=WB_IMM; end
      7'h17: begin reg_write=1; immediate_type=IMM_U; alu_pc=1; alu_immediate=1; end
      default: illegal=1;
    endcase
    if(illegal) begin reg_write=0; mem_read=0; mem_write=0; branch=0; jump=0; end
  end
endmodule
