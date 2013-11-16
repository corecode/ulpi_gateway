`timescale 1 ns / 100 ps

module ulpi_link (
  // ULPI physical
  ulpi_if.link uif,

  // system
  ulpi_link_if.link ulif
);

   typedef enum logic [1:0] {
      NOOP = 2'b00,
      REGW = 2'b10,
      REGR = 2'b11
   } UlpiCmd;

   logic ulpi_dir_r;
   logic is_bus_turnaround;
   logic is_valid_data;
   logic is_bus_ours;

   assign is_bus_turnaround = uif.dir != ulpi_dir_r;
   assign is_bus_ours       = !uif.dir && !is_bus_turnaround;
   assign is_valid_data     = ulpi_dir_r && !is_bus_turnaround;

   always_ff @(posedge uif.clk or posedge ulif.reset) begin
      if (ulif.reset) begin
         ulif.data_valid    <= 0;
         ulif.data          <= 0;
         ulif.rx_cmd        <= 0;
         ulif.reg_data_read <= 0;
         ulpi_dir_r         <= 0;
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
      end
   end


   enum logic [2:0] {
      IDLE,
      WRITE_ADDR,
      WRITE_DATA,
      READ_ADDR,
      READ_DATA,
      FINISH
   } state, next_state;
   logic [7:0] out_data;

   always_ff @(posedge uif.clk or posedge ulif.reset)
     if (ulif.reset)
       state <= IDLE;
     else
       state <= next_state;

   always_comb
     unique case (state)
       IDLE:
         out_data <= {NOOP,6'b0};
       READ_ADDR:
         out_data <= {REGR,ulif.reg_addr};
       READ_DATA:
         out_data <= 8'hzz;
       WRITE_ADDR:
         out_data <= {REGW,ulif.reg_addr};
       WRITE_DATA:
         out_data <= ulif.reg_data_write;
       FINISH:
         out_data <= 8'h00;
     endcase

   assign uif.stp  = state == FINISH;
   assign ulif.reg_done = state == FINISH;

   always_comb begin
      next_state <= state;
      unique case (state)
        IDLE:
          if (ulif.reg_enable)
            next_state <= ulif.reg_read_nwrite ? READ_ADDR : WRITE_ADDR;
        READ_ADDR:
          if (is_bus_ours && uif.nxt)
            next_state <= READ_DATA;
        READ_DATA:
          if (is_valid_data)
            next_state <= FINISH;
        WRITE_ADDR:
          if (is_bus_ours && uif.nxt)
            next_state <= WRITE_DATA;
        WRITE_DATA:
          if (is_bus_ours) begin
            if (uif.nxt)
              next_state <= FINISH;
          end else
            next_state <= WRITE_ADDR;
        FINISH:
          next_state <= IDLE;
      endcase
   end

   assign uif.data          = is_bus_ours ? out_data : 8'hzz;

endmodule
