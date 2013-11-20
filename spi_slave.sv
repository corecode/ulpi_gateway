module spi_slave (
   input logic        nCS,
   input logic        SCK,
   input logic        MOSI,
   output logic       MISO,

   input logic        clk,
   input logic        reset,
   output logic [7:0] mosi_data,
   input logic [7:0]  miso_data,
   output logic       data_next
);

   logic [7:0]        shiftreg;
   logic [2:0]        numbits;

// s_ denotes SCK clock domain
// i_ denotes internal clock domain
   logic              s_data_next;
   logic [1:0]        i_data_next;

assign MISO = shiftreg[7];

always_ff @(posedge SCK or posedge nCS)
  if (nCS) begin
     shiftreg  <= 0;
     s_data_next <= 0;
     numbits   <= 0;
  end else begin // if (~nCS)
     s_data_next <= 0;

     if (numbits == 7) begin
        s_data_next <= 1;
        mosi_data <= shiftreg;
        shiftreg  <= miso_data;
     end

     shiftreg <= {shiftreg[6:0],MOSI};
     numbits  <= numbits + 1;
  end

always_ff @(posedge clk or posedge reset)
  if (reset)
    i_data_next <= 0;
  else
    i_data_next <= {i_data_next[0],s_data_next};

assign data_next = i_data_next[1];

endmodule
