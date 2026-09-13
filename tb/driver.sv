class driver;
  virtual axi_lite_if vif;
  mailbox #(transaction) input_mb;
  bit finished=0;
  function new(virtual axi_lite_if v,mailbox #(transaction) mb); vif=v;input_mb=mb; endfunction
  task initialize();
    vif.awvalid=0;vif.wvalid=0;vif.arvalid=0;vif.bready=0;vif.rready=0;
    vif.awaddr=0;vif.awprot=0;vif.wdata=0;vif.wstrb=0;vif.araddr=0;vif.arprot=0;
  endtask
  task send_aw(transaction t);
    repeat(t.aw_delay) @(negedge vif.clk);
    vif.awaddr=t.address;vif.awvalid=1;
    do @(posedge vif.clk); while(!vif.awready);
    @(negedge vif.clk);vif.awvalid=0;
  endtask
  task send_w(transaction t);
    repeat(t.w_delay) @(negedge vif.clk);
    vif.wdata=t.data;vif.wstrb=t.strb;vif.wvalid=1;
    do @(posedge vif.clk); while(!vif.wready);
    @(negedge vif.clk);vif.wvalid=0;
  endtask
  task run();
    transaction t;
    forever begin
      input_mb.get(t);
      if(t==null) break;
      @(negedge vif.clk);
      if(t.write) begin
        fork send_aw(t);send_w(t);join
        wait(vif.bvalid);
        repeat(t.response_delay+1) @(negedge vif.clk);
        vif.bready=1;
        do @(posedge vif.clk); while(!vif.bvalid);
        @(negedge vif.clk);vif.bready=0;
      end else begin
        vif.araddr=t.address;vif.arvalid=1;
        do @(posedge vif.clk); while(!vif.arready);
        @(negedge vif.clk);vif.arvalid=0;
        wait(vif.rvalid);
        repeat(t.response_delay+1) @(negedge vif.clk);
        vif.rready=1;
        do @(posedge vif.clk); while(!vif.rvalid);
        @(negedge vif.clk);vif.rready=0;
      end
    end
    finished=1;
  endtask
endclass
