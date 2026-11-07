module axi_protocol_checker #(parameter int MAX_WAIT=256)(axi_lite_if.MONITOR axi);
  bit aw_stall,w_stall,b_stall,ar_stall,r_stall;
  logic [34:0] aw_payload,ar_payload;
  logic [35:0] w_payload;
  logic [33:0] r_payload;
  logic [1:0] b_payload;
  int aw_out,w_out,ar_out,write_age,read_age;
  int writes=0,reads=0;
  always @(posedge axi.clk) begin
    if(!axi.reset_n) begin
      aw_stall=0;w_stall=0;b_stall=0;ar_stall=0;r_stall=0;
      aw_out=0;w_out=0;ar_out=0;write_age=0;read_age=0;
      writes=0;reads=0;
    end else begin
      if(aw_stall) assert(axi.awvalid && {axi.awaddr,axi.awprot}===aw_payload) else $fatal(1,"AW stability");
      if(w_stall) assert(axi.wvalid && {axi.wdata,axi.wstrb}===w_payload) else $fatal(1,"W stability");
      if(b_stall) assert(axi.bvalid && axi.bresp===b_payload) else $fatal(1,"B stability");
      if(ar_stall) assert(axi.arvalid && {axi.araddr,axi.arprot}===ar_payload) else $fatal(1,"AR stability");
      if(r_stall) assert(axi.rvalid && {axi.rdata,axi.rresp}===r_payload) else $fatal(1,"R stability");
      aw_stall=axi.awvalid && !axi.awready; aw_payload={axi.awaddr,axi.awprot};
      w_stall=axi.wvalid && !axi.wready; w_payload={axi.wdata,axi.wstrb};
      b_stall=axi.bvalid && !axi.bready; b_payload=axi.bresp;
      ar_stall=axi.arvalid && !axi.arready; ar_payload={axi.araddr,axi.arprot};
      r_stall=axi.rvalid && !axi.rready; r_payload={axi.rdata,axi.rresp};
      // Eligibility uses state from earlier edges and is independent of READY.
      // Counting this edge's AW/W/AR first would permit same-edge responses.
      if(axi.bvalid) assert(aw_out>0 && w_out>0)
        else $fatal(1,"AXI_CHECKER_B_DEPENDENCY: BVALID before prior AW and W acceptance");
      if(axi.rvalid) assert(ar_out>0)
        else $fatal(1,"AXI_CHECKER_R_DEPENDENCY: RVALID before prior AR acceptance");
      if(axi.awvalid && axi.awready) aw_out++;
      if(axi.wvalid && axi.wready) w_out++;
      if(axi.arvalid && axi.arready) ar_out++;
      if(axi.bvalid && axi.bready) begin
        aw_out--;w_out--;writes++;
      end
      if(axi.rvalid && axi.rready) begin
        ar_out--;reads++;
      end
      write_age=(aw_out>0 && w_out>0) ? write_age+1 : 0;
      read_age=ar_out>0 ? read_age+1 : 0;
      assert(write_age<MAX_WAIT && read_age<MAX_WAIT) else $fatal(1,"bounded AXI completion timeout");
    end
  end
`ifdef FULL_SV
  assert property (@(posedge axi.clk) disable iff(!axi.reset_n)
    axi.awvalid && !axi.awready |=> axi.awvalid && $stable({axi.awaddr,axi.awprot}));
  assert property (@(posedge axi.clk) disable iff(!axi.reset_n)
    axi.wvalid && !axi.wready |=> axi.wvalid && $stable({axi.wdata,axi.wstrb}));
  assert property (@(posedge axi.clk) disable iff(!axi.reset_n)
    axi.arvalid && !axi.arready |=> axi.arvalid && $stable({axi.araddr,axi.arprot}));
  assert property (@(posedge axi.clk) disable iff(!axi.reset_n)
    axi.bvalid && !axi.bready |=> axi.bvalid && $stable(axi.bresp));
  assert property (@(posedge axi.clk) disable iff(!axi.reset_n)
    axi.rvalid && !axi.rready |=> axi.rvalid && $stable({axi.rdata,axi.rresp}));
  // Bounded environment liveness, not an AXI specification latency restriction.
  assert property (@(posedge axi.clk) disable iff(!axi.reset_n)
    (aw_out>0 && w_out>0) |-> ##[0:MAX_WAIT] (axi.bvalid && axi.bready));
  assert property (@(posedge axi.clk) disable iff(!axi.reset_n)
    (axi.arvalid && axi.arready) |-> ##[1:MAX_WAIT] (axi.rvalid && axi.rready));
`endif
endmodule
