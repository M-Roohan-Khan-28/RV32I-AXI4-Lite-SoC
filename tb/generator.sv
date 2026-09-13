class generator;
  mailbox #(transaction) output_mb;
  int generated=0;
  function new(mailbox #(transaction) mb); output_mb=mb; endfunction
  task send(input bit wr,input bit [31:0] addr,d,input bit [3:0] st,
    input int ad=0,wd=0,backpressure=0);
    transaction t=new;
    t.write=wr;t.address=addr;t.data=d;t.strb=st;t.aw_delay=ad;t.w_delay=wd;t.response_delay=backpressure;
    output_mb.put(t);generated++;
  endtask
  task run();
    transaction t;
    // Define initial contents explicitly; SRAM has no reset initialization.
    for(int i=0;i<1024;i++) send(1,32'h10000000+4*32'(i),32'h13570000+32'(i),15);
    // Hit every strobe and all AW/W orderings, with RAW and repeated writes.
    for(int st=0;st<16;st++) begin
      send(1,32'h10000000,32'haabbccdd,4'(st),st%3,(st+1)%3,st%8);
      send(1,32'h10000000,32'h12345678,4'(st),(st+1)%3,st%3,st%8);
      send(0,32'h10000000,0,0,0,0,st%8);
    end
    send(0,32'h10000800,0,0);send(0,32'h10000ffc,0,0);
    for(int i=0;i<256;i++) begin
      t=new;
`ifdef FULL_SV
      assert(t.randomize()) else $fatal(1,"transaction randomization failed");
`else
      t.write=1;t.address=32'h10000000+4*$urandom_range(1023,0);
      t.data=$urandom;t.strb=4'($urandom_range(15,0));
      t.aw_delay=$urandom_range(7,0);t.w_delay=$urandom_range(7,0);t.response_delay=$urandom_range(7,0);
`endif
      // Force write/read pairs so every random update is compared.
      t.write=1;output_mb.put(t);generated++;
      send(0,t.address,0,0,0,0,t.response_delay);
    end
    output_mb.put(null);
  endtask
endclass
