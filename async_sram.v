//async sram
`timescale 0.1ns / 1ps

module async_sram
#(
parameter ADDR_WIDTH = 16,
parameter DATA_WIDTH = 16,
parameter DATA_DEPTH = 4096 //2^12
)
(
input clk,
input we_n,
input [DATA_WIDTH-1:0] data_in,
input [ADDR_WIDTH-1:0] addr,
output [DATA_WIDTH-1:0] data_out
    );
    
reg [15:0] mem [0:DATA_DEPTH-1];
reg [15:0] r_data_out;

always @(posedge clk)begin
if(!we_n)begin //write
mem[addr] <= data_in;
end
end

always @(posedge clk)begin
#1 r_data_out <= mem[addr];
end

assign data_out = r_data_out;

endmodule