module spi_master_tb;

  reg reset,
      get_rdid;

  /* Reset Plus Load */
  initial begin
	  $dumpfile("spi_master.vcd");
	  $dumpvars(0,spi_master_tb);
	  # 10  reset = 1;
    # 10  reset = 0;
	  # 150 reset = 1;
    # 20  reset = 0;
    # 4000 $stop;
  end

  /* Get RDID */
  initial begin
    # 10  get_rdid = 1;
    # 400 get_rdid = 0;
  end

  /* Clock */
  reg clk = 0;
  always #5 clk = !clk;

  /* Instantiation */
  spi_master m1 (clk,reset,get_rdid);


  //initial
	//$monitor("At time %t, value = %h (%0d)",
	//		  $time, value, value);

endmodule