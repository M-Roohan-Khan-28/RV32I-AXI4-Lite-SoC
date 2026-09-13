`timescale 1ns/1ps
module axi_reset_test;
  bit clk=0,reset_n=0;
  always #5 clk=~clk;
  axi_lite_if bus(clk,reset_n);
  logic en,we;
  logic [1:0] addr;
  logic [31:0] wd,rd;
  logic [3:0] strb;
  // A non-power-of-two depth catches accidental index truncation/aliasing.
  axi_lite_slave #(.SRAM_DEPTH(3)) slave(bus,en,we,addr,wd,strb,rd);
  sram #(.DEPTH(3)) ram(clk,reset_n,en,we,addr,wd,strb,rd);
  axi_protocol_checker protocol(bus);
  task automatic initialize();
    bus.awvalid=0;bus.wvalid=0;bus.arvalid=0;bus.bready=0;bus.rready=0;
    bus.awaddr=0;bus.awprot=0;bus.wdata=0;bus.wstrb=15;bus.araddr=0;bus.arprot=0;
  endtask
  task automatic reset_bus();
    @(negedge clk);reset_n=0;initialize();repeat(2) @(negedge clk);reset_n=1;
    assert(!bus.bvalid && !bus.rvalid) else $fatal(1,"stale response after reset");
  endtask
  task automatic send_aw(input logic [31:0] a);
    @(negedge clk);bus.awaddr=a;bus.awvalid=1;
    do @(posedge clk);while(!bus.awready);
    @(negedge clk);bus.awvalid=0;
  endtask
  task automatic send_w(input logic [31:0] d);
    @(negedge clk);bus.wdata=d;bus.wvalid=1;
    do @(posedge clk);while(!bus.wready);
    @(negedge clk);bus.wvalid=0;
  endtask
  task automatic send_ar(input logic [31:0] a);
    @(negedge clk);bus.araddr=a;bus.arvalid=1;
    do @(posedge clk);while(!bus.arready);
    @(negedge clk);bus.arvalid=0;
  endtask
  task automatic consume_b(input logic [1:0] expected=0);
    wait(bus.bvalid);@(negedge clk);
    assert(bus.bresp===expected) else $fatal(1,"reset test B response");
    bus.bready=1;@(negedge clk);bus.bready=0;
  endtask
  task automatic consume_r(input logic [31:0] expected,input logic [1:0] status=0);
    wait(bus.rvalid);@(negedge clk);
    assert(bus.rresp===status && bus.rdata===expected) else $fatal(1,"reset/arbitration read got=%h",bus.rdata);
    bus.rready=1;@(negedge clk);bus.rready=0;
  endtask
  initial begin
    initialize();reset_bus();
    send_aw('h10000000);reset_bus(); // discard an unpaired address
    send_w('haabbccdd);repeat(4) @(negedge clk);
    assert(!bus.bvalid && !en) else $fatal(1,"old AW survived reset");
    send_aw('h10000008);consume_b();send_ar('h10000008);consume_r('haabbccdd);
    send_w('hdeadbeef);reset_bus(); // discard unpaired data
    send_aw('h10000008);repeat(4) @(negedge clk);
    assert(!bus.bvalid && !en) else $fatal(1,"old W survived reset");
    send_w('h12345678);consume_b();
    send_ar('h10000008);wait(bus.rvalid);reset_bus(); // discard stalled R
    send_ar('h10000008);consume_r('h12345678); // memory retained
    fork send_aw('h10000008);send_w('h87654321);send_ar('h10000008);join
    // Both buffered on the same edge: write has SRAM-port priority.
    fork consume_b();consume_r('h87654321);join
    fork send_aw('h1000000c);send_w(0);join
    consume_b(2'b10);send_ar('h1000000c);consume_r(0,2'b10);
    send_ar('h10000008);consume_r('h87654321);
    fork send_aw('h10000008);send_w('h55555555);join
    wait(bus.bvalid);reset_bus(); // completed store survives cancellation of B
    send_ar('h10000008);consume_r('h55555555);
    $display("PASS AXI partial AW/W reset, stalled B/R reset, retention, simultaneous read/write, depth=3 bounds");$finish;
  end
  initial begin #100000; $fatal(1,"reset test timeout");end
endmodule
