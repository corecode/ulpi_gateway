`timescale 1 ns / 100 ps

module ulpi (
             // ULPI physical
             input wire       ulpi_clk,
             input wire       ulpi_dir,
             input wire       ulpi_nxt,
             output wire      ulpi_stp,
             inout wire [7:0] ulpi_data,

             // system
             input wire       sys_reset,

             output reg [7:0] sys_data,
             output reg       sys_data_valid,
             output reg [7:0] sys_rx_cmd,

             input wire [7:0] sys_cmd,
             input wire       sys_cmd_strobe,
             output wire      sys_cmd_busy
);

   localparam CMD_NOOP = 8'b00000000;

   reg                         ulpi_nxt_r;

   reg                         ulpi_dir_r;
   wire                        ulpi_dir_changed;

   wire                        valid_rx_data;
   wire                        bus_turnaround_p;


   always @(posedge ulpi_clk or posedge sys_reset)
     if (sys_reset) ulpi_nxt_r <= 0;
     else           ulpi_nxt_r <= ulpi_nxt;

   always @(posedge ulpi_clk or posedge sys_reset)
     if (sys_reset) ulpi_dir_r <= 0;
     else           ulpi_dir_r <= ulpi_dir;

   assign bus_turnaround_p = ulpi_dir != ulpi_dir_r;

   assign valid_rx_data = ulpi_dir && !bus_turnaround_p;

   always @(posedge ulpi_clk or posedge sys_reset)
     if (sys_reset)                       sys_rx_cmd <= 0;
     else if (valid_rx_data && !ulpi_nxt) sys_rx_cmd <= ulpi_data;

   always @(posedge ulpi_clk or posedge sys_reset)
     if (sys_reset) sys_data <= 0;
     else           sys_data <= ulpi_data;

   always @(posedge ulpi_clk or posedge sys_reset)
     if (sys_reset)                      sys_data_valid <= 0;
     else if (valid_rx_data && ulpi_nxt) sys_data_valid <= 1;
     else                                sys_data_valid <= 0;

   assign ulpi_data = (ulpi_dir | bus_turnaround_p) ? 8'hzz : (sys_cmd_strobe ? sys_cmd : CMD_NOOP);

endmodule // ulpi


`ifndef synthesis
module ulpi_phy (
                 // ULPI physical
                 output reg       ulpi_clk,
                 output reg       ulpi_dir,
                 output reg       ulpi_nxt,
                 input wire       ulpi_stp,
                 inout wire [7:0] ulpi_data);

   reg                            phy_ready;

   reg                            ulpi_dir_r;
   wire                           bus_turnaround_p;

   reg [7:0]                      data_out;
   reg [7:0]                      rx_cmd;

   task write_data;
      input [7:0] data;

      begin
         if (!ulpi_dir_r)
           begin
              // XXX wait if we are not allowed to assert dir
              ulpi_dir = 1;
              @(posedge ulpi_clk);
           end
         ulpi_dir = 1;
         data_out = data;
         @(posedge ulpi_clk);
         ulpi_dir = 0;
      end
   endtask

   initial
     begin
        phy_ready = 0;
        rx_cmd = 0;
        ulpi_dir = 0;
        ulpi_dir_r = 0;
        ulpi_clk = 0;
        ulpi_nxt = 0;
        data_out = 8'h42;

        #15 phy_ready = 1;
        @(posedge ulpi_clk); #1
        #20 rx_cmd = 8'h23;
     end

   initial
     begin
        @(phy_ready);
        forever
          #5 ulpi_clk = ~ulpi_clk;
     end

   always @(posedge ulpi_clk)
     ulpi_dir_r <= ulpi_dir;

   assign bus_turnaround_p = ulpi_dir != ulpi_dir_r;

   always @(rx_cmd)
     begin
        if (phy_ready)
          write_data(rx_cmd);
     end

   assign ulpi_data = (ulpi_dir_r && !bus_turnaround_p) ? data_out : 8'hzz;

endmodule // ulpi_phy


module ulpi_tb;
   wire        ulpi_clk;
   wire        ulpi_dir;
   wire        ulpi_nxt;
   wire        ulpi_stp;
   wire [7:0]  ulpi_data;

   reg         sys_reset;

   wire [7:0]  sys_data;
   wire        sys_data_valid;

   reg [7:0]   sys_cmd;
   reg         sys_cmd_strobe;
   wire        sys_cmd_busy;

   ulpi ulpi(
             .ulpi_clk(ulpi_clk),
             .ulpi_dir(ulpi_dir),
             .ulpi_nxt(ulpi_nxt),
             .ulpi_stp(ulpi_stp),
             .ulpi_data(ulpi_data),

             .sys_reset(sys_reset),
             .sys_data(sys_data),
             .sys_data_valid(sys_data_valid),

             .sys_cmd(sys_cmd),
             .sys_cmd_strobe(sys_cmd_strobe),
             .sys_cmd_busy(sys_cmd_busy));

   ulpi_phy ulpi_phy(
                     .ulpi_clk(ulpi_clk),
                     .ulpi_dir(ulpi_dir),
                     .ulpi_nxt(ulpi_nxt),
                     .ulpi_stp(ulpi_stp),
                     .ulpi_data(ulpi_data));

   initial
     begin
        sys_reset = 1;
        sys_cmd_strobe = 0;
        sys_cmd = 0;

        #20 @(posedge ulpi_clk) sys_reset = 0;
     end

   initial
     begin
        $dumpfile("ulpi_tb.vcd");
        $dumpvars(0, ulpi_tb);
     end

   initial #500 $finish;

endmodule // ulpi_tb
`endif
