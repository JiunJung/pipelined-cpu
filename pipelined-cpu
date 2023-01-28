`timescale 0.1ns/1ps

module piplined 
#
(
  parameter ADDR_WIDTH = 16,
  parameter DATA_WIDTH = 16
)
(
  input clk,
  input reset_n,
  input [DATA_WIDTH-1:0] inst_in, //stands for instruction_in from sram0.
  input [DATA_WIDTH-1:0] data_in, //data_in from sram1.
  output [ADDR_WIDTH-1:0] addr_0,
  output [ADDR_WIDTH-1:0] addr_1,
  output [DATA_WIDTH-1:0] inst_out, //must be connnected to sram0(instruction ram)
  output [DATA_WIDTH-1:0] data_out, //must be connected to sram1(data ram)
  output we_n
);

//define reg here
reg [15:0] AR_0, AR_1, DR, IR, PC, AC; //AR_0 is for instructions, AR_1 is for data.
reg I, E, r_we_n;
reg [7:0] D;
reg [3:0] SC;
reg [15:0] r_data_out;
//new reg
reg [15:0] R1;

 
//define reg end
//assign here
assign we_n = r_we_n;
assign addr_0 = AR_0;
assign addr_1 = AR_1; 
assign data_out = r_data_out;
//assign end
always @(negedge reset_n) begin
  //register initialize
  AR_0 <= 16'd0;
  AR_1 <= 16'd0;
  DR <= 16'd0;
  IR <= 16'd0;
  PC <= 16'd0;
  AC <= 16'd0;
  I <= 1'b0;
  E <= 1'b0;
  D <= 4'd0;
  SC <= 4'd0;
  r_we_n <= 1'b1; //defalt : read
  
  //new reg
  R1 <= 1'b0;

end

//I will use the sram which gives data whether it is Read mode or not.
always @(posedge clk)begin //1st stage (fetch instruction)
  AR_0 <= PC; //error
  #2
  IR <= inst_in;
  PC <= PC + 1;
end

always @(posedge clk)begin //2nd stage (instruction decode)
  I <= IR[15];
  AR_1 <= IR[11:0];  //can cause error
  case(IR[14:12]) //decoder
    3'b000 : D <= 8'b00000001;
    3'b001 : D <= 8'b00000010;
    3'b010 : D <= 8'b00000100;
    3'b011 : D <= 8'b00001000;
    3'b100 : D <= 8'b00010000;
    3'b101 : D <= 8'b00100000;
    3'b110 : D <= 8'b01000000;
    3'b111 : D <= 8'b10000000;
    default : D <= 8'b00000000;
  endcase
end

//3rd stage cause hazard because of data_in (structure hazard)
//DR <= data_in (T4 part) must be changed. stall or multiple sram.

always @(posedge clk)begin  //3rd stage (fetch operand)
  if(D[7] == 1'b0)begin //memory reference instructions
    if(I == 1'b0)begin //direct addressing mode
      SC <= SC + 1;
    end 
    else if(I == 1'b1)begin
      AR_1 <= data_in; //critical error!! 
      SC <= SC + 1;
    end
  end
  else if(D[7] == 1'b1)begin //register reference instructions
    if(I == 1'b0)begin
      case(R1)
        16'h800 : AC <= 16'd0;        //CLA
        16'h400 : E <= 1'b0;          //CLE
        16'h200 : AC <= ~AC;          //CMA
        16'h100 : E <= ~E;            //CME
        16'h080 : AC <= {E,AC[15:1]}; //CIR
        16'h040 : AC <= {AC[14:0],E}; //CIL
        16'h020 : AC <= AC + 1;       //INC
      endcase
      SC <= 0;
    end
    else if(I == 1'b1)begin
      //input-output instructions
    end
  end
end

endmodule
