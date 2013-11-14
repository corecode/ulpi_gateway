module ulpi_tb_syn(ulpi_link_if.tb ulif, ulpi_if.tb uif);
   default clocking @uif.cb;
   endclocking;

   task write_data(input logic [7:0] data);
      if (uif.dir)
        uif.cb.data <= data;
      else begin
         $display("%d: writing output %x while dir is disabled", $time, data);
         uif.cb.data <= 8'hx;
      end
      @(uif.cb);
   endtask

   task turn_output;
      if (!uif.dir) begin
         uif.cb.dir <= 1;
         @(uif.cb);
      end
   endtask

   task turn_input;
      if (uif.dir) begin
         uif.cb.data <= 8'hz;
         uif.cb.dir <= 0;
         @(uif.cb);
      end
   endtask

   // phy -> link
   task send_incoming_data(int len);
      uif.cb.nxt <= 1;
      repeat (len) begin
         write_data($random());
      end
      uif.cb.nxt <= 0;
   endtask // send_incoming_data

   // system -> link
   task send_cmd(int len);
      logic [7:0] cmd;

      repeat (len) begin
         cmd = $random();
         ulif.cb.cmd <= cmd;
         $display("cmd out: %h", cmd);

         ulif.cb.cmd_strobe <= 1;
         do
           @(ulif.cb);
         while (ulif.cb.cmd_busy);
         ulif.cb.cmd_strobe <= 0;
      end
   endtask // send_cmd

   task phy_recv_cmd;
      automatic int waiting = 0;
      automatic int r;

      $display("incoming cmd");
      while (!uif.cb.stp) begin
         if (!waiting)
           $display("%d: data %x", $time, uif.cb.data);

         r = $random();
         if (r & 1)
           waiting  = 0;
         else
           waiting  = 1;

         if (waiting)
           $display("%d: wait", $time);

         uif.cb.nxt <= !waiting;
         @(uif.cb);
         uif.cb.nxt <= 0;
      end
      $display("end cmd: %x", uif.cb.data);
   endtask


   always_ff @(uif.cb) begin
      if (uif.dir == 0 && uif.cb.data != 8'h00)
        phy_recv_cmd;
   end

   initial begin
      ulif.reset <= 0;
      #5 ulif.reset <= 1;
      #20 ulif.reset <= 0;
      repeat (2)
        @(uif.cb);

      turn_output;
      write_data(8'h23);
      turn_input;
      turn_output;
      write_data(8'h42);
      send_incoming_data(4);
      write_data(8'hf0);
      send_incoming_data(4);
      write_data(8'h23);
      turn_input;

      repeat (3)
        @(uif.cb);
      send_cmd(6);
   end
endmodule

module ulpi_tb;
   logic clk;

   ulpi_if uif(.*);
   ulpi_link_if ulif(.*);
   ulpi_link ulpi_link(.*);

   initial begin
      $dumpfile("ulpi_tb.vcd");
      $dumpvars(0, ulpi_tb);
      $dumpvars(0, uif);
      $dumpvars(0, ulif);
   end

   initial #500 $finish;

   initial begin
      clk = 0;
      #5;
      forever
        #5 clk++;
   end

   initial begin
      uif.cb.dir <= 0;
      uif.nxt <= 0;
      ulif.cmd_strobe <= 0;
      ulif.cmd <= 0;
   end


   ulpi_tb_syn ulpi_tb_syn(.*);

endmodule
