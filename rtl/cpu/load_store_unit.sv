module load_store_unit (
  input logic enable, mem_read, mem_write,
  input logic [31:0] address, store_data,
  input logic response_valid, response_error,
  input logic [31:0] response_data,
  output logic req_valid, req_write,
  output logic [31:0] req_addr, req_wdata,
  output logic [3:0] req_wstrb,
  output logic complete, fault,
  output logic [31:0] load_data
);
  assign req_valid=enable && (mem_read || mem_write) && address[1:0]==0;
  assign req_write=mem_write;
  assign req_addr=address;
  assign req_wdata=store_data;
  assign req_wstrb=4'b1111;
  assign complete=response_valid;
  assign fault=(mem_read || mem_write) && (address[1:0]!=0 || (response_valid && response_error));
  assign load_data=response_data;
endmodule
