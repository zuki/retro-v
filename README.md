# Retro-V v1.0
Retro-V is a SoftCPU in Verilog created by Shaos (completely from scratch)
that implements RISC-V architecture RV32I (32-bit integer), but with 8-bit databus
to resemble a retro 8-bit microprocessors suitable for building DIY computers
around it ( like "nedoPC-5" for example: https://gitlab.com/nedopc/npc5 ).
Retro-V is capable of passing RV32I compliance tests (now 82%), compatible with RTOS Zephyr (not yet there)
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

Retro-V soft core has 2-stage pipeline with 4 cycles per stage, so on average every instruction
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
In case of branching (BRANCH or JAL/JAR) next instruction from pipeline alread performed 1st cycle,
so it stops right there and next cycle is 1st one from new address effectively re-initing the pipeline (so branch penalty is only 1 cycle).
In case of memory access (LOAD or STORE) state machine stays in cycle 4 for a while (to load or store bytes from/to memory one by one wasting
from 1 to 5 extra cycles) and next instruction in pipeline is kind of frozen between cycle 1 and cycle 2 in the same time.

If we count only "visible" cycles (from the beginning of one instructions to the beginning of the next one) then:

* **JAL/JALR** take 5 cycles always (because of branching)
* **BEQ/BNE/BLT/BGE/BLTU/BGEU** take 4 cycles if condition is false (no branching) or 5 cycles if true
* **LB/LBU** take 5 cycles (because of 1 extra cycle to read 1 byte from memory)
* **LH/LHU** take 6 cycles (because of 2 extra cycles to read 2 bytes from memory)
* **LW** takes 8 cycles (because of 4 extra cycles to read 4 bytes from memory)
* **SB** takes 6 cycles (because of 1 extra cycle to write 1 byte to memory and 1 preparational cycle)
* **SH** takes 7 cycles (because of 2 extra cycles to read 2 bytes from memory and 1 preparational cycle)
* **SW** takes 9 cycles (because of 4 extra cycles to read 4 bytes from memory and 1 preparational cycle)
* Everything else takes 4 cycles (plus 2 hidden cycles on the 2nd stage of pipeline)

## RV32I ompliance tests

Tests available here: https://github.com/riscv/riscv-compliance/

Current compliance tests status for Retro-V soft core is 45/55=81.8%:

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
    Check       I-CSRRC-01   FAIL
    Check      I-CSRRCI-01   FAIL
    Check       I-CSRRS-01   FAIL
    Check      I-CSRRSI-01   FAIL
    Check       I-CSRRW-01   FAIL
    Check      I-CSRRWI-01   FAIL
    Check I-DELAY_SLOTS-01 ... OK
    Check      I-EBREAK-01   FAIL
    Check       I-ECALL-01   FAIL
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
    Check I-MISALIGN_JMP-01  FAIL
    Check I-MISALIGN_LDST-01 FAIL
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
    FAIL: 10/55

## FPGA implementation

Current Design Statistics from iCEcube2 for iCE40UP5K FPGA:

    Number of LUTs      	:	2187
    Number of DFFs      	:	324
    Number of DFFs packed to IO :	0
    Number of Carrys    	:	275
    Number of RAMs      	:	4
    Number of ROMs      	:	0
    Number of IOs       	:	35
    Number of GBIOs     	:	1
    Number of GBs       	:	4
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
    Number of FILTER_50NSs	:	0
    Number of SPRAMs     	:	0

    Device Utilization Summary

    LogicCells                  :	2265/5280
    PLBs                        :	344/660
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

Performance Summary (as estimated by iCEcube2):

    Worst slack in design: -6.371
                       Requested     Estimated     Requested     Estimated                Clock        Clock                
    Starting Clock     Frequency     Frequency     Period        Period        Slack      Type         Group                
    ------------------------------------------------------------------------------------------------------------------------
    retro|clk          48.4 MHz      29.9 MHz      20.681        33.423        -6.371     inferred     Autoconstr_clkgroup_0
    ========================================================================================================================
