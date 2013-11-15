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


   logic [7:0] out_cmd;
   enum logic [2:0] {
         IDLE = 3'b001,
         CMD = 3'b010,
         FINISH = 3'b100
   } cmd_state;


   logic ulpi_dir_r;
   logic is_bus_turnaround;
   logic is_valid_data;
   logic is_bus_ours;

   assign is_bus_turnaround = uif.dir != ulpi_dir_r;
   assign is_bus_ours       = !uif.dir && !is_bus_turnaround;
   assign is_valid_data     = ulpi_dir_r && !is_bus_turnaround;
   assign uif.data          = is_bus_ours ? out_cmd : 8'hzz;

   always_comb begin
      if (is_bus_ours && (cmd_state == IDLE ||
                          cmd_state == CMD && uif.nxt))
        ulif.cmd_busy <= 0;
      else
        ulif.cmd_busy <= 1;
   end

   always_ff @(posedge uif.clk or posedge ulif.reset) begin
      if (ulif.reset) begin
         ulif.data_valid <= 0;
         cmd_state       <= IDLE;
         uif.stp         <= 0;
         out_cmd         <= NOOP;
         ulif.data       <= 0;
         ulif.rx_cmd     <= 0;
         ulpi_dir_r      <= 0;
      end else begin
         ulpi_dir_r      <= uif.dir;

         if (is_valid_data) begin
            if (uif.nxt) begin
               ulif.data       <= uif.data;
               ulif.data_valid <= 1;
            end else begin
               ulif.rx_cmd     <= uif.data;
               ulif.data_valid <= 0;
            end
         end else begin
            ulif.data_valid <= 0;
         end

         uif.stp <= 0;

         if (cmd_state == IDLE)
           out_cmd <= NOOP;

         /*
          * If we're (still) receiving, pass the data if it is
          * valid and there is space on the output bus.
          */
         if (ulif.cmd_strobe && is_bus_ours &&
             (cmd_state == IDLE ||
              (cmd_state == CMD && uif.nxt))) begin
            out_cmd       <= ulif.cmd;
            cmd_state     <= CMD;
         end

         /*
          * If there is no more data, or we're about to finish, we finish.
          */
         if (cmd_state == CMD && !ulif.cmd_strobe ||
             cmd_state == FINISH) begin
            cmd_state  <= FINISH;
            /*
             * Only signal STP when the PHY says NXT.
             */
            if (uif.nxt) begin
               cmd_state <= IDLE;
               uif.stp   <= 1;
               out_cmd   <= 8'h00; // success
            end
         end
      end
   end

endmodule // uif
