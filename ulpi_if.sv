interface ulpi_if(input wire clk);
   logic       dir;
   logic       nxt;
   logic       stp;
   tri [7:0]   data;

   clocking cl @(posedge clk);
      output   dir;
      output   nxt;
      input    nxt;
      inout    data;

      default input #1 output #0;
   endclocking // phy_cb

   modport link(input clk,
                input dir,
                input  nxt,
                output stp,
                inout  data);

   modport tb(clocking cl, input clk);

endinterface
