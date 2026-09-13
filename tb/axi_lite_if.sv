interface axi_lite_if(input logic clk, reset_n);
  logic [31:0] awaddr, wdata, araddr, rdata;
  logic [2:0] awprot, arprot;
  logic [3:0] wstrb;
  logic [1:0] bresp,rresp;
  logic awvalid,awready,wvalid,wready,bvalid,bready,arvalid,arready,rvalid,rready;
  modport MASTER(input clk,reset_n,awready,wready,bresp,bvalid,arready,rdata,rresp,rvalid,
    output awaddr,awprot,awvalid,wdata,wstrb,wvalid,bready,araddr,arprot,arvalid,rready);
  modport SLAVE(input clk,reset_n,awaddr,awprot,awvalid,wdata,wstrb,wvalid,bready,araddr,arprot,arvalid,rready,
    output awready,wready,bresp,bvalid,arready,rdata,rresp,rvalid);
  modport MONITOR(input clk,reset_n,awaddr,awprot,awvalid,awready,wdata,wstrb,wvalid,wready,
    bresp,bvalid,bready,araddr,arprot,arvalid,arready,rdata,rresp,rvalid,rready);
endinterface
