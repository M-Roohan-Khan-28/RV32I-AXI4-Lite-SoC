`timescale 1ns/1ps
module control_test;
  import rv32_pkg::*;
  logic [6:0] opcode,f7;
  logic [2:0] f3;
  alu_op_t op;
  imm_t imm;
  wb_t wb;
  logic ap,ai,rw,mr,mw,br,j,jr,bad,taken,expected;
  logic [31:0] a,b;
  control_unit ctl(opcode,f7,f3,op,imm,wb,ap,ai,rw,mr,mw,br,j,jr,bad);
  branch_unit bu(a,b,f3,taken);
  initial begin
    opcode=7'h33; f7=0; f3=0; a=0; b=0; #1;
    assert(rw && op==ALU_ADD && !bad) else $fatal(1,"ADD decode");
    f7=7'h20; #1; assert(op==ALU_SUB && !bad) else $fatal(1,"SUB decode");
    f7=1; #1; assert(bad && !rw) else $fatal(1,"M must be rejected");
    opcode=7'h13; f3=1; #1; assert(bad) else $fatal(1,"reserved SLLI");
    opcode=7'h03; f3=0; #1; assert(bad && !mr) else $fatal(1,"LB excluded");
    opcode=7'h23; f3=2; #1; assert(mw && !bad && imm==IMM_S) else $fatal(1,"SW decode");
    for(int k=0;k<8;k++) begin
      f3=3'(k);
      for(int n=0;n<3;n++) begin
        a=(n==0 ? 32'hffffffff : n==1 ? 0 : 1); b=(n==0 ? 1 : 0);
        case(k)
          0: expected=a==b; 1: expected=a!=b;
          4: expected=$signed(a)<$signed(b); 5: expected=$signed(a)>=$signed(b);
          6: expected=a<b; 7: expected=a>=b; default: expected=0;
        endcase
        #1; assert(taken===expected) else $fatal(1,"branch f3=%0d",k);
      end
    end
    $display("PASS control legal/illegal decode and signed/unsigned branches"); $finish;
  end
endmodule
