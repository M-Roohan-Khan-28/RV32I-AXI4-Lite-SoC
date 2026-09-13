class scoreboard;
  logic [31:0] reference_memory[0:1023];
  bit [3:0] known[0:1023];
  mailbox #(transaction) input_mb;
  int pass_count=0,fail_count=0;
  function new(mailbox #(transaction) mb); input_mb=mb; endfunction
  task run();
    transaction t;
    int index;
    bit good;
    forever begin
      input_mb.get(t);index=int'((t.address-32'h10000000)>>2);good=1;
      if(t.response!==0 || index<0 || index>=1024 || t.address[1:0]!=0) good=0;
      else if(t.write) begin
        for(int lane=0;lane<4;lane++) if(t.strb[lane]) begin
          reference_memory[index][lane*8+:8]=t.data[lane*8+:8];known[index][lane]=1;
        end
      end else begin
        if(known[index]!=15 || t.read_data!==reference_memory[index]) good=0;
      end
      if(good) pass_count++;
      else begin fail_count++; $error("FAIL scoreboard write=%b address=%h data=%h expected=%h resp=%b",t.write,t.address,t.write ? t.data : t.read_data,reference_memory[index],t.response); end
    end
  endtask
endclass
