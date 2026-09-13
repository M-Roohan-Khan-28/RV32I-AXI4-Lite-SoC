module riscv_core #(parameter logic [31:0] RESET_PC=0, parameter bit DEBUG=0)(
  input logic clk, reset_n,
  input logic [31:0] instruction,
  input logic fetch_fault,
  output logic [31:0] instruction_address,
  output logic req_valid, req_write,
  output logic [31:0] req_addr, req_wdata,
  output logic [3:0] req_wstrb,
  input logic response_valid, response_error,
  input logic [31:0] response_data,
  output logic debug_fault, debug_retire, debug_reg_write,
  output logic [4:0] debug_reg_addr,
  output logic [31:0] debug_reg_data
);
  import rv32_pkg::*;
  logic [6:0] opcode,funct7;
  logic [2:0] funct3;
  logic [4:0] rd,rs1,rs2;
  logic [31:0] rs1_data,rs2_data,immediate,alu_result,next_pc,load_data,operand_a,operand_b;
  alu_op_t alu_operation;
  imm_t immediate_type;
  wb_t writeback_source;
  logic alu_pc,alu_immediate,reg_write,mem_read,mem_write,branch,jump,jalr,illegal;
  logic branch_taken,complete,ls_fault,fault_now;
  pc #(.RESET_PC(RESET_PC)) pc_reg(clk,reset_n,debug_retire,next_pc,instruction_address);
  instruction_decoder decoder(instruction,opcode,rd,rs1,rs2,funct3,funct7);
  immediate_generator immgen(instruction,immediate_type,immediate);
  control_unit control(opcode,funct7,funct3,alu_operation,immediate_type,writeback_source,
    alu_pc,alu_immediate,reg_write,mem_read,mem_write,branch,jump,jalr,illegal);
  register_file rf(clk,reset_n,rs1,rs2,rd,debug_reg_data,debug_reg_write,rs1_data,rs2_data);
  assign operand_a=alu_pc ? instruction_address : rs1_data;
  assign operand_b=alu_immediate ? immediate : rs2_data;
  alu execute(operand_a,operand_b,alu_operation,alu_result);
  branch_unit branches(rs1_data,rs2_data,funct3,branch_taken);
  load_store_unit lsu(reset_n && !debug_fault && !illegal && !fetch_fault,
    mem_read,mem_write,alu_result,rs2_data,response_valid,response_error,response_data,
    req_valid,req_write,req_addr,req_wdata,req_wstrb,complete,ls_fault,load_data);
  always_comb begin
    next_pc=instruction_address+4;
    if(branch && branch_taken || jump) next_pc=instruction_address+immediate;
    if(jalr) next_pc=(rs1_data+immediate) & 32'hfffffffe;
    case(writeback_source)
      WB_MEM: debug_reg_data=load_data;
      WB_PC4: debug_reg_data=instruction_address+4;
      WB_IMM: debug_reg_data=immediate;
      default: debug_reg_data=alu_result;
    endcase
  end
  assign fault_now=illegal || fetch_fault || ls_fault || instruction_address[1:0]!=0 || next_pc[1:0]!=0;
  assign debug_retire=reset_n && !debug_fault && !fault_now && (!(mem_read || mem_write) || complete);
  assign debug_reg_write=debug_retire && reg_write && rd!=0;
  assign debug_reg_addr=rd;
  always_ff @(posedge clk) begin
    if(!reset_n) debug_fault<=0;
    else if(fault_now) debug_fault<=1;
  end
`ifndef SYNTHESIS
  int unsigned cycle;
  always @(posedge clk) begin
    if(!reset_n) cycle<=0;
    else begin
      cycle<=cycle+1;
      if(DEBUG) $display("CPU cycle=%0d pc=%h ins=%h rs1=x%0d:%h rs2=x%0d:%h rd=%0d alu=%h we=%b wb=%h mem=%h store=%h wait=%b fault=%b",
        cycle,instruction_address,instruction,rs1,rs1_data,rs2,rs2_data,rd,alu_result,debug_reg_write,debug_reg_data,req_addr,req_wdata,req_valid&&!complete,debug_fault);
      assert(instruction_address[1:0]==0) else $fatal(1,"PC alignment");
      assert(!req_valid || req_addr[1:0]==0) else $fatal(1,"memory alignment");
      assert(rf.regs[0]===0) else $fatal(1,"x0");
    end
  end
`ifdef FULL_SV
  assert property (@(posedge clk) disable iff(!reset_n) req_valid && !response_valid |=> $stable(instruction_address));
  assert property (@(posedge clk) disable iff(!reset_n) instruction_address[1:0]==0);
  assert property (@(posedge clk) disable iff(!reset_n) req_valid |-> req_addr[1:0]==0);
`endif
`endif
endmodule
