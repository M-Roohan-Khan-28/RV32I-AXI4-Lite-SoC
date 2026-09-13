class transaction;
  rand bit write;
  rand bit [31:0] address,data;
  rand bit [3:0] strb;
  rand int unsigned aw_delay,w_delay,response_delay;
  logic [1:0] response;
  logic [31:0] read_data;
  int aw_cycle,w_cycle;
  int ar_delay,b_delay,r_delay;
`ifdef FULL_SV
  constraint legal_address { address inside {[32'h10000000:32'h10000ffc]}; address[1:0]==0; }
  constraint delays { aw_delay inside {[0:7]}; w_delay inside {[0:7]}; response_delay inside {[0:7]}; }
  // All 16 WSTRB values are legal, including a no-op zero-strobe write.
`endif
  function new(); response=0; aw_delay=0;w_delay=0;response_delay=0; endfunction
endclass
