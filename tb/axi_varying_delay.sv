// Deterministic verification-only AXI4-Lite gates. Each accepted transfer
// advances a channel-specific transaction index and changes its next delay.
// Once a gate opens, it remains open through the handshake.
module axi_varying_delay #(
  parameter int SEED=1,
  parameter int MAX_DELAY=11
)(axi_lite_if.SLAVE upstream, axi_lite_if.MASTER downstream);
  int aw_count,w_count,b_count,ar_count,r_count;
  int aw_seen,w_seen,b_seen,ar_seen,r_seen;
  function automatic int target(input int channel,input int seen);
    logic [31:0] value;
    value=32'(SEED) ^ (32'(channel)*32'h9e3779b9) ^
          (32'(seen)*32'h85ebca6b);
    value=value^(value>>16);
    return 1+int'(value % 32'(MAX_DELAY));
  endfunction
  wire aw_open=aw_count>=target(1,aw_seen);
  wire w_open=w_count>=target(2,w_seen);
  wire b_open=b_count>=target(3,b_seen);
  wire ar_open=ar_count>=target(4,ar_seen);
  wire r_open=r_count>=target(5,r_seen);
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
    if(!upstream.reset_n) begin
      aw_count<=0;w_count<=0;b_count<=0;ar_count<=0;r_count<=0;
      aw_seen<=0;w_seen<=0;b_seen<=0;ar_seen<=0;r_seen<=0;
    end else begin
      if(upstream.awvalid && upstream.awready) begin aw_count<=0;aw_seen<=aw_seen+1;end
      else if(upstream.awvalid && !aw_open) aw_count<=aw_count+1;
      if(upstream.wvalid && upstream.wready) begin w_count<=0;w_seen<=w_seen+1;end
      else if(upstream.wvalid && !w_open) w_count<=w_count+1;
      if(downstream.bvalid && downstream.bready) begin b_count<=0;b_seen<=b_seen+1;end
      else if(downstream.bvalid && !b_open) b_count<=b_count+1;
      if(upstream.arvalid && upstream.arready) begin ar_count<=0;ar_seen<=ar_seen+1;end
      else if(upstream.arvalid && !ar_open) ar_count<=ar_count+1;
      if(downstream.rvalid && downstream.rready) begin r_count<=0;r_seen<=r_seen+1;end
      else if(downstream.rvalid && !r_open) r_count<=r_count+1;
    end
  end
endmodule
