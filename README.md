# Retro-V v1.0
Retro-V is a SoftCPU in Verilog created by Shaos (completely from scratch)
implementing RISC-V architecture RV32I (32-bit integer), but with 8-bit databus
to resemble a retro 8-bit microprocessor suitable for DIY computers
( like "nedoPC-5" for example: https://gitlab.com/nedopc/npc5 ).
Retro-V is capable of passing RV32I compliance tests (now 67%), compatible with RTOS Zephyr (not yet there)
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

THIS IS STILL WORK IN PROGRESS!!! NOT YET READY FOR 100% COMPLIANCE OR ZEPHYR!

This design has 2-stage pipeline with 4 cycles per stage, so on average every instruction
takes 4 cycles (with 40 MHz clock it will be 10 millions instructions per sec max).
Branches and Jump-and-Links takes 1 cycle more (5 cycles total).
Loads: LB - 5 cycles, LH - 6 cycles, LW - 8 cycles.
Stores: SB - 6 cycles, SH - 7 cycles, SW - 9 cycles (1 more than loads).

Current compliance tests status (37/55=67%):

    Check         I-ADD-01 ... OK
    Check        I-ADDI-01 ... OK
    Check         I-AND-01 ... OK
    Check        I-ANDI-01 ... OK
    Check       I-AUIPC-01 ... OK
    Check         I-BEQ-01   FAIL
    Check         I-BGE-01   FAIL
    Check        I-BGEU-01   FAIL
    Check         I-BLT-01   FAIL
    Check        I-BLTU-01   FAIL
    Check         I-BNE-01   FAIL
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
    Check         I-JAL-01   FAIL
    Check        I-JALR-01   FAIL
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
    FAIL: 18/55

Current Design Statistics from iCEcube2:

    Number of LUTs      	:	2124
    Number of DFFs      	:	321
    Number of DFFs packed to IO	:	0
    Number of Carrys    	:	268
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
    Number of FILTER_50NSs     	:	0
    Number of SPRAMs     	:	0

    Device Utilization Summary

    LogicCells                  :	2196/5280
    PLBs                        :	331/660
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

Performance Summary:

    Worst slack in design: -3.659
                       Requested     Estimated     Requested     Estimated                Clock        Clock                
    Starting Clock     Frequency     Frequency     Period        Period        Slack      Type         Group                
    ------------------------------------------------------------------------------------------------------------------------
    retro|clk          48.2 MHz      39.7 MHz      20.734        25.180        -3.659     inferred     Autoconstr_clkgroup_0
    ========================================================================================================================
