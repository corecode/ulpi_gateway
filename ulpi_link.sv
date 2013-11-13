`timescale 1 ns / 100 ps

module ulpi_link (
  // ULPI physical
  ulpi_if.link uif,

  // system
  ulpi_link_if.link ulif
);

   typedef enum logic [7:0] {
     NOOP = 8'h00
   } UlpiCmd;

   logic        ulpi_nxt_r;

   logic        ulpi_dir_r;

   logic        valid_rx_data;
   logic        is_bus_turnaround;


   always @(posedge uif.clk or posedge ulif.reset)
     if (ulif.reset)
       ulpi_nxt_r <= 0;
     else
       ulpi_nxt_r <= uif.nxt;

   always @(posedge uif.clk or posedge ulif.reset)
     if (ulif.reset)
       ulpi_dir_r <= 0;
     else
       ulpi_dir_r <= uif.dir;

   assign is_bus_turnaround = uif.dir != ulpi_dir_r;

   assign valid_rx_data = uif.dir && !is_bus_turnaround;

   always @(posedge uif.clk or posedge ulif.reset)
     if (ulif.reset)
       ulif.rx_cmd <= 0;
     else begin
       if (valid_rx_data && !uif.nxt)
         ulif.rx_cmd <= uif.data;
     end

   always @(posedge uif.clk or posedge ulif.reset)
     if (ulif.reset)
       ulif.data <= 0;
     else
       ulif.data <= uif.data;

   always @(posedge uif.clk or posedge ulif.reset)
     if (ulif.reset)
       ulif.data_valid <= 0;
     else begin
       if (valid_rx_data && uif.nxt)
         ulif.data_valid <= 1;
       else
         ulif.data_valid <= 0;
     end

   // XXX
   assign uif.data = (uif.dir | is_bus_turnaround) ? 8'hzz : (ulif.cmd_strobe ? ulif.cmd : NOOP);

endmodule // uif
