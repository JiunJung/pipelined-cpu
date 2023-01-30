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
reg [15:0] AR_0, AR_1, DR, DR2, IR, PC, AC; //AR_0 is for instructions, AR_1 is for data.
reg E, r_we_n;
reg [2:0] I; //I stores MSB.
reg [7:0] D0; //stores decoder result.
reg [7:0] D1; 
reg [7:0] D2;
reg [15:0] r_data_out;

reg [15:0] OP0; //stores opcode(register reference) for a brief moment at 2nd stage.
reg [15:0] OP1; //stores opcode(register reference) at 3rd stage
reg [15:0] OP2; //stores opcode(register reference) at 4th stage.

 
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
  DR2 <= 16'd0;
  IR <= 16'd0;
  PC <= 16'd0;
  AC <= 16'd0;
  I <= 3'b000;
  E <= 1'b0;
  D0 <= 8'd0;
  D1 <= 8'd0;
  D2 <= 8'd0;
  r_we_n <= 1'b1; //defalt : read

  OP0 <= 0; 
  OP1 <= 0; 
  OP2 <= 0; 

end

//I will use the sram which gives data whether it is Read mode or not.
always @(posedge clk)begin //1st stage (fetch instruction)
  AR_0 <= PC; //error
  #2 //put buffer for waiting instruction fetch.
  IR <= inst_in;
  PC <= PC + 1;
end

always @(posedge clk)begin //2nd stage (instruction decode)
  if(IR[14:12] == 3'b100 or IR[14:12] == 3'b101 or IR[14:12] == 3'b110)begin
    //must generate control bit. but how freeze other steps exept next steps?
  end
  I <= {I[1:0],IR[15]};
  OP0 <= IR[11:0];
  case(IR[14:12]) //decoder
    3'b000 : D0 <= 8'b00000001; //note this! 000 returns D0[0] = 1 //AND
    3'b001 : D0 <= 8'b00000010; //ADD
    3'b010 : D0 <= 8'b00000100; //LDA
    3'b011 : D0 <= 8'b00001000; //STA
    3'b100 : D0 <= 8'b00010000; //BUN
    3'b101 : D0 <= 8'b00100000; //BSA
    3'b110 : D0 <= 8'b01000000; //ISZ
    3'b111 : D0 <= 8'b10000000; //register reference instruction
    default : D0 <= 8'b00000000;
  endcase
  #3 AR_1 <= OP0; //put buffer(delay) for indirect addressing in fetch operand (3rd stage)

end

//3rd stage cause hazard because of data_in (structure hazard)
//DR <= data_in (T4 part) must be changed. stall or multiple sram.

always @(posedge clk)begin  //3rd stage (fetch operand)
  D1 <= D0; //D0 must be registerd for not causing structure hazard.
  OP1 <= OP0;
  if(D0[7] == 1'b0)begin //memory reference instructions
    if(I[0] == 1'b0)begin //direct addressing mode
      DR <= data_in;
    end 
    else if(I[0] == 1'b1)begin //indirect addressing mode
      AR_1 <= data_in; 
      #1 DR <= data_in; //put buffer for waiting data fetch.
    end
  end
end

always @(posedge clk)begin //4rth stage (execution instruction) 
  //must move DR data into DR2. NO. It catches before update.
  D2 <= D1;
  OP2 <= OP1; //Is it really neccessary?
  if(D1[7] == 1'b0)begin //memory reference instructions //must solve branch hazard.
    case(D1)
      8'b00000001 : AC <= AC & DR;      //AND
      8'b00000010 : {E, AC} <= AC + DR; //ADD
      8'b00000100 : AC <= DR;           //LDA
      8'b00001000 :                     //STA
        r_we_n <= 1'b0;
        r_data_out <= AC;
      8'b00010000 : PC <= OP1;          //BUN
      8'b00100000 :                     //BSA
        r_we_n <= 1'b0;
        r_data_out <= PC;
        OP2 <= OP1 +1;
        #1 PC <= OP2;
      8'b01000000 :                     //ISZ -> solve using freeze approach
        DR2 <= DR + 1;
        r_we_n <= 1'b0;
        #1 r_data_out <= DR2;
        if(DR2 == 0)begin
          
        end
    endcase
  end
  else if(D1[7] == 1'b1)begin //register reference instructions
    if(I[1] == 1'b0)begin
      case(OP1)
        16'h800 : AC <= 16'd0;        //CLA
        16'h400 : E <= 1'b0;          //CLE
        16'h200 : AC <= ~AC;          //CMA
        16'h100 : E <= ~E;            //CME
        16'h080 : AC <= {E,AC[15:1]}; //CIR
        16'h040 : AC <= {AC[14:0],E}; //CIL
        16'h020 : AC <= AC + 1;       //INC
      endcase
    end
    else if(I[1] == 1'b1)begin
      //input-output instructions
    end
  end
end

always @(posedge clk)begin //5th stage (write operand) //can cause structure hazard with 3rd stage.
//make sure to deal with D2 and I[2] and OP2(register reference)

end

endmodule