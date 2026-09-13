module instruction_memory #(
  parameter int IMEM_DEPTH=1024,
  parameter logic [31:0] BASE_ADDR=0,
  parameter INIT_FILE=""
)(input logic [31:0] address, output logic [31:0] instruction, output logic fault);
  logic [31:0] imem[0:IMEM_DEPTH-1];
  initial begin
    for(int i=0;i<IMEM_DEPTH;i++) imem[i]=32'h00000013;
    if(INIT_FILE!="") $readmemh(INIT_FILE,imem);
  end
  always_comb begin
    fault=(address<BASE_ADDR || (address-BASE_ADDR)/4>=IMEM_DEPTH || address[1:0]!=0);
    instruction=32'h00000013;
    if(!fault) instruction=imem[(address-BASE_ADDR)>>2];
  end
endmodule
