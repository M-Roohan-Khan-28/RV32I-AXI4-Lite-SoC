class coverage;
  mailbox #(transaction) input_mb;
  int reads=0,writes=0,raw_hits=0,repeated_writes=0,total=0;
  bit [15:0] strobe_hits=0;
  bit [3:0] region_hits=0;
  bit [2:0] order_hits=0;
  bit [4:0] delayed_channels=0;
  bit previous_write=0;
  bit [31:0] previous_address=0;
`ifdef FULL_SV
  covergroup axi_cg with function sample(transaction t,bit raw_access,bit repeated,int ordering);
    option.per_instance=1;
    operation: coverpoint t.write;
    region: coverpoint t.address[11:10] { bins quarters[]={[0:3]}; }
    strobes: coverpoint t.strb iff(t.write) { bins patterns[]={[0:15]}; }
    raw_cp: coverpoint raw_access { bins hit={1}; }
    repeat_cp: coverpoint repeated { bins hit={1}; }
    aw_order: coverpoint ordering iff(t.write) { bins orders[]={[0:2]}; }
    aw_delay_cp: coverpoint t.aw_delay iff(t.write) { bins zero={0}; bins delayed={[1:255]}; }
    w_delay_cp: coverpoint t.w_delay iff(t.write) { bins zero={0}; bins delayed={[1:255]}; }
    b_delay_cp: coverpoint t.b_delay iff(t.write) { bins zero={0}; bins delayed={[1:255]}; }
    ar_delay_cp: coverpoint t.ar_delay iff(!t.write) { bins zero={0}; bins delayed={[1:255]}; }
    r_delay_cp: coverpoint t.r_delay iff(!t.write) { bins zero={0}; bins delayed={[1:255]}; }
    op_region: cross operation,region;
  endgroup
`endif
  function new(mailbox #(transaction) mb);
    input_mb=mb;
`ifdef FULL_SV
    axi_cg=new;
`endif
  endfunction
  task run();
    transaction t;
    bit raw_access,repeated;
    int ordering;
    forever begin
      input_mb.get(t);total++;
      raw_access=previous_write && !t.write && previous_address==t.address;
      repeated=previous_write && t.write && previous_address==t.address;
      ordering=t.aw_cycle<t.w_cycle ? 0 : t.aw_cycle==t.w_cycle ? 1 : 2;
      if(t.write) begin writes++;strobe_hits[t.strb]=1;order_hits[ordering]=1; end else reads++;
      region_hits[t.address[11:10]]=1;
      if(raw_access) raw_hits++;
      if(repeated) repeated_writes++;
      if(t.aw_delay>0) delayed_channels[0]=1;
      if(t.w_delay>0) delayed_channels[1]=1;
      if(t.b_delay>0) delayed_channels[2]=1;
      if(t.ar_delay>0) delayed_channels[3]=1;
      if(t.r_delay>0) delayed_channels[4]=1;
`ifdef FULL_SV
      axi_cg.sample(t,raw_access,repeated,ordering);
`endif
      previous_write=t.write;previous_address=t.address;
    end
  endtask
  function void report();
    $display("COVERAGE AXI reads=%0d writes=%0d strobes=%h regions=%b AW/W_orders=%b delayed_channels=%b RAW=%0d repeated_writes=%0d",
      reads,writes,strobe_hits,region_hits,order_hits,delayed_channels,raw_hits,repeated_writes);
`ifdef FULL_SV
    $display("COVERAGE AXI covergroup=%0.2f%%",axi_cg.get_inst_coverage());
`endif
  endfunction
endclass
