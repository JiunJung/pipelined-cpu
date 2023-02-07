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

- Data Hazard

- Branch Hazard

---------------------------
