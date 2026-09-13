class monitor;
  virtual axi_lite_if vif;
  mailbox #(transaction) scoreboard_mb,coverage_mb;
  function new(virtual axi_lite_if v,mailbox #(transaction) sb,cv); vif=v;scoreboard_mb=sb;coverage_mb=cv; endfunction
  task run();
    transaction wt=new,rt=new;
    int cycle=0;
    forever begin
      @(posedge vif.clk);
      if(!vif.reset_n) begin wt=new;rt=new;cycle=0; end
      else begin
        cycle++;
        if(vif.awvalid && !vif.awready) wt.aw_delay++;
        if(vif.wvalid && !vif.wready) wt.w_delay++;
        if(vif.arvalid && !vif.arready) rt.ar_delay++;
        if(vif.bvalid && !vif.bready) wt.b_delay++;
        if(vif.rvalid && !vif.rready) rt.r_delay++;
        if(vif.awvalid && vif.awready) begin wt.address=vif.awaddr;wt.aw_cycle=cycle; end
        if(vif.wvalid && vif.wready) begin wt.data=vif.wdata;wt.strb=vif.wstrb;wt.w_cycle=cycle; end
        if(vif.arvalid && vif.arready) rt.address=vif.araddr;
        if(vif.bvalid && vif.bready) begin
          wt.write=1;wt.response=vif.bresp;
          scoreboard_mb.put(wt);coverage_mb.put(wt);wt=new;
        end
        if(vif.rvalid && vif.rready) begin
          rt.write=0;rt.read_data=vif.rdata;rt.response=vif.rresp;
          scoreboard_mb.put(rt);coverage_mb.put(rt);rt=new;
        end
      end
    end
  endtask
endclass
