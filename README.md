# Retro-V v1.1
Retro-V is a SoftCPU in Verilog created by Shaos (completely from scratch)
that implements RISC-V architecture RV32I (32-bit integer), but with 8-bit databus
to resemble a retro 8-bit microprocessors suitable for building DIY computers
around it ( like "nedoPC-5" for example: https://gitlab.com/nedopc/npc5 ).
Retro-V is capable of passing RV32I compliance tests (now 98%), compatible with RTOS Zephyr (not yet there)
and distributed as fully open sourced Verilog single file soft core under Apache License:

    // Copyright 2018 Alexander Shabarshin <ashabarshin@gmail.com>
    //
    // Licensed under the Apache License, Version 2.0 (the "License");
    // you may not use this file except in compliance with the License.
    // You may obtain a copy of the License at
    //
    //    http://www.apache.org/licenses/LICENSE-2.0
    //
    // Unless required by applicable law or agreed to in writing, software
    // distributed under the License is distributed on an "AS IS" BASIS,
    // WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    // See the License for the specific language governing permissions and
    // limitations under the License.

**THIS IS STILL WORK IN PROGRESS!!! NOT YET READY FOR 100% COMPLIANCE OR ZEPHYR!**

Retro-V soft core has 2-stage pipeline ( or more precisely 1.5-stage pipeline ; ) with 4 cycles per stage, so on average every instruction
takes 4 cycles (with 40 MHz clock it will be 10 millions instructions per sec max):

* **Cycle 1** - Fetch 1st byte of the instruction (lowest one)
* **Cycle 2** - Fetch 2nd byte of the instruction, determine destination register (rd) and check if instruction is valid
* **Cycle 3** - Fetch 3rd byte of the instruction, read 1st argument from register file (if needed)
* **Cycle 4** - Fetch 4th byte of the instruction (highest one), read 2nd argument from register file (if needed), decode immediate value (if needed)
* **Cycle 5** (overlapped with *Cycle 1* of the next instruction) - Execute complete instruction (with optional write back in case of branching)
* **Cycle 6** (overlapped with *Cycle 2* of the next instruction) - Write back to register file if destination register is not 0

As you can see Retro-V core reads from register file in cycles 3 and 4 and write to register file in cycles 1 and 2 (the same as 5 and 6 for 2nd stage of pipeline).
The fact that reading and writing are always performed in different moments in time allows us to implement register file by block memory inside FPGA.
Also it is obvious that this design doesn't have hazard problem if the same register is written in one instruction and we have read
in the next because instruction reads 1st argument in cycle 3 and write back from previous instruction is already happened in previous cycle.
In case of jump (**JAL/JALR** or **BRANCH** instructions and also **EBREAK** and **ECALL** in v1.1) next instruction from pipeline alread performed
1st cycle, so it stops right there and next cycle is 1st one from new address effectively re-initing the pipeline (so branch penalty is only 1 cycle).
In case of memory access (**LOAD** or **STORE** instructions) state machine stays in cycle 4 for a while (to load or store bytes from/to memory one by one wasting
from 1 to 5 extra cycles) and next instruction in pipeline is kind of frozen between cycle 1 and cycle 2 in the same time.

If we count only "visible" cycles (from the beginning of one instructions to the beginning of the next one) then:

* **JAL/JALR** take 5 cycles always (because of jump)
* **BEQ/BNE/BLT/BGE/BLTU/BGEU** take 4 cycles if condition is false (no jump) or 5 cycles if true
* **LB/LBU** take 5 cycles (because of 1 extra cycle to read 1 byte from memory)
* **LH/LHU** take 6 cycles (because of 2 extra cycles to read 2 bytes from memory)
* **LW** takes 8 cycles (because of 4 extra cycles to read 4 bytes from memory)
* **SB** takes 6 cycles (because of 1 extra cycle to write 1 byte to memory and 1 preparational cycle)
* **SH** takes 7 cycles (because of 2 extra cycles to write 2 bytes to memory and 1 preparational cycle)
* **SW** takes 9 cycles (because of 4 extra cycles to write 4 bytes to memory and 1 preparational cycle)
* **ECALL** and **EBRAKE** (added in Retro-V v1.1) also take 5 cycles
* Everything else takes 4 cycles (plus 2 hidden cycles on the 2nd stage of pipeline)

Read/Write of a word from some predefined memory addresses as MTIME or MTIMECMP also takes 4 cycles.

## RV32I compliance tests (run through Verilator)

Tests available here: https://github.com/riscv/riscv-compliance/

Current compliance tests status for Retro-V soft core is 54/55=98%:

    Check         I-ADD-01 ... OK
    Check        I-ADDI-01 ... OK
    Check         I-AND-01 ... OK
    Check        I-ANDI-01 ... OK
    Check       I-AUIPC-01 ... OK
    Check         I-BEQ-01 ... OK
    Check         I-BGE-01 ... OK
    Check        I-BGEU-01 ... OK
    Check         I-BLT-01 ... OK
    Check        I-BLTU-01 ... OK
    Check         I-BNE-01 ... OK
    Check       I-CSRRC-01 ... OK
    Check      I-CSRRCI-01 ... OK
    Check       I-CSRRS-01 ... OK
    Check      I-CSRRSI-01 ... OK
    Check       I-CSRRW-01 ... OK
    Check      I-CSRRWI-01 ... OK
    Check I-DELAY_SLOTS-01 ... OK
    Check      I-EBREAK-01 ... OK
    Check       I-ECALL-01 ... OK
    Check   I-ENDIANESS-01 ... OK
    Check     I-FENCE.I-01 ... OK
    Check             I-IO ... OK
    Check         I-JAL-01 ... OK
    Check        I-JALR-01 ... OK
    Check          I-LB-01 ... OK
    Check         I-LBU-01 ... OK
    Check          I-LH-01 ... OK
    Check         I-LHU-01 ... OK
    Check         I-LUI-01 ... OK
    Check          I-LW-01 ... OK
    Check I-MISALIGN_JMP-01 ... FAIL
    Check I-MISALIGN_LDST-01 ... OK
    Check         I-NOP-01 ... OK
    Check          I-OR-01 ... OK
    Check         I-ORI-01 ... OK
    Check     I-RF_size-01 ... OK
    Check    I-RF_width-01 ... OK
    Check       I-RF_x0-01 ... OK
    Check          I-SB-01 ... OK
    Check          I-SH-01 ... OK
    Check         I-SLL-01 ... OK
    Check        I-SLLI-01 ... OK
    Check         I-SLT-01 ... OK
    Check        I-SLTI-01 ... OK
    Check       I-SLTIU-01 ... OK
    Check        I-SLTU-01 ... OK
    Check         I-SRA-01 ... OK
    Check        I-SRAI-01 ... OK
    Check         I-SRL-01 ... OK
    Check        I-SRLI-01 ... OK
    Check         I-SUB-01 ... OK
    Check          I-SW-01 ... OK
    Check         I-XOR-01 ... OK
    Check        I-XORI-01 ... OK
    --------------------------------
    FAIL: 1/55

## Dhrystone results (also through Verilator

On my machine Verilator is capable of running this core with about 2 MHz clock, so I set HZ to be 500,000 (4 times less):

    Dhrystone Benchmark, Version C, Version 2.2
    Program compiled without 'register' attribute
    Using rdcycle(), HZ=500000

    Trying 500 runs through Dhrystone:
    Final values of the variables used in the benchmark:

    Int_Glob:            5
            should be:   5
    Bool_Glob:           1
            should be:   1
    Ch_1_Glob:           A
            should be:   A
    Ch_2_Glob:           B
            should be:   B
    Arr_1_Glob[8]:       7
            should be:   7
    Arr_2_Glob[8][7]:    510
            should be:   Number_Of_Runs + 10
    Ptr_Glob->
      Ptr_Comp:          -2147452480
            should be:   (implementation-dependent)
      Discr:             0
            should be:   0
      Enum_Comp:         2
            should be:   2
      Int_Comp:          17
            should be:   17
      Str_Comp:          DHRYSTONE PROGRAM, SOME STRING
            should be:   DHRYSTONE PROGRAM, SOME STRING
    Next_Ptr_Glob->
      Ptr_Comp:          -2147452480
            should be:   (implementation-dependent), same as above
      Discr:             0
            should be:   0
      Enum_Comp:         1
            should be:   1
      Int_Comp:          18
            should be:   18
      Str_Comp:          DHRYSTONE PROGRAM, SOME STRING
            should be:   DHRYSTONE PROGRAM, SOME STRING
    Int_1_Loc:           5
            should be:   5
    Int_2_Loc:           13
            should be:   13
    Int_3_Loc:           7
            should be:   7
    Enum_Loc:            1
            should be:   1
    Str_1_Loc:           DHRYSTONE PROGRAM, 1'ST STRING
            should be:   DHRYSTONE PROGRAM, 1'ST STRING
    Str_2_Loc:           DHRYSTONE PROGRAM, 2'ND STRING
            should be:   DHRYSTONE PROGRAM, 2'ND STRING

    Microseconds for one run through Dhrystone: 902
    Dhrystones per Second:                      1108
    mcycle = 225523

That is 1108 / 1757 = 0.63 DMIPS or for 2 MHz it's 0.315 DMIPS/MHZ (5.5 times less than official RISC-V rocket core results).

## FPGA implementation

Current Design Statistics from iCEcube2 for iCE40UP5K FPGA:

    Final Design Statistics

    Number of LUTs      	:	3366
    Number of DFFs      	:	662
    Number of DFFs packed to IO	:	0
    Number of Carrys    	:	337
    Number of RAMs      	:	4
    Number of ROMs      	:	0
    Number of IOs       	:	35
    Number of GBIOs     	:	1
    Number of GBs       	:	6
    Number of WarmBoot  	:	0
    Number of PLLs      	:	0
    Number of I2Cs      	:	0
    Number of SPIs      	:	0
    Number of DSPs     	:	0
    Number of SBIOODs     	:	0
    Number of LEDDAIPs     	:	0
    Number of RGBADRVs     	:	0
    Number of LFOSCs     	:	0
    Number of HFOSCs     	:	0
    Number of FILTER_50NSs     	:	0
    Number of SPRAMs     	:	0

    Device Utilization Summary

    LogicCells                  :	3447/5280
    PLBs                        :	484/660
    BRAMs                       :	4/30
    IOs and GBIOs               :	36/36
    PLLs                        :	0/1
    I2Cs                        :	0/2
    SPIs                        :	0/2
    DSPs                        :	0/8
    SBIOODs                     :	0/3
    RGBADRVs                    :	0/1
    LEDDAIPs                    :	0/1
    LFOSCs                      :	0/1
    HFOSCs                      :	0/1
    SPRAMs                      :	0/4
    FILTER50NSs                 :	0/2

    #####################################################################
    Placement Timing Summary
    The timing summary is based on estimated routing delays after
    placement. For final timing report, please carry out the timing
    analysis after routing.
    =====================================================================
    #####################################################################
                         Clock Summary 
    =====================================================================
    Number of clocks: 1
    Clock: retro|clk | Frequency: 24.38 MHz | Target: 34.84 MHz
    =====================================================================
                         End of Clock Summary
    #####################################################################
