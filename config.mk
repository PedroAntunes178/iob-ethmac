######################################################################
#
# ETH Configuration File
#
######################################################################

SHELL = bash

TOP_MODULE:=iob_ethoc

#
# PRIMARY PARAMETERS: CAN BE CHANGED BY USERS OR OVERRIDEN BY ENV VARS
#

#CPU ARCHITECTURE
DATA_W ?=32
ADDR_W ?=16

#ETH DIRECTORY ON REMOTE MACHINES
REMOTE_ETH_DIR ?=sandbox/iob_ethoc

#SIMULATION
#default simulator running locally or remotely
#check the respective Makefile in hardware/simulation/$(SIMULATOR) for specific settings
SIMULATOR ?=icarus

####################################################################
# DERIVED FROM PRIMARY PARAMETERS: DO NOT CHANGE BELOW THIS POINT
####################################################################

#sw paths
ETH_SW_DIR=$(ETH_DIR)/software

#hw paths
ETH_HW_DIR=$(ETH_DIR)/hardware
ETH_SIM_DIR=$(ETH_HW_DIR)/simulation/$(SIMULATOR)

LIB_DIR?=$(ETH_DIR)/submodules/LIB
VETH_DIR?=$(ETH_DIR)/submodules/verilog-ethernet

#RULES
ethernet_gen_clean:
	@rm -f *# *~

.PHONY: gen-clean