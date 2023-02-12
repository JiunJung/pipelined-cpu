# pipelined mano machine

- application of 5 stage pipeline to mano-machine cpu.
  

- This pipelined mano-machine has been improved it's processing speed 51.67% faster than original mano-machine 

- Original mano-machine and pipelined mano-machine were tested using same code and data. : Sum of grades (scroe.txt)

![Original mano machine](/image/tb_cpu.jpg)
[Original mano-machine : Ends at 284.5ns]

![pipelined mano machine](/image/pipelined-cpu.jpg)
[Pipelined mano-machine : Ends at 137.5ns]

-----
## Secret of pipelined mano machine.

5 stage pipelined cpu is supposed to be approximately 5 times faster. But there's a few problems called "hazrard" when you make pipeline. Sometimes, we need to stall some stages to solve the hazards. That's why this pipelined mano machine is not 5 times faster than original mano machine. But, the point is, It is really improved!

-----------------

## Pipeline Hazards

What kind of hazards did I faced, and how did I solve the hazards?

- Structural Hazard

    There's a problem when multiple stages try to access memory simultaneously. In our case, 1st stage (Fetch instruction), 3rd stage (Fetch operand) and 5th stage (Write operand) cause structure hazard. <br/>
    
    To prevent structure hazard, there are two methods. First, we can stall the pipeline. For example, when 3rd stage is working, we should stop 1st stage and 5th stage. 
    <br/>

    Secondly, we can use Havard Architecture. It means to use 2 kinds of memory. One for only instructions and another for data. <br/>

    However, stalling the pipeline causes througput decrease. So I used Havard Architecture. I used two kinds of memory. Sram0 for store instructions, and Sram1 for store data. <br/>

    It was good decision because I had to use stalling method later(to solve branch hazard). If I chose to stall pipeline, this CPU might be slower than now. <br/>

    But, there's one problem still remaining which is conflict of 3rd stage and 5th stage. Both stage use data memory. In this case, I put delay to 3rd stage. So, when both of them work, 5th stage starts to work a little bit faster than 3rd stage. And It prevents structure hazard. Furthermore, It can prevent data hazard when the instruction 2 times before is at 5th stage(write operand) and the data should be used at the 3rd stage simultaneously. <br/>

- Data Hazard

    Data hazard occurs when an instruction depends on the result of a previous instruction. For example, at 3rd stage, cpu fetches the data. But, the data could not be completely updated because, at 5th stage, the data could be still in progress. <br/>

    To prevent this, we can use two methods. First one is stallind and second one is "bypassig". I have mentioned that stalling can decrease throughput. So, if other method exists, that way might be better. <br/>

    So, what is bypassig? Is it really better than stalling? The answer is yes. Bypassing doens't need to stall pipeline. Bypassing means when the instruction needs same address with an instruction right before, it gets the data directly from previous instruction, right after when the calculation is finished. <br/>

    So, at 4th stage, it stores data at an register for a while in advance. <br/>

    Data hazard can occurs even when an instruction 2 times before conflicts with current instruction. But, we already solved this problem when we solve structure hazard. <br/>

- Branch Hazard

    Some instructions need to change the data in PC. And it can cause problem with 1st stage (instruction fetch). there are several ways to prevent our CPU from branch hazard. Freeze scheme, predict-untaken scheme, predict-taken scheme, delayed branch is that. Freeze scheme is simply just stop the progress until the branch is chosen. predict-untaken is that while freeze scheme is in progress, CPU just predict the branch to be untaken. And, if the predict was wrong, delete all the process which is wrong, and redo the process. Predict-taken scheme is just opposite to it. Delayed branch is doing other instructions which is not assosiated with the branch instruction. It is done in compiler time. <br/>

    I just simply used freeze approach. I used if-else and on/off token in verilog. You can check through pipelined-cpu.v in this repo.


---------------------------
