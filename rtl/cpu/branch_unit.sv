module branch_unit (
  input logic [31:0] rs1_data, rs2_data,
  input logic [2:0] funct3,
  output logic branch_taken
);
  always_comb begin
    branch_taken=0;
    case(funct3)
      0: branch_taken=rs1_data==rs2_data;
      1: branch_taken=rs1_data!=rs2_data;
      4: branch_taken=$signed(rs1_data)<$signed(rs2_data);
      5: branch_taken=$signed(rs1_data)>=$signed(rs2_data);
      6: branch_taken=rs1_data<rs2_data;
      7: branch_taken=rs1_data>=rs2_data;
      default: branch_taken=0;
    endcase
  end
endmodule
