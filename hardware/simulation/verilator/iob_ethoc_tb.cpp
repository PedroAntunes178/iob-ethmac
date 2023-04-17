#include <stdio.h>
#include <stdlib.h>

#include "Viob_ethoc_sim_wrapper.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

// other macros
#define CLK_PERIOD 100 // 10 ns
#define ETH_CLK_PERIOD 25 // 10 ns

vluint64_t main_time = 0;
VerilatedVcdC* tfp = NULL;
Viob_ethoc_sim_wrapper* dut = NULL;

double sc_time_stamp(){
  return main_time;
}

void Timer(unsigned int ns){
  for(int i = 0; i<ns; i++){
    if(!(main_time%(CLK_PERIOD/2))){
      dut->clk_i = !(dut->clk_i);
    }
    if(!(main_time%(ETH_CLK_PERIOD/2))){
      dut->eth_clk_i = !(dut->eth_clk_i);
    }
    main_time += 1;
    dut->eval();
  }
}

int wait_responce(){
  while(dut->ready != 1){
    Timer(CLK_PERIOD);
  }
  return dut->rdata;
}

int set_inputs(int address, int data, int strb){
  dut->valid = 1;
  dut->address = address;
  dut->wdata = data;
  dut->wstrb = strb;
  Timer(CLK_PERIOD);
  dut->valid = 0;
  return wait_responce();
}

int main(int argc, char **argv, char **env){
  Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(true);
  dut = new Viob_ethoc_sim_wrapper;
  int errors;
  main_time = 0;

#ifdef VCD
  tfp = new VerilatedVcdC;

  dut->trace(tfp, 1);
#endif
  dut->eval();

  dut->clk_i = 0;
  dut->eth_clk_i = 0;
  dut->arst_i = 0;
  dut->valid = 0;
  dut->address = 0;
  dut->wdata = 0;
  dut->wstrb = 0;

  printf("\nTestbench started!\n\n");

  // Reset sequence
  Timer(CLK_PERIOD);
  dut->arst_i = !(dut->arst_i);
  Timer(CLK_PERIOD);
  dut->arst_i = !(dut->arst_i);

  Timer(CLK_PERIOD);
  printf("\nTestbench finished!\n\n");
  dut->final();
#ifdef VCD
  tfp->close();
#endif
  delete dut;
  dut = NULL;
  printf("Number of errors: %d\n", errors);
  exit(0);

}

int csr_write_simple(uint32_t data, uint32_t addr){
  int strb = 0;
  strb = 1<<(addr&&0x00000003);
  return set_inputs(addr, data, strb);
}

int csr_read_simple(uint32_t addr){
  return set_inputs(addr, 0, 0);
}