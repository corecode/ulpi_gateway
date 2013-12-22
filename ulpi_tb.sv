`default_nettype none
`timescale 1 ns / 100 ps

module ulpi_tb_syn(ulpi_link_if.tb ulif, ulpi_if.tb uif);
   default clocking @uif.cb;
   endclocking;

   logic driving_out;

   task turn_output;
      driving_out = 1;
      disable phy_recv_cmd;
      uif.cb.dir <= 1;
      if (!uif.dir) begin
         @(uif.cb);
      end
   endtask

   task turn_input;
      if (uif.dir) begin
         uif.cb.data <= 8'hz;
         uif.cb.dir <= 0;
      end
      driving_out = 0;
   endtask

   task write_data(input logic [7:0] data);
      if (uif.dir)
        uif.cb.data <= data;
      else begin
         $display("%d: writing output %x while dir is disabled", $time, data);
         uif.cb.data <= 8'hx;
      end
      @(uif.cb);
   endtask

   task send_rxcmd(logic [7:0] rxcmd);
      turn_output;
      write_data(rxcmd);
      turn_input;
   endtask

   // phy -> link
   task send_incoming_data(int len);
      uif.cb.nxt <= 1;
      turn_output;
      repeat (len) begin
         write_data($random());
      end
      uif.cb.nxt <= 0;
      turn_input;
   endtask // send_incoming_data

   task phy_recv_cmd;
      automatic logic [7:0] cmd;

      $display("%d: incoming cmd", $time);
      cmd = uif.cb.data;
      $display("%d: cmd %x", $time, cmd);

      uif.cb.nxt <= 1;
      @(uif.cb);

      case (cmd[7:6])
        2'b10: begin            // REGW
           automatic logic [7:0] data;

           @(uif.cb);
           uif.cb.nxt   <= 0;
           data          = uif.cb.data;
           $display("%d: write reg %x <= %x", $time, cmd[5:0], data);
           @(uif.cb);
           assert (uif.cb.stp == 1) else $error("no stp from link", $time);
        end
        2'b11: begin            // REGR
           automatic logic [7:0] data;

           uif.cb.nxt <= 0;
           uif.cb.dir <= 1;
           @(uif.cb);
           data = $random();
           $display("%d: read reg %x => %x", $time, cmd[5:0], data);
           uif.cb.data <= data;
           @(uif.cb);
           uif.cb.data <= 8'hzz;
           uif.cb.dir <= 0;
        end
      endcase
      @(uif.cb);
   endtask

   always_ff @(uif.cb) begin
      if (uif.dir == 0 && uif.cb.data != 8'h00 && !driving_out)
        phy_recv_cmd;
   end


   // system -> link -> phy
   task write_reg(int regno, logic [7:0] data);
      ulif.cb.reg_addr        <= regno;
      ulif.cb.reg_data_write  <= data;
      ulif.cb.reg_read_nwrite <= 0;
      ulif.cb.reg_enable      <= 1;

      do begin
         @(uif.cb);
         ulif.cb.reg_enable <= 0;
      end while (!ulif.cb.reg_done);
   endtask

   task read_reg(int regno, output logic [7:0] data);
      ulif.cb.reg_addr        <= regno;
      ulif.cb.reg_read_nwrite <= 1;
      ulif.cb.reg_enable      <= 1;

      do begin
         @(uif.cb);
         ulif.cb.reg_enable <= 0;
      end while (!ulif.cb.reg_done);
      $display("%d: read reg %x", $time, ulif.cb.reg_data_read);
      data <= ulif.cb.reg_data_read;
   endtask

   initial begin
      logic [7:0] regdata;

      ulif.reset <= 0;
      #5 ulif.reset <= 1;
      #20 ulif.reset <= 0;
      repeat (2)
        @(uif.cb);

      send_rxcmd(8'h23);
      send_rxcmd(8'h42);
      @(uif.cb);
      send_incoming_data(4);
      send_rxcmd(8'hf0);
      send_incoming_data(4);
      send_rxcmd(8'h23);

      repeat (3)
        @(uif.cb);
      write_reg(1, 2);
      fork
         begin
            repeat (1)
              @(uif.cb);
            send_incoming_data(3);
         end
         write_reg(3, 4);
      join

      read_reg(6, regdata);
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
      uif.cb.dir              <= 0;
      uif.dir                 <= 0;
      uif.nxt                 <= 0;

      ulif.reg_addr        <= 0;
      ulif.reg_data_write  <= 0;
      ulif.reg_enable      <= 0;
      ulif.reg_read_nwrite <= 0;
   end


   ulpi_tb_syn ulpi_tb_syn(.*);

endmodule
