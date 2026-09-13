class environment;
  mailbox #(transaction) gen_to_drv,mon_to_sb,mon_to_cov;
  generator gen;
  driver drv;
  monitor mon;
  scoreboard sb;
  coverage cov;
  function new(virtual axi_lite_if v);
    gen_to_drv=new;mon_to_sb=new;mon_to_cov=new;
    gen=new(gen_to_drv);drv=new(v,gen_to_drv);mon=new(v,mon_to_sb,mon_to_cov);
    sb=new(mon_to_sb);cov=new(mon_to_cov);
  endfunction
  task run();
    fork gen.run();drv.run();mon.run();sb.run();cov.run();join_none
    wait(drv.finished);
    wait(sb.pass_count+sb.fail_count==gen.generated && cov.total==gen.generated);
    cov.report();
    assert(sb.fail_count==0 && cov.reads>0 && cov.writes>0 && cov.strobe_hits==16'hffff &&
      cov.region_hits==15 && cov.order_hits==7 && cov.delayed_channels==31 && cov.raw_hits>0 && cov.repeated_writes>0)
      else $fatal(1,"OOP failures or missing required coverage");
    $display("PASS OOP AXI scoreboard pass_count=%0d fail_count=%0d generated=%0d",sb.pass_count,sb.fail_count,gen.generated);
  endtask
endclass
