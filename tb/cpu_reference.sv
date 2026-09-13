// Independent architectural model: does not call RTL ALU/control/immediate helpers.
class cpu_reference;
  logic [31:0] regs[0:31],memory[0:1023];
  bit initialized[0:1023];
  logic [31:0] expected_pc=0;
  bit [30:0] instruction_hits=0;
  bit [11:0] branch_hits=0;
  int retired=0;
`ifdef FULL_SV
  covergroup cpu_cg with function sample(int id,bit taken);
    option.per_instance=1;
    instruction_cp: coverpoint id { bins instructions[]={[0:30]}; }
    branch_cp: coverpoint id iff(id inside {[21:26]}) { bins branches[]={[21:26]}; }
    taken_cp: coverpoint taken iff(id inside {[21:26]});
    branch_outcomes: cross branch_cp,taken_cp;
  endgroup
`endif
  function new();
    foreach(regs[k]) regs[k]=0;
`ifdef FULL_SV
    cpu_cg=new;
`endif
  endfunction
  function void step(input logic [31:0] pc,ins,input bit actual_we,input logic [4:0] actual_rd,input logic [31:0] actual_wdata);
    int opcode,rd,a,b,f3,f7,id,index;
    logic [31:0] x,y,result,next_pc,addr;
    logic signed [31:0] imm;
    bit write_reg,taken;
    assert(pc===expected_pc) else $fatal(1,"CPU reference PC got=%h expected=%h",pc,expected_pc);
    opcode=int'(ins & 127);rd=int'((ins>>7)&31);f3=int'((ins>>12)&7);
    a=int'((ins>>15)&31);b=int'((ins>>20)&31);f7=int'(ins>>25);
    x=regs[a];y=regs[b];result=0;write_reg=1;taken=0;id=-1;next_pc=pc+4;
    imm=$signed(ins)>>>20;
    case(opcode)
      'h33,'h13: begin
        if(opcode=='h13) y=imm;
        case(f3)
          0: if(opcode=='h33 && f7==32) begin result=x-y;id=1;end else begin result=x+y;id=0;end
          7: begin result=x&y;id=2;end
          6: begin result=x|y;id=3;end
          4: begin result=x^y;id=4;end
          2: begin result=32'($signed(x)<$signed(y));id=5;end
          3: begin result=32'(x<y);id=6;end
          1: begin result=x << (y%32);id=7;end
          5: if(f7==32) begin result=$signed(x) >>> (y%32);id=9;end else begin result=x >> (y%32);id=8;end
        endcase
        if(opcode=='h13) begin
          case(id)
            0:id=10;2:id=11;3:id=12;4:id=13;5:id=14;6:id=15;7:id=16;8:id=17;9:id=18;
          endcase
        end
      end
      'h03,'h23: begin
        if(opcode=='h23) imm=$signed({ins[31:25],ins[11:7]});
        addr=x+imm;index=int'((addr-32'h10000000)/4);
        assert(addr>=32'h10000000 && index<1024 && addr%4==0) else $fatal(1,"model memory address");
        if(opcode=='h23) begin memory[index]=y;initialized[index]=1;write_reg=0;id=20;end
        else begin assert(initialized[index]) else $fatal(1,"model uninitialized read");result=memory[index];id=19;end
      end
      'h63: begin
        write_reg=0;imm=$signed({ins[31],ins[7],ins[30:25],ins[11:8],1'b0});
        case(f3)
          0:begin taken=x==y;id=21;end
          1:begin taken=x!=y;id=22;end
          4:begin taken=$signed(x)<$signed(y);id=23;end
          5:begin taken=$signed(x)>=$signed(y);id=24;end
          6:begin taken=x<y;id=25;end
          7:begin taken=x>=y;id=26;end
        endcase
        if(taken) next_pc=pc+imm;
        branch_hits[(id-21)*2+int'(taken)]=1;
      end
      'h6f: begin imm=$signed({ins[31],ins[19:12],ins[20],ins[30:21],1'b0});result=pc+4;next_pc=pc+imm;id=27;end
      'h67: begin result=pc+4;next_pc=(x+imm)&32'hfffffffe;id=28;end
      'h37: begin result=ins&32'hfffff000;id=29;end
      'h17: begin result=pc+(ins&32'hfffff000);id=30;end
      default: $fatal(1,"model unsupported ins=%h",ins);
    endcase
    assert(actual_we==(write_reg && rd!=0)) else $fatal(1,"CPU write-enable pc=%h",pc);
    if(actual_we) begin
      assert(actual_rd==rd && actual_wdata===result) else $fatal(1,"CPU pc=%h ins=%h x%0d got=%h expected=%h",pc,ins,rd,actual_wdata,result);
      regs[rd]=result;
    end
    regs[0]=0;expected_pc=next_pc;retired++;instruction_hits[id]=1;
`ifdef FULL_SV
    cpu_cg.sample(id,taken);
`endif
  endfunction
endclass
