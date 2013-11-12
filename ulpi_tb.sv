module ulpi_tb;
   logic clk;
   logic reset;

   logic [7:0] sys_data;
   logic       sys_data_valid;

   logic [7:0] sys_cmd;
   logic [7:0] sys_rx_cmd;
   logic       sys_cmd_strobe;
   logic       sys_cmd_busy;

   ulpi_if ulpi(.*);

   ulpi_link ulpi_link(.*);

   initial begin
      reset <= 1;
      sys_cmd_strobe <= 0;
      sys_cmd <= 0;

      repeat (2)
        @(posedge clk);
      reset <= 0;
   end

   initial begin
      clk = 0;
      #20;
      forever
        #10 clk++;
   end


   initial
     begin
        $dumpfile("ulpi_tb.vcd");
        $dumpvars(0, ulpi_tb);
     end

   initial #500 $finish;

endmodule
