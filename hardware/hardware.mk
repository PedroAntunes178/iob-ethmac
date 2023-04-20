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
INCLUDE+=$(incdir). $(incdir)$(ETH_INC_DIR)

#sources
VSRC+=$(ETH_SRC_DIR)/iob_ethmac.v 
VSRC+=$(wildcard $(ETH_SRC_DIR)/eth_oc/*.v) 

ethernet_hw_clean: ethernet_gen_clean
	@rm -f *.vh

.PHONY: ethernet_hw_clean

endif