`timescale 1 ns / 100 ps

module ulpi_link (
  // ULPI physical
  ulpi_if.link ulpi,

  // system
  input logic       reset,

  output logic [7:0] sys_data,
  output logic       sys_data_valid,
  output logic [7:0] sys_rx_cmd,

  input logic [7:0] sys_cmd,
  input logic       sys_cmd_strobe,
  output logic      sys_cmd_busy
);

   typedef enum logic [7:0] {
     NOOP = 8'h00
   } UlpiCmd;

   logic                         ulpi_nxt_r;

   logic                         ulpi_dir_r;
   logic                        ulpi_dir_changed;

   logic                        valid_rx_data;
   logic                        is_bus_turnaround;


   always @(posedge ulpi.clk or posedge reset)
     if (reset)
       ulpi_nxt_r <= 0;
     else
       ulpi_nxt_r <= ulpi.nxt;

   always @(posedge ulpi.clk or posedge reset)
     if (reset)
       ulpi_dir_r <= 0;
     else
       ulpi_dir_r <= ulpi.dir;

   assign is_bus_turnaround = ulpi.dir != ulpi_dir_r;

   assign valid_rx_data = ulpi.dir && !is_bus_turnaround;

   always @(posedge ulpi.clk or posedge reset)
     if (reset)
       sys_rx_cmd <= 0;
     else begin
       if (valid_rx_data && !ulpi.nxt)
         sys_rx_cmd <= ulpi.data;
     end

   always @(posedge ulpi.clk or posedge reset)
     if (reset)
       sys_data <= 0;
     else
       sys_data <= ulpi.data;

   always @(posedge ulpi.clk or posedge reset)
     if (reset)
       sys_data_valid <= 0;
     else begin
       if (valid_rx_data && ulpi.nxt)
         sys_data_valid <= 1;
       else
         sys_data_valid <= 0;
     end

   // XXX
   assign ulpi.data = (ulpi.dir | is_bus_turnaround) ? 8'hzz : (sys_cmd_strobe ? sys_cmd : NOOP);

endmodule // ulpi
