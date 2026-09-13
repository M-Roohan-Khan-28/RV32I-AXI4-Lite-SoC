// Verification-only channel gates. Once opened, a gate stays open until handshake.
module axi_delay #(
  parameter int AW_DELAY=0,W_DELAY=0,B_DELAY=0,AR_DELAY=0,R_DELAY=0
)(axi_lite_if.SLAVE upstream, axi_lite_if.MASTER downstream);
  int aw_count,w_count,b_count,ar_count,r_count;
  wire aw_open=aw_count>=AW_DELAY, w_open=w_count>=W_DELAY, b_open=b_count>=B_DELAY;
  wire ar_open=ar_count>=AR_DELAY, r_open=r_count>=R_DELAY;
  assign downstream.awaddr=upstream.awaddr;
  assign downstream.awprot=upstream.awprot;
  assign downstream.awvalid=upstream.awvalid && aw_open;
  assign upstream.awready=downstream.awready && aw_open;
  assign downstream.wdata=upstream.wdata;
  assign downstream.wstrb=upstream.wstrb;
  assign downstream.wvalid=upstream.wvalid && w_open;
  assign upstream.wready=downstream.wready && w_open;
  assign upstream.bresp=downstream.bresp;
  assign upstream.bvalid=downstream.bvalid && b_open;
  assign downstream.bready=upstream.bready && b_open;
  assign downstream.araddr=upstream.araddr;
  assign downstream.arprot=upstream.arprot;
  assign downstream.arvalid=upstream.arvalid && ar_open;
  assign upstream.arready=downstream.arready && ar_open;
  assign upstream.rdata=downstream.rdata;
  assign upstream.rresp=downstream.rresp;
  assign upstream.rvalid=downstream.rvalid && r_open;
  assign downstream.rready=upstream.rready && r_open;
  always @(posedge upstream.clk) begin
    if(!upstream.reset_n) begin aw_count<=0;w_count<=0;b_count<=0;ar_count<=0;r_count<=0; end
    else begin
      if(upstream.awvalid && upstream.awready) aw_count<=0;
      else if(upstream.awvalid && !aw_open) aw_count<=aw_count+1;
      if(upstream.wvalid && upstream.wready) w_count<=0;
      else if(upstream.wvalid && !w_open) w_count<=w_count+1;
      if(downstream.bvalid && downstream.bready) b_count<=0;
      else if(downstream.bvalid && !b_open) b_count<=b_count+1;
      if(upstream.arvalid && upstream.arready) ar_count<=0;
      else if(upstream.arvalid && !ar_open) ar_count<=ar_count+1;
      if(downstream.rvalid && downstream.rready) r_count<=0;
      else if(downstream.rvalid && !r_open) r_count<=r_count+1;
    end
  end
endmodule
