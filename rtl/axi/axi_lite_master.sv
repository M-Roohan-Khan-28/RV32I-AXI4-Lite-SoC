module axi_lite_master (
  input logic clk, reset_n,
  input logic req_valid, req_write,
  input logic [31:0] req_addr, req_wdata,
  input logic [3:0] req_wstrb,
  output logic req_ready, response_valid, response_error,
  output logic [31:0] response_data,
  axi_lite_if.MASTER axi
);
  typedef enum logic [1:0] {IDLE,WRITE,READ,DONE} state_t;
  state_t state;
  assign req_ready=reset_n && state==IDLE;
  assign response_valid=reset_n && state==DONE;
  assign axi.bready=reset_n && state==WRITE && !axi.awvalid && !axi.wvalid;
  assign axi.rready=reset_n && state==READ && !axi.arvalid;
  assign axi.awprot=3'b000;
  assign axi.arprot=3'b000;
  always_ff @(posedge clk) begin
    if(!reset_n) begin
      state<=IDLE; axi.awvalid<=0; axi.wvalid<=0; axi.arvalid<=0;
      axi.awaddr<=0; axi.wdata<=0; axi.wstrb<=0; axi.araddr<=0;
      response_error<=0; response_data<=0;
    end else begin
      if(axi.awvalid && axi.awready) axi.awvalid<=0;
      if(axi.wvalid && axi.wready) axi.wvalid<=0;
      if(axi.arvalid && axi.arready) axi.arvalid<=0;
      case(state)
        IDLE: if(req_valid) begin
          response_error<=0;
          if(req_write) begin
            axi.awaddr<=req_addr; axi.wdata<=req_wdata; axi.wstrb<=req_wstrb;
            axi.awvalid<=1; axi.wvalid<=1; state<=WRITE;
          end else begin axi.araddr<=req_addr; axi.arvalid<=1; state<=READ; end
        end
        WRITE: if(axi.bvalid && axi.bready) begin response_error<=axi.bresp!=0; state<=DONE; end
        READ: if(axi.rvalid && axi.rready) begin
          response_data<=axi.rdata; response_error<=axi.rresp!=0; state<=DONE;
        end
        // CPU consumes completion at this edge; do not re-accept its old request.
        DONE: state<=IDLE;
        default: state<=IDLE;
      endcase
    end
  end
endmodule
