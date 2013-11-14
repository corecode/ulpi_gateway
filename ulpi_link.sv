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


   always_ff @(posedge uif.clk or posedge ulif.reset)
     if (ulif.reset)
       ulpi_nxt_r <= 0;
     else
       ulpi_nxt_r <= uif.nxt;

   always_ff @(posedge uif.clk or posedge ulif.reset)
     if (ulif.reset)
       ulpi_dir_r <= 0;
     else
       ulpi_dir_r <= uif.dir;

   assign is_bus_turnaround = uif.dir != ulpi_dir_r;

   assign valid_rx_data = uif.dir && !is_bus_turnaround;

   always_ff @(posedge uif.clk or posedge ulif.reset)
     if (ulif.reset)
       ulif.rx_cmd <= 0;
     else begin
       if (valid_rx_data && !uif.nxt)
         ulif.rx_cmd <= uif.data;
     end

   always_ff @(posedge uif.clk or posedge ulif.reset)
     if (ulif.reset)
       ulif.data <= 0;
     else if (valid_rx_data && uif.nxt)
       ulif.data <= uif.data;

   always_ff @(posedge uif.clk or posedge ulif.reset)
     if (ulif.reset)
       ulif.data_valid <= 0;
     else begin
       if (valid_rx_data && uif.nxt)
         ulif.data_valid <= 1;
       else
         ulif.data_valid <= 0;
     end


   logic tx_active;
   logic [7:0] out_cmd;

   always_ff @(posedge ulif.clk or posedge ulif.reset)
     if (ulif.reset) begin
        out_cmd <= NOOP;
        tx_active <= 0;
     end else begin
        if (!ulif.cmd_strobe) begin
           out_cmd <= NOOP;
           tx_active <= 0;
        end else if (!ulif.cmd_busy) begin
           out_cmd <= ulif.cmd;
           tx_active <= 1;
        end
     end

   always_comb begin
      ulif.cmd_busy <= 0;
      if (uif.dir || is_bus_turnaround)
        ulif.cmd_busy <= 1;
      if (tx_active && !uif.nxt)
        ulif.cmd_busy <= 1;
   end


   assign uif.data = (uif.dir || is_bus_turnaround) ? 8'hzz : out_cmd;


   always_ff @(posedge uif.clk or posedge ulif.reset)
     if (ulif.reset)
       uif.stp <= 0;
     else begin
        if (tx_active && !ulif.cmd_strobe)
          uif.stp <= 1;
        else
          uif.stp <= 0;
     end


endmodule // uif
