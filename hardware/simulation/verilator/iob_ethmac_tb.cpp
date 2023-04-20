#include <stdio.h>
#include <stdlib.h>

#include "Viob_ethmac_sim_wrapper.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

// other macros
#define CLK_PERIOD 100 // 10 ns
#define ETH_CLK_PERIOD 25 // 10 ns

#define ETH_MODER_ADR         0x0    // 0x0 
#define ETH_INT_SOURCE_ADR    0x1    // 0x4 
#define ETH_INT_MASK_ADR      0x2    // 0x8 
#define ETH_IPGT_ADR          0x3    // 0xC 
#define ETH_IPGR1_ADR         0x4    // 0x10
#define ETH_IPGR2_ADR         0x5    // 0x14
#define ETH_PACKETLEN_ADR     0x6    // 0x18
#define ETH_COLLCONF_ADR      0x7    // 0x1C
#define ETH_TX_BD_NUM_ADR     0x8    // 0x20
#define ETH_CTRLMODER_ADR     0x9    // 0x24
#define ETH_MIIMODER_ADR      0xA    // 0x28
#define ETH_MIICOMMAND_ADR    0xB    // 0x2C
#define ETH_MIIADDRESS_ADR    0xC    // 0x30
#define ETH_MIITX_DATA_ADR    0xD    // 0x34
#define ETH_MIIRX_DATA_ADR    0xE    // 0x38
#define ETH_MIISTATUS_ADR     0xF    // 0x3C
#define ETH_MAC_ADDR0_ADR     0x10   // 0x40
#define ETH_MAC_ADDR1_ADR     0x11   // 0x44
#define ETH_HASH0_ADR         0x12   // 0x48
#define ETH_HASH1_ADR         0x13   // 0x4C
#define ETH_TX_CTRL_ADR       0x14   // 0x50
#define ETH_RX_CTRL_ADR       0x15   // 0x54
#define ETH_DBG_ADR           0x16   // 0x58

vluint64_t main_time = 0;
VerilatedVcdC* tfp = NULL;
Viob_ethmac_sim_wrapper* dut = NULL;

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
  dut = new Viob_ethmac_sim_wrapper;
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

  // Reset sequence
  Timer(CLK_PERIOD);
  dut->arst_i = !(dut->arst_i);
  Timer(CLK_PERIOD);
  dut->arst_i = !(dut->arst_i);
  printf("\nTestbench started!\n\n");
  // Start of testbench

  printf("Enable loop back, TX is looped back to the RX.");
  set_inputs(ETH_MODER_ADR, 0x0000A080, 0xff);
  printf("Enable full-duplex mode.");
  set_inputs(ETH_MODER_ADR, 0x0000A480, 0xff);

  // End of testbench
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