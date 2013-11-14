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

   logic        ulpi_dir_r;

   logic        valid_rx_data;
   logic        is_bus_turnaround;


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


   logic [7:0] out_cmd;
   enum logic [1:0] {
         IDLE = 2'b00,
         CMD = 2'b01,
         FINISH = 2'b10
   } cmd_state;

   always_ff @(posedge uif.clk or posedge ulif.reset)
     if (ulif.reset) begin
        cmd_state <= IDLE;
        uif.stp   <= 0;
        out_cmd   <= NOOP;
     end else begin
        uif.stp <= 0;
        case (cmd_state)
          IDLE: begin
             out_cmd <= NOOP;
             if (!ulif.cmd_busy && ulif.cmd_strobe) begin
                out_cmd   <= ulif.cmd;
                cmd_state <= CMD;
             end
          end
          CMD:
            if (!ulif.cmd_busy && ulif.cmd_strobe) begin
               out_cmd   <= ulif.cmd;
               cmd_state <= CMD;
            end else if (!ulif.cmd_strobe) begin
               if (uif.nxt) begin
                  cmd_state <= IDLE;
                  uif.stp   <= 1;
                  out_cmd   <= 8'h00; // success
               end else
                 cmd_state <= FINISH;
            end
          FINISH:
            if (uif.nxt) begin
               cmd_state <= IDLE;
               uif.stp   <= 1;
               out_cmd   <= 8'h00; // success
            end
        endcase
     end

   always_comb begin
      ulif.cmd_busy <= 0;
      if (uif.dir || is_bus_turnaround)
        ulif.cmd_busy <= 1;
      if (cmd_state == CMD && !uif.nxt)
        ulif.cmd_busy <= 1;
      if (cmd_state == FINISH)
        ulif.cmd_busy <= 1;
   end


   assign uif.data = (uif.dir || is_bus_turnaround) ? 8'hzz : out_cmd;


endmodule // uif
