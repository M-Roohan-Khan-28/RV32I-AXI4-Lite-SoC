class axi_test extends base_test;
  function new(virtual axi_lite_if vif); super.new(vif); endfunction
  virtual task run(); env.run(); endtask
endclass
