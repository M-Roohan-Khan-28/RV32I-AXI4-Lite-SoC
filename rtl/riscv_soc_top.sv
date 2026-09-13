module riscv_soc_top #(
  parameter int IMEM_DEPTH=1024, SRAM_DEPTH=1024,
  parameter logic [31:0] RESET_PC=0, SRAM_BASE=32'h10000000,
  parameter INIT_FILE="programs/integration.hex",
  parameter bit DEBUG=0
)(
  input logic clk,reset_n,
  output logic [31:0] debug_pc,debug_instruction,
  output logic debug_fault,debug_retire,debug_reg_write,
  output logic [4:0] debug_reg_addr,
  output logic [31:0] debug_reg_data,debug_mem_addr,
  output logic debug_mem_write
);
  localparam int ADDR_BITS=SRAM_DEPTH>1 ? $clog2(SRAM_DEPTH) : 1;
  axi_lite_if axi(clk,reset_n);
  logic fetch_fault,req_valid,req_write,req_ready,response_valid,response_error;
  logic [31:0] req_addr,req_wdata,response_data;
  logic [3:0] req_wstrb;
  logic sram_en,sram_we;
  logic [ADDR_BITS-1:0] sram_addr;
  logic [31:0] sram_wdata,sram_rdata;
  logic [3:0] sram_wstrb;
  instruction_memory #(.IMEM_DEPTH(IMEM_DEPTH),.BASE_ADDR(RESET_PC),.INIT_FILE(INIT_FILE))
    imem(debug_pc,debug_instruction,fetch_fault);
  riscv_core #(.RESET_PC(RESET_PC),.DEBUG(DEBUG)) core(clk,reset_n,debug_instruction,fetch_fault,debug_pc,
    req_valid,req_write,req_addr,req_wdata,req_wstrb,response_valid,response_error,response_data,
    debug_fault,debug_retire,debug_reg_write,debug_reg_addr,debug_reg_data);
  axi_lite_master master(clk,reset_n,req_valid,req_write,req_addr,req_wdata,req_wstrb,
    req_ready,response_valid,response_error,response_data,axi);
  axi_lite_slave #(.BASE_ADDR(SRAM_BASE),.SRAM_DEPTH(SRAM_DEPTH)) slave(axi,
    sram_en,sram_we,sram_addr,sram_wdata,sram_wstrb,sram_rdata);
  sram #(.DEPTH(SRAM_DEPTH)) data_sram(clk,reset_n,sram_en,sram_we,sram_addr,sram_wdata,sram_wstrb,sram_rdata);
  assign debug_mem_addr=req_addr;
  assign debug_mem_write=req_valid && req_write;
`ifndef SYNTHESIS
  always @(posedge clk) if(reset_n && DEBUG)
    $display("AXI state=%0d AW=%b%b W=%b%b B=%b%b:%b AR=%b%b R=%b%b:%b SRAM en=%b we=%b index=%h wd=%h rd=%h",
      master.state,axi.awvalid,axi.awready,axi.wvalid,axi.wready,axi.bvalid,axi.bready,axi.bresp,
      axi.arvalid,axi.arready,axi.rvalid,axi.rready,axi.rresp,sram_en,sram_we,sram_addr,sram_wdata,sram_rdata);
`endif
endmodule
