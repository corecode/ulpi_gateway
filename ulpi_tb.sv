module ulpi_phy (ulpi_if.tb ulpi);
   logic                            phy_ready;

   logic                            ulpi_dir_r;
   logic                           is_bus_turnaround;

   logic [7:0]                      data_out;
   logic [7:0]                      rx_cmd;

   task write_data;
      input [7:0] data;

      begin
         if (!ulpi_dir_r)
           begin
              // XXX wait if we are not allowed to assert dir
              ulpi.cl.dir = 1;
              @(posedge ulpi.clk);
           end
         ulpi.cl.dir = 1;
         data_out = data;
         @(posedge ulpi.clk);
         ulpi.cl.dir = 0;
      end
   endtask

   initial
     begin
        phy_ready = 0;
        rx_cmd = 0;
        ulpi.dir = 0;
        ulpi_dir_r = 0;
        ulpi.clk = 0;
        ulpi.nxt = 0;
        data_out = 8'h42;

        #15 phy_ready <= 1;
        @(posedge ulpi.clk); #1
        #20 rx_cmd = 8'h23;
     end

   initial
     begin
        @(phy_ready);
        forever
          #5 ulpi.clk = ~ulpi.clk;
     end

   always @(posedge ulpi.clk)
     ulpi_dir_r <= ulpi.dir;

   assign is_bus_turnaround = ulpi.dir != ulpi_dir_r;

   always @(rx_cmd)
     begin
        if (phy_ready)
          write_data(rx_cmd);
     end

   assign ulpi_data = (ulpi_dir_r && !is_bus_turnaround) ? data_out : 8'hzz;

endmodule // ulpi_phy


module ulpi_tb;
   logic clk;

   logic         reset;

   logic [7:0]    sys_data;
   logic        sys_data_valid;

   logic [7:0]   sys_cmd;
   logic [7:0]   sys_rx_cmd;
   logic         sys_cmd_strobe;
   logic        sys_cmd_busy;

   ulpi_if ulpi(.*);

   ulpi_link ulpi_link(.*);
   ulpi_phy ulpi_phy(.*);


   initial
     begin
        reset = 1;
        sys_cmd_strobe = 0;
        sys_cmd = 0;

        #20 @(posedge clk) reset = 0;
     end

   initial
     begin
        $dumpfile("ulpi_tb.vcd");
        $dumpvars(0, ulpi_tb);
     end

   initial #500 $finish;

endmodule
