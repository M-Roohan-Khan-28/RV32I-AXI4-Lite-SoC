module axi_lite_slave #(
  parameter logic [31:0] BASE_ADDR=32'h10000000,
  parameter int SRAM_DEPTH=1024,
  parameter int ADDR_BITS=(SRAM_DEPTH>1 ? $clog2(SRAM_DEPTH) : 1)
)(
  axi_lite_if.SLAVE axi,
  output logic sram_en, sram_we,
  output logic [ADDR_BITS-1:0] sram_addr,
  output logic [31:0] sram_wdata,
  output logic [3:0] sram_wstrb,
  input logic [31:0] sram_rdata
);
  logic aw_full,w_full,ar_full,read_wait;
  logic [31:0] aw_saved,w_saved,ar_saved;
  logic [3:0] strb_saved;
  logic write_issue,read_issue,write_legal,read_legal;
  function automatic logic legal(input logic [31:0] address);
    return address[1:0]==0 && address>=BASE_ADDR && (address-BASE_ADDR)/4<SRAM_DEPTH;
  endfunction
  assign axi.awready=axi.reset_n && !aw_full && !axi.bvalid;
  assign axi.wready=axi.reset_n && !w_full && !axi.bvalid;
  assign axi.arready=axi.reset_n && !ar_full && !read_wait && !axi.rvalid;
  assign write_issue=axi.reset_n && aw_full && w_full && !axi.bvalid;
  assign read_issue=axi.reset_n && ar_full && !read_wait && !axi.rvalid && !write_issue;
  assign write_legal=legal(aw_saved);
  assign read_legal=legal(ar_saved);
  assign sram_en=(write_issue && write_legal) || (read_issue && read_legal);
  assign sram_we=write_issue && write_legal;
  assign sram_addr=ADDR_BITS'(((write_issue ? aw_saved : ar_saved)-BASE_ADDR)>>2);
  assign sram_wdata=w_saved;
  assign sram_wstrb=strb_saved;
  always_ff @(posedge axi.clk) begin
    if(!axi.reset_n) begin
      aw_full<=0; w_full<=0; ar_full<=0; read_wait<=0;
      aw_saved<=0; w_saved<=0; ar_saved<=0; strb_saved<=0;
      axi.bvalid<=0; axi.bresp<=0; axi.rvalid<=0; axi.rresp<=0; axi.rdata<=0;
    end else begin
      if(axi.awvalid && axi.awready) begin aw_saved<=axi.awaddr; aw_full<=1; end
      if(axi.wvalid && axi.wready) begin w_saved<=axi.wdata; strb_saved<=axi.wstrb; w_full<=1; end
      if(axi.arvalid && axi.arready) begin ar_saved<=axi.araddr; ar_full<=1; end
      if(axi.bvalid && axi.bready) axi.bvalid<=0;
      if(axi.rvalid && axi.rready) axi.rvalid<=0;
      if(write_issue) begin
        aw_full<=0; w_full<=0; axi.bvalid<=1;
        axi.bresp<=write_legal ? 2'b00 : 2'b10;
      end
      if(read_issue) begin
        ar_full<=0;
        if(read_legal) read_wait<=1;
        else begin axi.rvalid<=1; axi.rresp<=2'b10; axi.rdata<=0; end
      end
      // SRAM updates rdata at the issue edge; capture it on the following edge.
      if(read_wait) begin
        read_wait<=0; axi.rvalid<=1; axi.rresp<=0; axi.rdata<=sram_rdata;
      end
    end
  end
endmodule
