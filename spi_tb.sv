`default_nettype none
`timescale 1 ns / 100 ps

module spi_tb;
   logic        nCS;
   logic        SCK;
   logic        MOSI;
   logic        MISO;

   logic        clk;
   logic        reset;
   logic [7:0]  mosi_data;
   logic [7:0]  miso_data;
   logic        next_byte_ready;
   logic        new_transfer;

spi_slave dut(.*);


task spi_xfer(int length);
   automatic logic [7:0] mosi_out, miso_in;

   nCS  = 0;
   #4;
   repeat (length) begin
      mosi_out   = $random();
      $display("%d: spi => %x", $time, mosi_out);

      for (int b = 7; b >= 0; --b) begin
         MOSI = mosi_out[b];
         #12;
         SCK  = 1;
         #12;
         miso_in[b] = MISO;
         SCK  = 0;
      end
      $display("%d: spi <= %x", $time, miso_in);
   end
   #4;
   nCS  = 1;
   #5;
endtask


initial begin
   $dumpfile("spi_tb.vcd");
   $dumpvars(0, spi_tb);
end

initial
  #1000 $finish;


initial begin
   clk        = 0;
   reset      = 0;
   miso_data  = 0;

   #5 reset   = 1;
   @(posedge clk);
   reset = 0;
end

initial begin
   #10;
   forever
     #10 clk++;
end

always_ff @(posedge clk) begin
   if (new_transfer) begin
      $display("%d: new transfer", $time);
   end

   if (next_byte_ready) begin
      automatic logic [7:0] miso_out;

      $display("%d: sys <= %x", $time, mosi_data);
      miso_out   = $random();
      $display("%d: sys => %x", $time, miso_out);
      miso_data <= miso_out;
   end
end



initial begin
   nCS        = 1;
   SCK        = 0;
   MOSI       = 0;
end

initial begin
   #50 spi_xfer(1);
   #30 spi_xfer(2);
   #30 spi_xfer(1);
end


endmodule
