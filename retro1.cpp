#include "Vretro.h"
#include "Vretro_retro.h"
#include "verilated.h"
#include <iostream>
#include <iomanip>

unsigned char rom[] = {
/* 000x */ 0xB7, 0x07, 0x01, 0x00, 0x93, 0x87, 0x87, 0x07, 0x13, 0x07, 0x80, 0x04, 0xB7, 0x26, 0x00, 0x40,
/* 001x */ 0x23, 0x80, 0xE6, 0x00, 0x93, 0x87, 0x17, 0x00, 0x03, 0xC7, 0x07, 0x00, 0xE3, 0x1A, 0x07, 0xFE,
/* 002x */ 0x67, 0x80, 0x00, 0x00, 0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x20, 0x52, 0x49, 0x53, 0x43, 0x2D, 0x56,
/* 003x */ 0x21, 0x0A, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
/* 004x */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
/* 005x */ 0x00, 0x00, 0x00, 0x00, 0xB7, 0x07, 0x01, 0x00, 0x93, 0x87, 0x87, 0x07, 0x13, 0x07, 0x80, 0x04,
/* 006x */ 0xB7, 0x26, 0x00, 0x40, 0x23, 0x80, 0xE6, 0x00, 0x93, 0x87, 0x17, 0x00, 0x03, 0xC7, 0x07, 0x00,
/* 007x */ 0xE3, 0x1A, 0x07, 0xFE, 0x67, 0x80, 0x00, 0x00, 0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x20, 0x52, 0x49,
/* 008x */ 0x53, 0x43, 0x2D, 0x56, 0x21, 0x0A, 0x00, 0x00

};

int main(int argc, char** argv, char** env)
{
  Verilated::commandArgs(argc,argv);

  int adr=0, old_clk=0;
  unsigned long t=0;

  Vretro* top = new Vretro();

  cout << internal << setfill('0');

  while(!Verilated::gotFinish())
  {
     top->clk = t&1;
     top->hold = 0;
     if(top->address > sizeof(rom))
          top->data_in = 1;
     else top->data_in = rom[top->address];
     if(t<10)
     {
        top->nres = 0;
     }
     else // t >= 10
     {
        top->nres = 1;
     }

     top->eval(); // <<<<<<<<< EVAL

     cout << t++ << " nres=" << (int)top->nres << " clk=" << (int)top->clk << " address=" << hex << setw(4) << (int)top->address
          << " din=" << setw(2) << (int)top->data_in << " dout=" << setw(2) << (int)top->data_out << " wren=" << (int)top->wren
          << " inst=" << setw(8) << (int)top->retro->inst << " rd=" << (int)top->retro->__PVT__rd
          << " arg1=" << setw(8) << (int)top->retro->arg1 << " arg2=" << setw(8) << (int)top->retro->arg2 << " imm=" << setw(8) << (int)top->retro->imm
          << " x13=" << setw(8) << (int)top->retro->__PVT__regs[13]
          << " x14=" << setw(8) << (int)top->retro->__PVT__regs[14]
          << " x15=" << setw(8) << (int)top->retro->__PVT__regs[15]
          << " extaddr=" << setw(8) << (int)top->retro->__PVT__extaddr
          << " res=" << setw(8) << (int)top->retro->__PVT__res
          << setw(4) << " op=" << (int)top->retro->__PVT__op << dec << " errop=" << (int)top->retro->errop
          << " lbytes=" << (int)top->retro->__PVT__lbytes << " sbytes=" << (int)top->retro->__PVT__sbytes
          << endl;

     if(top->address==0xFFFF && !old_clk && top->clk)
     {
          cerr << (char)top->data_out;
     }

     old_clk = top->clk;
  }

  delete top;

  exit(0);
}

