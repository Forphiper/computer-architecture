# Computer Architecture

* hw1 and hw3 are handwritten, so not included in this repo
* hw2: Implement ALU, FPU, Simple CPU
* hw4: Implement Pipelined CPU

About hw4 pipeline desgin:
* Pipeline are divided into 5 stages, i.e. IF, ID, EX, MEM, WB, implemented according to the following figure
* Because of latency of data memory and instruction memory, we set 4 cycles for each stage to run
* Use forwarding unit to solve general data hazard, and we need to stall the pipeline if encountering load-use data hazard
* Branch instruction are checked in ID stage to deal with control hazard
