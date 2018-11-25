# Retro-V v1.0
Retro-V is a SoftCPU in Verilog created from scratch by Shaos implementing RISC-V
architecture RV32I (32-bit integer), but with 8-bit databus to resemble
a retro 8-bit microprocessor suitable for DIY computers
( like "nedoPC-5" for example: https://gitlab.com/nedopc/npc5 ).
Retro-V is capable of passing RV32I compliance tests, compatible with RTOS Zephyr and
distributed as fully open sourced Verilog single file soft core under Apache License:

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

THIS IS STILL WORK IN PROGRESS!!! NOT YET READY FOR TESTS OR ZEPHYR!

This design has 2-stage pipeline with 4 cycles per stage, so in average every instruction
takes 4 cycles (with 40 MHz clock it will be 10 millions instructions per second in average).
Branches and Jump-and-Links takes 1 cycle more (5 cycles total).
Loads: LB - 5 cycles, LH - 6 cycles, LW - 8 cycles.
Stores: SB - 6 cycles, SH - 7 cycles, SW - 9 cycles (1 more than loads).
