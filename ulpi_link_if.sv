interface ulpi_link_if(input wire clk);
   logic       reset;
   logic [7:0] data;
   logic       data_valid;
   logic [7:0] rx_cmd;
   logic [7:0] cmd;
   logic       cmd_strobe;
   logic       cmd_busy;

   modport link(input clk,
                input  reset,
                output data,
                output data_valid,
                output rx_cmd,
                input  cmd,
                input  cmd_strobe,
                output cmd_busy);

`ifndef synthesis
   clocking cb @(posedge clk);
      input    data;
      input    data_valid;
      input    rx_cmd;
      output   cmd;
      output   cmd_strobe;
      input    cmd_busy;

      default input #1 output #0;
   endclocking // phy_cb

   modport tb(clocking cb, input clk, output reset);
`endif

endinterface
