`timescale 0.1ns/1ps

module pipelined_cpu 
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
  //output [DATA_WIDTH-1:0] inst_out, //must be connnected to sram0(instruction ram)
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

reg [2:0] S1; //counter register to solve branch hazard.
reg [2:0] S2;
reg S3;
reg S4;
reg S5;

reg [15:0] R1; //stores the data for STA
reg [15:0] R2;
reg [15:0] R3;

reg [15:0] B1; //B for Bypassing
 
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
  r_we_n <= 1'b1; //default : read

  OP0 <= 0; 
  OP1 <= 0; 
  OP2 <= 0; 

  //stage on/off control register.
  S1 <= 3'b000; //default : on
  S2 <= 3'b001; //default : off
  S3 <= 1'b0; //default : off
  S4 <= 1'b0; //default : off
  S5 <= 1'b0; //default : off

  R1 <= 0;
  R2 <= 0;
  R3 <= 0;

  B1 <= 0;
end

//I will use the sram which gives data whether it is Read mode or not.
always @(posedge clk)begin //1st stage (fetch instruction)
  if(S1 == 3'b000)begin
    AR_0 <= PC; //error?
    #2 //put buffer for waiting instruction fetch.
    IR <= inst_in;
    PC <= PC + 1;
  end
  else if(S1 == 3'b010)begin
    PC <= PC - 1; // No data coherene with 4th stage.
    S1 <= S1 - 1;
  end else begin
    S1 <= S1 - 1;
  end
end

always @(posedge clk)begin //2nd stage (instruction decode)
  if(S2 == 3'b000)begin
    if(IR[14:12] == 3'b100 or IR[14:12] == 3'b101 or IR[14:12] == 3'b110)begin
      S1 <= 3'b010;
      S2 <= 1'b0;
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
    S3 <= 1'b1; //3rd stage enable.
    //#3 AR_1 <= OP0; //put buffer(delay) for indirect addressing in fetch operand (3rd stage)
  end else begin
    S2 <= S2 - 1;
    S3 <= 1'b0; //3rd stage disable.
  end

end

//3rd stage cause hazard because of data_in (structure hazard)
//DR <= data_in (T4 part) must be changed. stall or multiple sram.

always @(posedge clk)begin  //3rd stage (fetch operand)
  if(S3 == 1'b1)begin
    if(D0[7] == 1'b0)begin //memory reference instructions
      if(I[0] == 1'b0)begin //direct addressing mode
        if(OP0 == OP1) begin //Bypassing
          #3 DR <= B1; OP1 <= OP0;
        end else begin
          #2 AR_1 <= OP0; //async sram will return data. After stage 5 complete.
          #1 // Is it okay? (if not ok -> #2)
          DR <= data_in;
          OP1 <= OP0;
        end      
      end else if(I[0] == 1'b1)begin //indirect addressing mode
        if(OP0 == OP1) begin //Bypassing
          #2 AR_1 <= B1; OP1 <= B1;
          #1 DR <= data_in;
        end else begin
          #2 AR_1 <= OP0;
          #1
          if(OP1 == data_in)begin //Bypassing
            DR <= B1;
            OP1 <= data_in;
          end else begin
            AR_1 <= data_in;
            OP1 <= data_in;
            #1 DR <= data_in;
          end
        end
      end
    end
    D1 <= D0; //D0 must be registerd for not causing structure hazard.
    S4 <= 1'b1;
  end else begin 
    S4 <= 1'b0;
  end
end

always @(posedge clk)begin //4th stage (execution instruction) 
  if(S4 == 1'b1)begin
    //must move DR data into DR2. NO. It catches before update.
    D2 <= D1;
    OP2 <= OP1; //Is it really neccessary? Yes. 5th stage needs address to store the data.
    if(D1[7] == 1'b0)begin //memory reference instructions //must solve branch hazard.
      case(D1)
        8'b00000001 : AC <= AC & DR;      //AND
        8'b00000010 : {E, AC} <= AC + DR; //ADD
        8'b00000100 : AC <= DR;           //LDA
        8'b00001000 : 
          R1 <= AC;                       //STA -> goes to 5th stage
          B1 <= AC;                       //for bypassing.
        8'b00010000 : PC <= OP1;          //BUN
        8'b00100000 :                     //BSA
          R2 <= PC;
          B1 <= PC;
          #1 PC <= OP1 +1;
        8'b01000000 :                     //ISZ -> solve using freeze approach
          DR2 <= DR + 1;
          if(DR2 == 0)begin
            PC <- PC + 1;
          end
          #1 R3 <= DR2; B1 <= DR2;
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
    S5 <= 1'b1;
  end else begin
    S5 <= 1'b0;
  end
end

always @(posedge clk)begin //5th stage (write operand) //can cause structure hazard with 3rd stage.
//make sure to deal with D2 and I[2] and OP2(register reference)
  if(S5 == 1'b1)begin
    r_we_n <= 1'b0;
    AR_1 <= OP2;
    if(D2 == 8'b00001000)begin
      r_data_out <= R1;
    end else if(D2 == 8'b00100000)begin
      r_data_out <= R2;
    end else if(D2 == 8'b01000000)begin
      r_data_out <= R3;
    end
  end
end

endmodule