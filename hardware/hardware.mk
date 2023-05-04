ifeq ($(filter ETH, $(HW_MODULES)),)
include $(ETH_DIR)/config.mk

#add itself to HW_MODULES list
HW_MODULES+=ETH

ETH_INC_DIR:=$(ETH_HW_DIR)/include
ETH_SRC_DIR:=$(ETH_HW_DIR)/src

#include iob-lib hardware
include $(LIB_DIR)/hardware/iob_reg/hardware.mk

#include files
VHDR+=$(wildcard $(ETH_INC_DIR)/*.vh) 

#hardware include dirs
INCLUDE+=$(incdir). $(incdir)$(ETH_INC_DIR) $(incdir)$(ETHOC_HW_DIR)

#sources
VSRC+=$(wildcard $(ETH_SRC_DIR)/*.v) 
VSRC:=$(filter-out $(ETH_SRC_DIR)/iob_reg.v, $(VSRC))
VSRC:=$(filter-out $(ETH_SRC_DIR)/iob_iob2wishbone.v, $(VSRC))
VSRC+=$(ETHOC_HW_DIR)/eth_outputcontrol.v $(ETHOC_HW_DIR)/eth_spram_256x32.v $(ETHOC_HW_DIR)/eth_clockgen.v $(ETHOC_HW_DIR)/eth_random.v $(ETHOC_HW_DIR)/eth_receivecontrol.v $(ETHOC_HW_DIR)/eth_transmitcontrol.v $(ETHOC_HW_DIR)/eth_crc.v $(ETHOC_HW_DIR)/eth_registers.v $(ETHOC_HW_DIR)/eth_txcounters.v $(ETHOC_HW_DIR)/eth_fifo.v $(ETHOC_HW_DIR)/eth_register.v $(ETHOC_HW_DIR)/eth_txethmac.v $(ETHOC_HW_DIR)/eth_maccontrol.v $(ETHOC_HW_DIR)/eth_rxaddrcheck.v $(ETHOC_HW_DIR)/eth_txstatem.v $(ETHOC_HW_DIR)/ethmac_defines.v $(ETHOC_HW_DIR)/eth_rxcounters.v $(ETHOC_HW_DIR)/eth_wishbone.v $(ETHOC_HW_DIR)/eth_macstatus.v $(ETHOC_HW_DIR)/eth_rxethmac.v $(ETHOC_HW_DIR)/ethmac.v $(ETHOC_HW_DIR)/eth_rxstatem.v $(ETHOC_HW_DIR)/eth_miim.v $(ETHOC_HW_DIR)/eth_shiftreg.v 

#$(ETHOC_HW_DIR)/xilinx_dist_ram_16x32.v


ethernet_hw_clean: ethernet_gen_clean
	@rm -f *.vh

.PHONY: ethernet_hw_clean

endif