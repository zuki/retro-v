// retro.v - very simplistic implementation of RISC-V architecture RV32I
// that is compilable by Verilator, capable to pass RV32I compliance tests
// and compatible with RTOS Zephyr v1.13.0
//
// RETRO-V v1.0-Alpha2 (November 2018)
//
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

// THIS IS STILL WORK IN PROGRESS!!! NOT YET READY FOR TESTS OR ZEPHYR!

module retro (nres,clk,hold,address,data_in,data_out,wren);

parameter ADDRESS_WIDTH = 16;       // address bus width
parameter REGISTERS_NUM = 64;       // number of registers (32+16=48)
input nres;                         // external negative reset
input clk;                          // external clock
input hold;                         // external hold
output [ADDRESS_WIDTH-1:0] address; // address bus for external memory
input [7:0] data_in;                // data in for memory read
output reg [7:0] data_out;          // data out for memory write
output reg wren;                    // memory write enable
// special internal addresses:
parameter MTIME_ADDR    = 32'h40000000;
parameter MTIMECMP_ADDR = 32'h40000008;
parameter UART_TX_ADDR  = 32'h40002000;
parameter START_ADDR    = 32'h80000000;

// general purpose & control and status registers
reg [31:0] regs[REGISTERS_NUM-1:0] /* synthesis syn_ramstyle="block_ram" */;
reg [31:0] inst /*verilator public*/;
reg [31:0] arg1 /*verilator public*/;
reg [31:0] arg2 /*verilator public*/;
reg [31:0] imm  /*verilator public*/;
reg [31:0] pc;  // program counter
reg [31:0] pc2; // stored program counter
reg [31:0] res; // result register
reg [9:0] op;   // extended opcode
reg [5:0] rd,rd2; // destination register ids
reg [2:0] lbytes; // current number of bytes to load
reg [2:0] sbytes; // current number of bytes to store
reg [1:0] bytes;  // total number of bytes to transfer (3 means 4)
reg [31:0] extaddr; // external address
reg flag,pcflag,unflag,errop/*verilator public*/; // flags

assign address = (lbytes!=3'b0||sbytes!=3'b0)?extaddr[ADDRESS_WIDTH-1:0]:pc[ADDRESS_WIDTH-1:0];

always @(posedge clk) begin
     if(~hold) begin
        case (pc[1:0])

          2'b00: begin // 1st byte of the instruction
                 if(sbytes==3'b0 && lbytes==3'b0) begin
                    inst <= { 24'h000000, data_in };
                 end else begin
                    inst <= { 24'h000000, inst[7:0] };
                 end
                 // 2nd stage of pipeline below
                 rd2 <= rd;
                 casez ( op )
                    10'b???0110111: // LUI
                       begin
                               pc2 <= pc;
                               pcflag <= 1'b0;
                               res <= imm;
                       end
                    10'b???0010111: // AUIPC
                       begin
                               pc2 <= pc;
                               pcflag <= 1'b0;
                               res <= pc2 + imm;
                       end
                    10'b???1101111: // JAL
                       begin
                               pc2 <= pc2 + imm;
                               pcflag <= 1'b1; // set pc-change event
                               op <= 10'b0; // !!!
                               if(rd!=6'b0) begin
                                  regs[rd] <= pc; // this is pc+4 stored to rd
                               end
//                               res <= 32'b0;
                       end
                    10'b0001100111: // JALR
                       begin
                               pc2 <= arg1 + imm;
                               pcflag <= 1'b1; // set pc-change event
                               op <= 10'b0; // !!!
                               if(rd!=6'b0) begin
                                  regs[rd] <= pc; // this is pc+4 stored to rd
                               end
//                               res <= 32'b0;
                       end
                    10'b0001100011: // BEQ
                       begin
                               if(arg1==arg2) begin
                                  pc2 <= pc2 + imm;
                                  pcflag <= 1'b1; // set pc-change event
                                  op <= 10'b0; // !!!
                               end else begin
                                  pc2 <= pc;
                                  pcflag <= 1'b0;
                               end
//                               res <= 32'b0;
                       end
                    10'b0011100011: // BNE
                       begin
                               if(arg1!=arg2) begin
                                  pc2 <= pc2 + imm;
                                  pcflag <= 1'b1; // set pc-change event
                                  op <= 10'b0; // !!!
                               end else begin
                                  pc2 <= pc;
                                  pcflag <= 1'b0;
                               end
//                               res <= 32'b0;
                       end
                    10'b1001100011: // BLT
                       begin
                               if($signed(arg1) < $signed(arg2)) begin
                                  pc2 <= pc2 + imm;
                                  pcflag <= 1'b1; // set pc-change event
                                  op <= 10'b0; // !!!
                               end else begin
                                  pc2 <= pc;
                                  pcflag <= 1'b0;
                               end
//                               res <= 32'b0;
                       end
                    10'b1011100011: // BGE
                       begin
                               if($signed(arg1) >= $signed(arg2)) begin
                                  pc2 <= pc2 + imm;
                                  pcflag <= 1'b1; // set pc-change event
                                  op <= 10'b0; // !!!
                               end else begin
                                  pc2 <= pc;
                                  pcflag <= 1'b0;
                               end
//                               res <= 32'b0;
                       end
                    10'b1101100011: // BLTU
                       begin
                               if(arg1 < arg2) begin
                                  pc2 <= pc2 + imm;
                                  pcflag <= 1'b1; // set pc-change event
                                  op <= 10'b0; // !!!
                               end else begin
                                  pc2 <= pc;
                                  pcflag <= 1'b0;
                               end
//                               res <= 32'b0;
                       end
                    10'b1111100011: // BGEU
                       begin
                               if(arg1 >= arg2) begin
                                  pc2 <= pc2 + imm;
                                  pcflag <= 1'b1; // set pc-change event
                                  op <= 10'b0; // !!!
                               end else begin
                                  pc2 <= pc;
                                  pcflag <= 1'b0;
                               end
//                               res <= 32'b0;
                       end
                    10'b???0?00011: // LOAD or STORE
                       begin
                               pc2 <= pc;
                               pcflag <= 1'b0;
                               if(sbytes==3'b0 && lbytes==3'b0) begin
                                 extaddr <= arg1+imm;
                                 if(op[5]==0) begin // LOAD
                                   lbytes <= (op[8:7]==2'b00)?3'b001:
                                             (op[8:7]==2'b01)?3'b010:
                                             (op[8:7]==2'b10)?3'b100:3'b0;
                                   bytes  <= (op[8:7]==2'b00)?2'b01:
                                             (op[8:7]==2'b01)?2'b10:
                                             (op[8:7]==2'b10)?2'b11:2'b0;
                                   unflag <= op[9];
                                 end else begin // STORE
                                   sbytes <= (op[8:7]==2'b00)?3'b010:
                                             (op[8:7]==2'b01)?3'b011:
                                             (op[8:7]==2'b10)?3'b101:3'b0;
                                   bytes  <= (op[8:7]==2'b00)?2'b01:
                                             (op[8:7]==2'b01)?2'b10:
                                             (op[8:7]==2'b10)?2'b11:2'b0;
                                 end
                                 res <= 32'b0;
                               end else begin // memory transfer in progress
                                 if(op[5]==0) begin // LOAD
                                   extaddr <= extaddr + 1'b1;
                                   lbytes <= lbytes - 1'b1;
                                   case (lbytes)
                                     3'b100:
                                       begin
                                         res <= { 24'b0, data_in };
                                       end
                                     3'b011:
                                       begin
                                         res <= { 16'b0, data_in, res[7:0] };
                                       end
                                     3'b010:
                                       begin
                                         if(bytes==2'b10) begin
                                            res <= { 24'b0, data_in };
                                         end else begin // 2'b11
                                            res <= { 8'b0, data_in, res[15:0] };
                                         end
                                       end
                                     default: // 3'b001
                                       begin
                                         if(bytes==2'b01) begin
                                            if(unflag==1'b1 || data_in[7]==1'b0) begin
                                               res <= { 24'b000000000000000000000000, data_in };
                                            end else begin
                                               res <= { 24'b111111111111111111111111, data_in };
                                            end
                                         end else begin
                                            if(bytes==2'b10) begin
                                               if(unflag==1'b1 || data_in[7]==1'b0) begin
                                                  res <= { 16'b0000000000000000, data_in, res[7:0] };
                                               end else begin
                                                  res <= { 16'b1111111111111111, data_in, res[7:0] };
                                               end
                                            end else begin // 2'b11
                                               res <= { data_in, res[23:0] };
                                            end
                                         end
                                       end
                                   endcase
                                 end else begin // STORE
                                   sbytes <= sbytes - 1'b1;
                                   case (sbytes)
                                     3'b101:
                                       begin
                                        extaddr <= extaddr;
                                        data_out <= arg2[7:0];
                                        wren <= 1'b1;
                                       end
                                     3'b100:
                                       begin
                                        extaddr <= extaddr+1'b1;
                                        data_out <= arg2[15:8];
                                        wren <= 1'b1;
                                       end
                                     3'b011:
                                       begin
                                        extaddr <= extaddr+{31'b0,bytes[0]};
                                        data_out <= (bytes==2'b11)?arg2[23:16]:arg2[7:0];
                                        wren <= 1'b1;
                                       end
                                     3'b010:
                                       begin
                                        extaddr <= (extaddr==UART_TX_ADDR)?32'hFFFFFFFF:(extaddr+{31'b0,bytes[1]});
                                        data_out <= (bytes==2'b11)?arg2[31:24]:(bytes==2'b10)?arg2[15:8]:arg2[7:0];
                                        wren <= 1'b1;
                                       end
                                     default:
                                       begin
                                        extaddr <= 32'b0;
                                        data_out <= data_out;
                                        wren <= 1'b0;
                                       end
                                   endcase
                                   res <= 32'b0;
                                 end
                               end
                       end
                    10'b0000010011: // ADDI
                       begin
                               pc2 <= pc;
                               pcflag <= 1'b0;
                               res <= arg1 + imm;
                       end
                    10'b0100010011: // SLTI
                       begin
                               pc2 <= pc;
                               pcflag <= 1'b0;
                               res <= ($signed(arg1) < $signed(imm))?32'b1:32'b0;
                       end
                    10'b0110010011: // SLTIU
                       begin
                               pc2 <= pc;
                               pcflag <= 1'b0;
                               res <= (arg1 < imm)?32'b1:32'b0;
                       end
                    10'b1000010011: // XORI
                       begin
                               pc2 <= pc;
                               pcflag <= 1'b0;
                               res <= arg1 ^ imm;
                       end
                    10'b1100010011: // ORI
                       begin
                               pc2 <= pc;
                               pcflag <= 1'b0;
                               res <= arg1 | imm;
                       end
                    10'b1110010011: // ANDI
                       begin
                               pc2 <= pc;
                               pcflag <= 1'b0;
                               res <= arg1 & imm;
                       end
                    10'b0010010011, // SLLI
                    10'b0010110011: // SLL
                       begin
                          pc2 <= pc;
                          pcflag <= 1'b0;
                          case (arg2[4:0])
                            5'b00000: res <= arg1;
                            5'b00001: res <= { arg1[30:0], 1'b0 };
                            5'b00010: res <= { arg1[29:0], 2'b0 };
                            5'b00011: res <= { arg1[28:0], 3'b0 };
                            5'b00100: res <= { arg1[27:0], 4'b0 };
                            5'b00101: res <= { arg1[26:0], 5'b0 };
                            5'b00110: res <= { arg1[25:0], 6'b0 };
                            5'b00111: res <= { arg1[24:0], 7'b0 };
                            5'b01000: res <= { arg1[23:0], 8'b0 };
                            5'b01001: res <= { arg1[22:0], 9'b0 };
                            5'b01010: res <= { arg1[21:0], 10'b0 };
                            5'b01011: res <= { arg1[20:0], 11'b0 };
                            5'b01100: res <= { arg1[19:0], 12'b0 };
                            5'b01101: res <= { arg1[18:0], 13'b0 };
                            5'b01110: res <= { arg1[17:0], 14'b0 };
                            5'b01111: res <= { arg1[16:0], 15'b0 };
                            5'b10000: res <= { arg1[15:0], 16'b0 };
                            5'b10001: res <= { arg1[14:0], 17'b0 };
                            5'b10010: res <= { arg1[13:0], 18'b0 };
                            5'b10011: res <= { arg1[12:0], 19'b0 };
                            5'b10100: res <= { arg1[11:0], 20'b0 };
                            5'b10101: res <= { arg1[10:0], 21'b0 };
                            5'b10110: res <= { arg1[9:0], 22'b0 };
                            5'b10111: res <= { arg1[8:0], 23'b0 };
                            5'b11000: res <= { arg1[7:0], 24'b0 };
                            5'b11001: res <= { arg1[6:0], 25'b0 };
                            5'b11010: res <= { arg1[5:0], 26'b0 };
                            5'b11011: res <= { arg1[4:0], 27'b0 };
                            5'b11100: res <= { arg1[3:0], 28'b0 };
                            5'b11101: res <= { arg1[2:0], 29'b0 };
                            5'b11110: res <= { arg1[1:0], 30'b0 };
                            5'b11111: res <= { arg1[0], 31'b0 };
                          endcase
                       end
                    10'b1010010011, // SRLI or SRAI
                    10'b1010110011: // SRL or SRA
                       begin
                       pc2 <= pc;
                       pcflag <= 1'b0;
                       if(flag==1'b0 || arg1[31]==1'b0)
                       begin
                          case (arg2[4:0])
                            5'b00000: res <= arg1;
                            5'b00001: res <= { 1'b0, arg1[31:1] };
                            5'b00010: res <= { 2'b0, arg1[31:2] };
                            5'b00011: res <= { 3'b0, arg1[31:3] };
                            5'b00100: res <= { 4'b0, arg1[31:4] };
                            5'b00101: res <= { 5'b0, arg1[31:5] };
                            5'b00110: res <= { 6'b0, arg1[31:6] };
                            5'b00111: res <= { 7'b0, arg1[31:7] };
                            5'b01000: res <= { 8'b0, arg1[31:8] };
                            5'b01001: res <= { 9'b0, arg1[31:9] };
                            5'b01010: res <= { 10'b0, arg1[31:10] };
                            5'b01011: res <= { 11'b0, arg1[31:11] };
                            5'b01100: res <= { 12'b0, arg1[31:12] };
                            5'b01101: res <= { 13'b0, arg1[31:13] };
                            5'b01110: res <= { 14'b0, arg1[31:14] };
                            5'b01111: res <= { 15'b0, arg1[31:15] };
                            5'b10000: res <= { 16'b0, arg1[31:16] };
                            5'b10001: res <= { 17'b0, arg1[31:17] };
                            5'b10010: res <= { 18'b0, arg1[31:18] };
                            5'b10011: res <= { 19'b0, arg1[31:19] };
                            5'b10100: res <= { 20'b0, arg1[31:20] };
                            5'b10101: res <= { 21'b0, arg1[31:21] };
                            5'b10110: res <= { 22'b0, arg1[31:22] };
                            5'b10111: res <= { 23'b0, arg1[31:23] };
                            5'b11000: res <= { 24'b0, arg1[31:24] };
                            5'b11001: res <= { 25'b0, arg1[31:25] };
                            5'b11010: res <= { 26'b0, arg1[31:26] };
                            5'b11011: res <= { 27'b0, arg1[31:27] };
                            5'b11100: res <= { 28'b0, arg1[31:28] };
                            5'b11101: res <= { 29'b0, arg1[31:29] };
                            5'b11110: res <= { 30'b0, arg1[31:30] };
                            5'b11111: res <= { 31'b0, arg1[31] };
                          endcase
                       end else begin
                          case (arg2[4:0])
                            5'b00000: res <= arg1;
                            5'b00001: res <= {  1'b1, arg1[31:1] };
                            5'b00010: res <= {  2'b11, arg1[31:2] };
                            5'b00011: res <= {  3'b111, arg1[31:3] };
                            5'b00100: res <= {  4'b1111, arg1[31:4] };
                            5'b00101: res <= {  5'b11111, arg1[31:5] };
                            5'b00110: res <= {  6'b111111, arg1[31:6] };
                            5'b00111: res <= {  7'b1111111, arg1[31:7] };
                            5'b01000: res <= {  8'b11111111, arg1[31:8] };
                            5'b01001: res <= {  9'b111111111, arg1[31:9] };
                            5'b01010: res <= { 10'b1111111111, arg1[31:10] };
                            5'b01011: res <= { 11'b11111111111, arg1[31:11] };
                            5'b01100: res <= { 12'b111111111111, arg1[31:12] };
                            5'b01101: res <= { 13'b1111111111111, arg1[31:13] };
                            5'b01110: res <= { 14'b11111111111111, arg1[31:14] };
                            5'b01111: res <= { 15'b111111111111111, arg1[31:15] };
                            5'b10000: res <= { 16'b1111111111111111, arg1[31:16] };
                            5'b10001: res <= { 17'b11111111111111111, arg1[31:17] };
                            5'b10010: res <= { 18'b111111111111111111, arg1[31:18] };
                            5'b10011: res <= { 19'b1111111111111111111, arg1[31:19] };
                            5'b10100: res <= { 20'b11111111111111111111, arg1[31:20] };
                            5'b10101: res <= { 21'b111111111111111111111, arg1[31:21] };
                            5'b10110: res <= { 22'b1111111111111111111111, arg1[31:22] };
                            5'b10111: res <= { 23'b11111111111111111111111, arg1[31:23] };
                            5'b11000: res <= { 24'b111111111111111111111111, arg1[31:24] };
                            5'b11001: res <= { 25'b1111111111111111111111111, arg1[31:25] };
                            5'b11010: res <= { 26'b11111111111111111111111111, arg1[31:26] };
                            5'b11011: res <= { 27'b111111111111111111111111111, arg1[31:27] };
                            5'b11100: res <= { 28'b1111111111111111111111111111, arg1[31:28] };
                            5'b11101: res <= { 29'b11111111111111111111111111111, arg1[31:29] };
                            5'b11110: res <= { 30'b111111111111111111111111111111, arg1[31:30] };
                            5'b11111: res <= { 31'b1111111111111111111111111111111, arg1[31] };
                          endcase
                       end
                       end
                    10'b0000110011: // ADD or SUB
                       begin
                               pc2 <= pc;
                               pcflag <= 1'b0;
                               if(flag==1'b0) begin
                                 res <= arg1 + arg2;
                               end else begin
                                 res <= arg1 - arg2;
                               end
                       end
                    10'b0100110011: // SLT
                       begin
                               pc2 <= pc;
                               pcflag <= 1'b0;
                               res <= ($signed(arg1) < $signed(arg2))?1:0;
                       end
                    10'b0110110011: // SLTU
                       begin
                               pc2 <= pc;
                               pcflag <= 1'b0;
                               res <= (arg1 < arg2)?1:0;
                       end
                    10'b1000110011: // XOR
                       begin
                               pc2 <= pc;
                               pcflag <= 1'b0;
                               res <= arg1 ^ arg2;
                       end
                    10'b1100110011: // OR
                       begin
                               pc2 <= pc;
                               pcflag <= 1'b0;
                               res <= arg1 | arg2;
                       end
                    10'b1110110011: // AND
                       begin
                               pc2 <= pc;
                               pcflag <= 1'b0;
                               res <= arg1 & arg2;
                       end
                    10'b0001110011: // ECALL, EBREAK and other priviledged instructions
                       begin
                       end
                    default: // FENCE and FENCE.I go here as NOPs
                       begin
                               pc2 <= pc; // this is actually store in the 1st stage to use in the 2nd
                               pcflag <= 1'b0;
                       end
                 endcase
                 end

          2'b01: begin // 2nd byte of the instruction (fill op and rd)
                 inst <= { 16'h0000, data_in, inst[7:0] };
                 if(inst[6:0]==7'b0100011) begin
                    rd <= 6'b0; // STORE special case
                 end else begin
                    rd <= { 1'b0, data_in[3:0], inst[7] };
                 end
                 flag <= data_in[7];
                 op <= { data_in[6:4], inst[6:0] };
                 // check if it's a valid opcode or not
                 case ( inst[6:0] )
                     7'b0110111,7'b0010111,7'b1101111,7'b0010011,7'b0110011:
                       begin
                         errop <= 1'b0;
                       end
                     7'b1100111: // JALR
                       begin
                         if(data_in[6:4]==3'b000) begin
                            errop <= 1'b0;
                         end else begin
                            errop <= 1'b1;
                         end
                       end
                     7'b1100011: // BRANCH
                       begin
                         if(data_in[6:4]==3'b010 || data_in[6:4]==3'b011) begin
                            errop <= 1'b1;
                         end else begin
                            errop <= 1'b0;
                         end
                       end
                     7'b0000011: // LOAD
                       begin
                         if(data_in[6:4]==3'b000 || data_in[6:4]==3'b001 || data_in[6:4]==3'b010 ||
                            data_in[6:4]==3'b100 || data_in[6:4]==3'b101) begin
                            errop <= 1'b0;
                         end else begin
                            errop <= 1'b1;
                         end
                       end
                     7'b0100011: // SAVE
                       begin
                         if(data_in[6:4]==3'b000 || data_in[6:4]==3'b001 || data_in[6:4]==3'b010) begin
                            errop <= 1'b0;
                         end else begin
                            errop <= 1'b1;
                         end
                       end
                     7'b0001111: // MISC-MEM (FENCE and FENCE.I)
                       begin
                         if(data_in[6:4]==3'b000 || data_in[6:4]==3'b001) begin
                            errop <= 1'b0;
                         end else begin
                            errop <= 1'b1;
                         end
                       end
                     7'b1110011: // SYSTEM
                       begin
                         if(data_in[6:4]==3'b100) begin
                            errop <= 1'b1;
                         end else begin
                            errop <= 1'b0;
                         end
                       end
                     default: // everything else is invalid
                       begin
                         errop <= 1'b1;
                       end
                 endcase
                 // 2nd step of 2nd stage of pipeline below
                 if(rd2!=6'b0) begin // it has to be rd2 otherwise it wastes 1K+ LUTs in iCEcube2
                     regs[rd2] <= res; // write back
                 end
                 end

          2'b10: begin // 3rd byte of the instruction (fill arg1)
                 inst <= { 8'h00, data_in, inst[15:0] };
                 casez ( op )
                     10'b0001100111,
                     10'b???1100011,
                     10'b???0000011,
                     10'b???0100011,
                     10'b???0010011,
                     10'b???0110011,
                     10'b0011110011,
                     10'b0101110011,
                     10'b0111110011:
                        arg1 <= regs[ { 1'b0, data_in[3:0], flag } ]; // value from rs1
                     10'b1011110011,
                     10'b1101110011,
                     10'b1111110011:
                        arg1 <= { 27'b0, data_in[3:0], flag }; // value of rs1
                     default:
                        arg1 <= 32'h00000000;
                 endcase
                 arg2 <= { 28'b0, data_in[7:4] };
                 end

          2'b11: begin // 4th byte of the instruction (fill arg2, imm and flag)
                 inst <= { data_in, inst[23:0] }; // inst can not be used anymore
                 flag <= data_in[6]; // subfunction flag
                 casez ( op )
                     10'b???0110111,10'b???0010111:
                        begin // U-type
                          imm <= { data_in, inst[23:12], 12'b0 }; // 32-bit immeadiate (with zeroed lowest 12 bits)
                          arg2 <= 32'h00000000;
                        end
                     10'b???1101111:
                        begin // J-type
                          if(data_in[7]) begin
                            imm <= { 12'b111111111111, inst[19:12], inst[20], data_in[6:0], inst[23:21], 1'b0 }; // 21-bit immediate (negative)
                          end else begin
                            imm <= { 12'b000000000000, inst[19:12], inst[20], data_in[6:0], inst[23:21], 1'b0 }; // 21-bit immediate (positive)
                          end
                          arg2 <= 32'h00000000;
                        end
                     10'b???1100011:
                        begin // B-type
                          if(data_in[7]) begin
                            imm <= { 20'b11111111111111111111, inst[7], data_in[6:1], inst[11:8], 1'b0 }; // 13-bit immediate (negative)
                          end else begin
                            imm <= { 20'b00000000000000000000, inst[7], data_in[6:1], inst[11:8], 1'b0 }; // 13-bit immediate (negative)
                          end
                          arg2 <= regs[ { 1'b0, data_in[0], arg2[3:0] } ]; // value from rs2
                        end
                     10'b???0100011:
                        begin // S-type
                          if(data_in[7]) begin
                            imm <= { 21'b111111111111111111111, data_in[6:1], inst[11:7] }; // 12-bit immediate (negative)
                          end else begin
                            imm <= { 21'b000000000000000000000, data_in[6:1], inst[11:7] }; // 12-bit immediate (positive)
                          end
                          arg2 <= regs[ { 1'b0, data_in[0], arg2[3:0] } ]; // value from rs2
                        end
                     10'b0010010011,10'b1010010011:
                        begin // shifts
                          imm <= 32'h00000000;
                          arg2 <= { 27'b0, data_in[0], arg2[3:0] }; // shamt
                        end
                     10'b???0110011:
                        begin // R-type
                          imm <= 32'h00000000;
                          arg2 <= regs[ { 1'b0, data_in[0], arg2[3:0] } ]; // value from rs2
                        end
                     default: // I-type
                        begin
                          if(data_in[7]) begin
                            imm <= { 20'b11111111111111111111, data_in, arg2[3:0] }; // 12-bit immediate or CSR (negative)
                          end else begin
                            imm <= { 20'b00000000000000000000, data_in, arg2[3:0] }; // 12-bit immediate or CSR (positive)
                          end
                          arg2 <= 32'h00000000;
                        end
                 endcase
                 end
        endcase
     end

end

always @(negedge clk) begin
  if(nres) begin
     if(~hold) begin
        if(pcflag) begin
           pc <= pc2 & 32'hFFFFFFFC;
        end else if(sbytes==3'b0 && lbytes==3'b0) begin
           pc <= pc + 1'b1;
        end
     end
  end else begin
     // reset condition (nres=0)
     pc <= START_ADDR;
  end
end

initial begin
regs[0]=32'h00000000; // ???
data_out=8'h00;
wren=1'b0;
sbytes=3'b0;
lbytes=3'b0;
end

endmodule
