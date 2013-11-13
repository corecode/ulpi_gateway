interface ulpi_if(input wire clk);
   logic       dir;
   logic       nxt;
   logic       stp;
   tri [7:0]   data;

   clocking cb @(posedge clk);
      output   dir;
      output   nxt;
      input    stp;
      inout    data;

      default input #1 output #0;
   endclocking // phy_cb

   modport link(input clk,
                input dir,
                input  nxt,
                output stp,
                inout  data);

   modport tb(clocking cb, input dir, input clk);

endinterface
