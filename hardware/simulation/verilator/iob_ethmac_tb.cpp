#include <stdio.h>
#include <stdlib.h>

#include "Vtb_ethernet.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

VerilatedVcdC* tfp = NULL;
Vtb_ethernet* dut = NULL;

int main(int argc, char **argv, char **env){
  Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(true);
  dut = new Vtb_ethernet;
  int errors;
  main_time = 0;

#ifdef VCD
  tfp = new VerilatedVcdC;
  dut->trace(tfp, 1);
  tfp->close();
#endif
  exit(0);

}