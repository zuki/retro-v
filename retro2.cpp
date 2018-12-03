#include "Vretro.h"
#include "Vretro_retro.h"
#include "verilated.h"
#include <iostream>
#include <iomanip>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <time.h>
#include <libelf.h>
#include <gelf.h>

// Code that handles ELF and compliance tests signagures was taken from
// https://gist.github.com/FrankBuss/c974e59826d33e21d7cad54491ab50e8
// originally licensed under MIT license - thanks Frank Buss !

#define RAM_SIZE 65536

unsigned char ram[RAM_SIZE];

int main(int argc, char** argv, char** env)
{
    FILE *fo;
    char *po,hex_file[100];

    uint32_t mtvec;

    /* virtual start address for index 0 in the ram array */
    uint32_t ram_start;

    /* last byte of the memory initialized and temporary value */
    uint32_t ram_last = 0;
    uint32_t ram_curr = 0;

    /* used when called from the compliance tests */
    uint32_t begin_signature = 0;
    uint32_t end_signature = 0;

    /* automatic STDOUT flushing, no fflush needed */
    setvbuf(stdout, NULL, _IONBF, 0);

    /* parse command line */
    const char* elf_file = NULL;
    const char* signature_file = NULL;
    for (int i = 1; i < argc; i++) {
        char* arg = argv[i];
        if (arg == strstr(arg, "+signature=")) {
            signature_file = arg + 11;
        } else if (arg[0] != '-') {
            elf_file = arg;
        }
    }
    if (elf_file == NULL) {
        printf("missing ELF file\n");
        return 1;
    }

    for(uint32_t u=0;u<RAM_SIZE;u++) ram[u]=0;

    /* open ELF file */
    elf_version(EV_CURRENT);
    int fd = open(elf_file, O_RDONLY);
    if (fd == -1) {
        printf("can't open file %s\n", elf_file);
        return 1;
    }
    Elf *elf = elf_begin(fd, ELF_C_READ, NULL);

    /* scan for symbol table */
    Elf_Scn *scn = NULL;
    GElf_Shdr shdr;
    while ((scn = elf_nextscn(elf, scn)) != NULL) {
        gelf_getshdr(scn, &shdr);
        if (shdr.sh_type == SHT_SYMTAB) {
            Elf_Data *data = elf_getdata(scn, NULL);
            int count = shdr.sh_size / shdr.sh_entsize;
            for (int i = 0; i < count; i++) {
                GElf_Sym sym;
                gelf_getsym(data, i, &sym);
                char* name = elf_strptr(elf, shdr.sh_link, sym.st_name);
#if 0
                if(*name) printf("sym '%s' %lx\n",name,sym.st_value);
#endif
                if (strcmp(name, "begin_signature") == 0) {
                    begin_signature = sym.st_value;
                }
                if (strcmp(name, "end_signature") == 0) {
                    end_signature = sym.st_value;
                }

                /* for compliance test */
                if (strcmp(name, "_start") == 0) {
                    ram_start = sym.st_value;
                }

                /* for zephyr */
                if (strcmp(name, "__reset") == 0) {
                    ram_start = sym.st_value;
                }
                if (strcmp(name, "__irq_wrapper") == 0) {
                    mtvec = sym.st_value;
                }
            }
        }
    }
    printf("begin_signature: 0x%08x\n", begin_signature);
    printf("end_signature: 0x%08x\n", end_signature);
    printf("start: 0x%08x\n", ram_start);

    /* scan for program */
    while ((scn = elf_nextscn(elf, scn)) != NULL) {
        gelf_getshdr(scn, &shdr);
        if (shdr.sh_type == SHT_PROGBITS) {
            Elf_Data *data = elf_getdata(scn, NULL);
            if (shdr.sh_addr >= ram_start) {
                for (size_t i = 0; i < shdr.sh_size; i++) {
                    ram_curr = shdr.sh_addr + i - ram_start;
                    if(ram_curr >= RAM_SIZE)
                    {
                        printf("memory pointer outside of range 0x%08x (section at address 0x%08x)\n", ram_curr, (uint32_t) shdr.sh_addr);
                        /* break; */
                    }
                    else
                    {
                        ram[ram_curr] = ((uint8_t *)data->d_buf)[i];
                        if(ram_curr > ram_last) ram_last = ram_curr;
                    }
                }
            } else {
                printf("ignoring section at address 0x%08x\n", (uint32_t) shdr.sh_addr);
            }
        }
    }

    /* close ELF file */
    elf_end(elf);
    close(fd);

    printf("codesize: 0x%08x (%i)\n", ram_last+1, ram_last+1);
    strcpy(hex_file, elf_file);
    po = strrchr(hex_file,'.');
    if(po!=NULL) *po = 0;
    strcat(hex_file,".mem");
    fo = fopen(hex_file,"wt");
    if(fo!=NULL)
    {
       for(uint32_t u=0;u<=ram_last;u++)
       {
          fprintf(fo,"%02X ",ram[u]);
          if((u&15)==15) fprintf(fo,"\n");
       }
       fprintf(fo,"\n");
       fclose(fo);
    }

  Verilated::commandArgs(argc,argv);

  int adr=0, old_clk=0;
  unsigned long t=0;

  Vretro* top = new Vretro();

  cout << internal << setfill('0');

  while(!Verilated::gotFinish())
  {
     top->clk = ++t&1;
     top->hold = 0;
     if(top->address > sizeof(ram))
          top->data_in = 1;
     else top->data_in = ram[top->address];
     if(t<10)
     {
        top->nres = 0;
     }
     else // t >= 10
     {
        top->nres = 1;
     }

     top->eval(); // <<<<<<<<< EVAL

#if 0
     cout << t << " nres=" << (int)top->nres << " clk=" << (int)top->clk << " address=" << hex << setw(4) << (int)top->address
          << " din=" << setw(2) << (int)top->data_in << " dout=" << setw(2) << (int)top->data_out << " wren=" << (int)top->wren
          << " (" << (int)(top->address&3)+1 << ") inst=" << setw(8) << (int)top->retro->inst << " rd=" << (int)top->retro->__PVT__rd << " rd2=" << (int)top->retro->__PVT__rd2
          << " arg1=" << setw(8) << (int)top->retro->arg1 << " arg2=" << setw(8) << (int)top->retro->arg2 << " imm=" << setw(8) << (int)top->retro->imm
          << " pc=" << setw(8) << (int)top->retro->__PVT__pc << " pc2=" << setw(8) << (int)top->retro->__PVT__pc2
          << " x1=" << setw(8) << (int)top->retro->__PVT__regs[1]
          << " x2=" << setw(8) << (int)top->retro->__PVT__regs[2]
          << " x3=" << setw(8) << (int)top->retro->__PVT__regs[3]
          << " x4=" << setw(8) << (int)top->retro->__PVT__regs[4]
          << " x5=" << setw(8) << (int)top->retro->__PVT__regs[5]
          << " x6=" << setw(8) << (int)top->retro->__PVT__regs[6]
          << " x7=" << setw(8) << (int)top->retro->__PVT__regs[7]
          << " x8=" << setw(8) << (int)top->retro->__PVT__regs[8]
          << " x9=" << setw(8) << (int)top->retro->__PVT__regs[9]
          << " x10=" << setw(8) << (int)top->retro->__PVT__regs[10]
          << " x11=" << setw(8) << (int)top->retro->__PVT__regs[11]
          << " x12=" << setw(8) << (int)top->retro->__PVT__regs[12]
          << " x13=" << setw(8) << (int)top->retro->__PVT__regs[13]
          << " x14=" << setw(8) << (int)top->retro->__PVT__regs[14]
          << " x15=" << setw(8) << (int)top->retro->__PVT__regs[15]
          << " x31=" << setw(8) << (int)top->retro->__PVT__regs[31]
          << " extaddr=" << setw(8) << (int)top->retro->__PVT__extaddr
          << " res=" << setw(8) << (int)top->retro->__PVT__res
          << setw(4) << " op=" << (int)top->retro->__PVT__op << dec << " errop=" << (int)top->retro->errop
          << " lbytes=" << (int)top->retro->__PVT__lbytes << " sbytes=" << (int)top->retro->__PVT__sbytes
          << endl;
#endif

     if(top->wren && !old_clk)
     {
//          printf("write 0x%2.2X to 0x%4.4X\n",(unsigned char)top->data_out,top->address);
          if(top->address==0xFFFF && top->clk) cerr << (char)top->data_out;
          else ram[top->address] = (unsigned char)top->data_out;
     }

     if(t>100000 || top->retro->errop) break;

     old_clk = top->clk;
  }

  delete top;

    /* write signature */
    if (signature_file) {
        FILE* sf = fopen(signature_file, "w");
        int size = end_signature - begin_signature;
        for (int i = 0; i < size / 16; i++) {
            for (int j = 0; j < 16; j++) {
                fprintf(sf, "%02x", ram[begin_signature + 15 - j - ram_start]);
            }
            begin_signature += 16;
            fprintf(sf, "\n");
        }
        fclose(sf);
    }

  exit(0);
}

