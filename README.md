# pipelined mano machine

- application of 5 stage pipeline to mano-machine cpu.
  

- This pipelined mano-machine has been improved it's processing speed 51.67% faster than single cycle mano-machine 

- Single cylcle mano-machine and pipelined mano-machine were tested using same code and data. : Sum of grades (scroe.txt)

![single cycle mano machine](/image/tb_cpu.jpg)
[Single cycle mano-machine : Ends at 284.5ns]

![pipelined mano machine](/image/pipelined-cpu.jpg)
[Pipelined mano-machine : Ends at 137.5ns]

-----
## Secret of pipelined mano machine.

5 stage pipelined cpu is supposed to be approximately 5 times faster. But there's a few problems called "hazrard" when you make pipeline. Sometimes, we need to stall some stages to solve the hazards. That's why this pipelined mano machine is not 5 times faster than single cycle mano machine. But, the point is, It is really improved!

-----------------

## Pipeline Hazards

What kind of hazards did I faced, and how did I solve the hazards?

- Structure Hazard

    There's a problem when multiple stages try to access memory simultaneously. In our case, 1st stage (Fetch instruction), 3rd stage (Fetch operand) and 5th stage (Write operand) cause structure hazard. <br/>
    
    To prevent structure hazard, there are two methods. First, we can stall the pipeline. For example, when 3rd stage is working, we should stop 1st stage and 5th stage. 
    <br/>

    Secondly, we can use Havard Architecture. It means to use 2 kinds of memory. One for only instructions and another for data. <br/>

    However, stalling the pipeline causes througput decrease. So I used Havard Architecture. I used two kinds of memory. Sram0 for store instructions, and Sram1 for store data. <br/>

    It was good decision because I had to use stalling method later(to solve branch hazard). If I chose to stall pipeline, this CPU might be slower than now. 

- Data Hazard

    

- Branch Hazard

---------------------------
