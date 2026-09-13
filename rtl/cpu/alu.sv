module alu (
  input logic [31:0] operand_a, operand_b,
  input rv32_pkg::alu_op_t alu_operation,
  output logic [31:0] alu_result
);
  import rv32_pkg::*;
  always_comb begin
    alu_result = 32'b0;
    case (alu_operation)
      ALU_ADD: alu_result = operand_a + operand_b;
      ALU_SUB: alu_result = operand_a - operand_b;
      ALU_AND: alu_result = operand_a & operand_b;
      ALU_OR: alu_result = operand_a | operand_b;
      ALU_XOR: alu_result = operand_a ^ operand_b;
      ALU_SLT: alu_result = {31'b0, $signed(operand_a) < $signed(operand_b)};
      ALU_SLTU: alu_result = {31'b0, operand_a < operand_b};
      ALU_SLL: alu_result = operand_a << operand_b[4:0];
      ALU_SRL: alu_result = operand_a >> operand_b[4:0];
      ALU_SRA: alu_result = $signed(operand_a) >>> operand_b[4:0];
      default: alu_result = 32'b0;
    endcase
  end
endmodule
