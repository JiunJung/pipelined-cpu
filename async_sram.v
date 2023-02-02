//async sram
`timescale 0.1ns / 1ps

module async_sram
#(
parameter ADDR_WIDTH = 16,
parameter DATA_WIDTH = 16,
parameter DATA_DEPTH = 4096 //2^12
)
(
input we_n,
input [DATA_WIDTH-1:0] data_in,
input [ADDR_WIDTH-1:0] addr,
output [DATA_WIDTH-1:0] data_out
    );
    
reg [15:0] mem [0:DATA_DEPTH-1];
reg [15:0] r_data_out;

always @(addr)begin //read (you just need to send addr to sram to read data.)
    r_data_out <= mem[addr];
end

always @(we_n or data_in or addr)begin //write
    if(!we_n)begin
        mem[addr] <= data_in;
    end
end

assign data_out = r_data_out;

endmodule