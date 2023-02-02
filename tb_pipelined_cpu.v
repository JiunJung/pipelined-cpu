`timescale 0.1ns / 1ps

module tb_pipelined_cpu;

//parameter
parameter DATA_WIDTH = 16;
parameter ADDR_WIDTH = 16;
//reg
reg clk;
reg reset_n;
//wire
wire [DATA_WIDTH-1:0] data_in;  //sram1 -> cpu
wire [DATA_WIDTH-1:0] data_out; //cpu -> sram1
wire [ADDR_WIDTH-1:0] addr_0;   //cpu -> sram0
wire [ADDR_WIDTH-1:0] addr_1;   //cpu -> sram1
wire we_n;                      //cpu -> sram1
wire [DATA_WIDTH-1:0] inst_in;  //sram0 -> cpu

integer fp;

// check if the io correctly connected.

pipelined_cpu cpu0(
    .clk(clk),
    .reset_n(reset_n),
    .inst_in(inst_in),
    .data_in(data_in),
    .addr_0(addr_0),
    .addr_1(addr_1),
    .data_out(data_out),
    .we_n(we_n)
);

async_sram sram0( //instruction sram
    .addr(addr_0),
    .data_out(inst_in)
);

async_sram sram1( //data sram
    .we_n(we_n),
    .data_in(data_out),
    .addr(addr_1),
    .data_out(data_in)
);

always #5 clk = ~clk;

initial begin
    clk = 1'b0; reset_n = 1'b1; 
    #2
    reset_n = 1'b0;
    #5
    reset_n = 1'b1;
    //use readmem and fdisplay for file operations
    $readmemb("score.txt", tb_cpu.sram1.mem, 100);
    $readmemb("integer.txt", tb_cpu.sram1.mem, 200);
    $readmemb("code.txt", tb_cpu.sram0.mem);
    fp = $fopen("result.txt", "w");
    #3000
    $fdisplay(fp, "mem[%03d] : %03d", 300, tb_cpu.sram0.mem[300]);
    $fclose(fp);
    #10
    $finish;

end

endmodule