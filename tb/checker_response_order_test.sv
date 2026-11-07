// Directed qualification for axi_protocol_checker, not a DUT functional test.
// Every negative CASE runs in its own fresh simulation and reset interval.
// Stimulus changes at falling edges using nonblocking assignments.
`timescale 1ns/1ps
module checker_response_order_test;
  bit clk=0, reset_n=0;
  always #5 clk=~clk;
  axi_lite_if bus(clk,reset_n);
  axi_protocol_checker #(.MAX_WAIT(32)) mon(bus);
  int test_case=0;

  task automatic idle_bus;
    bus.awaddr<=32'h10000000; bus.awprot<=0;
    bus.wdata<=32'h725ac913; bus.wstrb<=4'hf;
    bus.araddr<=32'h10000000; bus.arprot<=0;
    bus.rdata<=32'h725ac913; bus.rresp<=0; bus.bresp<=0;
    bus.awvalid<=0; bus.wvalid<=0; bus.arvalid<=0;
    bus.bvalid<=0; bus.rvalid<=0;
    bus.awready<=1; bus.wready<=1; bus.arready<=1;
    bus.bready<=0; bus.rready<=0;
  endtask

  task automatic legal_write(input int ordering);
    @(negedge clk);
    if(ordering==0) begin
      bus.awvalid<=1;
      @(negedge clk); bus.awvalid<=0; bus.wvalid<=1;
      @(negedge clk); bus.wvalid<=0;
    end else if(ordering==1) begin
      bus.wvalid<=1;
      @(negedge clk); bus.wvalid<=0; bus.awvalid<=1;
      @(negedge clk); bus.awvalid<=0;
    end else begin
      bus.awvalid<=1; bus.wvalid<=1;
      @(negedge clk); bus.awvalid<=0; bus.wvalid<=0;
    end
    // Both requests were accepted at earlier rising edges.
    bus.bvalid<=1;
    repeat(3) @(negedge clk);
    bus.bready<=1;
    @(negedge clk); bus.bvalid<=0; bus.bready<=0;
  endtask

  task automatic legal_read;
    @(negedge clk); bus.arvalid<=1;
    @(negedge clk); bus.arvalid<=0; bus.rvalid<=1;
    repeat(3) @(negedge clk);
    bus.rready<=1;
    @(negedge clk); bus.rvalid<=0; bus.rready<=0;
  endtask

  initial begin
    if(!$value$plusargs("CASE=%d",test_case)) test_case=0;
    idle_bus();
    repeat(3) @(negedge clk);
    reset_n<=1;
    @(negedge clk);
    case(test_case)
      0: begin
        legal_write(0); legal_write(1); legal_write(2); legal_read();
        @(negedge clk);
        if(mon.writes!=3 || mon.reads!=1)
          $fatal(1,"CHECKER_ORDER_POSITIVE_COUNTS W=%0d R=%0d",mon.writes,mon.reads);
        $display("CHECKER_ORDER_POSITIVE_PASS writes=3 reads=1");
        $finish;
      end
      1: begin // BVALID held while neither AW nor W has been accepted.
        bus.bvalid<=1;
        repeat(4) @(negedge clk);
      end
      2: begin // AW accepted; W is still missing; BREADY remains low.
        bus.awvalid<=1;
        @(negedge clk); bus.awvalid<=0; bus.bvalid<=1;
        repeat(4) @(negedge clk);
      end
      3: begin // W accepted first; AW is still missing.
        bus.wvalid<=1;
        @(negedge clk); bus.wvalid<=0; bus.bvalid<=1;
        repeat(4) @(negedge clk);
      end
      4: begin // RVALID held without an earlier AR handshake.
        bus.rvalid<=1;
        repeat(4) @(negedge clk);
      end
      5: begin // AW, W and B handshakes on the same edge: no prior eligibility.
        bus.awvalid<=1; bus.wvalid<=1; bus.bvalid<=1; bus.bready<=1;
        @(negedge clk); idle_bus();
        repeat(2) @(negedge clk);
      end
      6: begin // AR and R handshakes on the same edge.
        bus.arvalid<=1; bus.rvalid<=1; bus.rready<=1;
        @(negedge clk); idle_bus();
        repeat(2) @(negedge clk);
      end
      7: begin // AW is older, but W and B arrive on the same edge.
        bus.awvalid<=1;
        @(negedge clk); bus.awvalid<=0; bus.wvalid<=1; bus.bvalid<=1; bus.bready<=1;
        @(negedge clk); idle_bus();
        repeat(2) @(negedge clk);
      end
      8: begin // W is older, but AW and B arrive on the same edge.
        bus.wvalid<=1;
        @(negedge clk); bus.wvalid<=0; bus.awvalid<=1; bus.bvalid<=1; bus.bready<=1;
        @(negedge clk); idle_bus();
        repeat(2) @(negedge clk);
      end
      default: $fatal(1,"CHECKER_ORDER_INVALID_CASE case=%0d",test_case);
    endcase
    $fatal(1,"CHECKER_ORDER_UNDETECTED case=%0d",test_case);
  end
  initial begin #10000; $fatal(1,"CHECKER_ORDER_TIMEOUT"); end
endmodule
