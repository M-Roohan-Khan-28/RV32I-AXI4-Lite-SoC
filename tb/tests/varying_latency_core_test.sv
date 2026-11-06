`timescale 1ns/1ps
module varying_latency_core_test;
  import cpu_tb_pkg::*;
  parameter int SEED=1;
  bit clk=0,reset_n=0;
  always #5 clk=~clk;
  logic [31:0] pc,ins,addr,wd,load,wb,sw,sr;
  logic ff,valid,wr,ready,done,error,fault,retire,we,en,swe;
  logic [3:0] strb,ss;
  logic [4:0] rd;
  logic [9:0] sa;
  bit waiting=0;
  logic [31:0] held_pc,held_addr,held_data;
  int waits=0,aw_wait=0,ar_wait=0;
  int aw_min=100000,aw_max=0,ar_min=100000,ar_max=0;
  cpu_reference model;
  axi_lite_if m(clk,reset_n),s(clk,reset_n);
  instruction_memory #(.INIT_FILE("programs/isa.hex")) im(pc,ins,ff);
  riscv_core core(clk,reset_n,ins,ff,pc,valid,wr,addr,wd,strb,done,error,load,fault,retire,we,rd,wb);
  axi_lite_master master(clk,reset_n,valid,wr,addr,wd,strb,ready,done,error,load,m);
  axi_varying_delay #(.SEED(SEED),.MAX_DELAY(11)) delays(m,s);
  axi_lite_slave slave(s,en,swe,sa,sw,ss,sr);
  sram ram(clk,reset_n,en,swe,sa,sw,ss,sr);
  axi_protocol_checker cm(m),cs(s);
  initial begin model=new;repeat(4) @(negedge clk);reset_n=1;end
  always @(posedge clk) if(reset_n) begin
    assert(!fault) else $fatal(1,"varying-latency core fault pc=%h",pc);
    if(waiting) assert(pc===held_pc && addr===held_addr && wd===held_data)
      else $fatal(1,"CPU request changed while waiting seed=%0d",SEED);
    waiting=valid && !done;held_pc=pc;held_addr=addr;held_data=wd;
    if(waiting) begin
      waits++;
      assert(!we && !retire) else $fatal(1,"premature varying-latency retirement");
    end
    if(m.awvalid&&!m.awready) aw_wait++;
    if(m.awvalid&&m.awready) begin
      if(aw_wait<aw_min) aw_min=aw_wait;
      if(aw_wait>aw_max) aw_max=aw_wait;
      aw_wait=0;
    end
    if(m.arvalid&&!m.arready) ar_wait++;
    if(m.arvalid&&m.arready) begin
      if(ar_wait<ar_min) ar_min=ar_wait;
      if(ar_wait>ar_max) ar_max=ar_wait;
      ar_wait=0;
    end
    if(retire) begin
      model.step(pc,ins,we,rd,wb);
      @(negedge clk);
      for(int k=0;k<32;k++)
        assert(core.rf.regs[k]===model.regs[k]) else $fatal(1,"retired x%0d seed=%0d",k,SEED);
      if(ins==32'h0000006f) begin
        for(int k=0;k<1024;k++) if(model.initialized[k])
          assert(ram.mem[k]===model.memory[k]) else $fatal(1,"varying SRAM word %0d",k);
        assert(cm.writes==4 && cm.reads==5 && waits>50)
          else $fatal(1,"varying transaction counts seed=%0d",SEED);
        assert(aw_max>aw_min && ar_max>ar_min)
          else $fatal(1,"memory latency did not vary seed=%0d AW=%0d..%0d AR=%0d..%0d",
                      SEED,aw_min,aw_max,ar_min,ar_max);
        $display("PASS varying latency seed=%0d retired=%0d waits=%0d AW=%0d..%0d AR=%0d..%0d",
                 SEED,model.retired,waits,aw_min,aw_max,ar_min,ar_max);
        $finish;
      end
    end
  end
  initial begin #150000;$fatal(1,"varying-latency timeout seed=%0d",SEED);end
endmodule
