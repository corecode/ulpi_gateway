`default_nettype none
`timescale 1 ns / 100 ps

module spi_slave
 (
  input wire         nCS,
  input wire         SCK,
  input wire         MOSI,
  output logic       MISO,

  input wire         clk,
  input wire         reset,
  output logic [7:0] mosi_data,
  input wire [7:0]   miso_data,
  output logic       next_byte_ready,
  output logic       new_transfer
);


   logic [7:0]        mosi_data_nxt;
   logic [7:0]        shiftreg, shiftreg_nxt, shiftreg_mosi;
   logic [2:0]        numbits, numbits_nxt;

   logic              is_last_bit;

   logic              next_byte_tgl, next_byte_tgl_nxt;
   logic [2:0]        next_byte_tgl_sync;

   logic [1:0]        new_transfer_flag;
   logic              new_transfer_tgl, new_transfer_tgl_nxt;
   logic [2:0]        new_transfer_tgl_sync;


initial next_byte_tgl = 0;
initial new_transfer_tgl = 0;

assign is_last_bit = (numbits == 7);

assign numbits_nxt = numbits + 1'd1;
assign shiftreg_mosi = {shiftreg[6:0],MOSI};
assign shiftreg_nxt = is_last_bit ? miso_data : shiftreg_mosi;
assign mosi_data_nxt = is_last_bit ? shiftreg_mosi : mosi_data;
assign next_byte_tgl_nxt = is_last_bit ? !next_byte_tgl : next_byte_tgl;

// detect rising edge
assign new_transfer_tgl_nxt = (!new_transfer_flag[1] && new_transfer_flag[0]) ^ new_transfer_tgl;

// XXX initialize shiftreg from status, etc. on first clock edge after nCS

always_ff @(posedge SCK or posedge nCS)
  if (nCS) begin
     shiftreg          <= 0;
     numbits           <= 0;
     new_transfer_flag <= 0;
  end else begin // if (~nCS)
     shiftreg          <= shiftreg_nxt;
     numbits           <= numbits_nxt;
     mosi_data         <= mosi_data_nxt;
     next_byte_tgl     <= next_byte_tgl_nxt;
     new_transfer_flag <= {new_transfer_flag[0],1'b1};
     new_transfer_tgl  <= new_transfer_tgl_nxt;
  end

always_ff @(negedge SCK or posedge nCS)
  if (nCS)
    MISO <= 0;
  else
    MISO <= shiftreg[7];


// synchronize next_byte_tgl and new_transfer_tgl to system clk

always_ff @(posedge clk or posedge reset)
  if (reset) begin
     next_byte_tgl_sync    <= 0;
     new_transfer_tgl_sync <= 0;
  end else begin
     next_byte_tgl_sync    <= {next_byte_tgl_sync[1:0],next_byte_tgl};
     new_transfer_tgl_sync <= {new_transfer_tgl_sync[1:0],new_transfer_tgl};
  end

assign next_byte_ready = next_byte_tgl_sync[2] ^ next_byte_tgl_sync[1];
assign new_transfer = new_transfer_tgl_sync[2] ^ new_transfer_tgl_sync[1];

endmodule
