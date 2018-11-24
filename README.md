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
