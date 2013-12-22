`default_nettype none
`timescale 1 ns / 100 ps

interface ulpi_link_if(input wire clk);
   logic       reset;
   logic [7:0] data;
   logic       data_valid;
   logic [7:0] rx_cmd;

   logic [5:0] reg_addr;
   logic [7:0] reg_data_read;
   logic [7:0] reg_data_write;
   logic       reg_enable;
   logic       reg_read_nwrite;
   logic       reg_done;

   modport link(input clk,
                input  reset,
                output data,
                output data_valid,
                output rx_cmd,
                input  reg_addr,
                output reg_data_read,
                input  reg_data_write,
                input  reg_enable,
                input  reg_read_nwrite,
                output reg_done);

`ifndef synthesis
   clocking cb @(posedge clk);
      input    data;
      input    data_valid;
      input    rx_cmd;
      output   reg_addr;
      input    reg_data_read;
      output   reg_data_write;
      output   reg_enable;
      output   reg_read_nwrite;
      input    reg_done;

      default input #1step output #4;
   endclocking // phy_cb

   modport tb(clocking cb, input clk, output reset);
`endif

endinterface
