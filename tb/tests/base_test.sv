virtual class base_test;
  environment env;
  function new(virtual axi_lite_if vif); env=new(vif); endfunction
  pure virtual task run();
endclass
