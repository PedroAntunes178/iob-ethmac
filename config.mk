######################################################################
#
# ETH Configuration File
#
######################################################################

SHELL = bash

TOP_MODULE:=iob_ethmac

#
# PRIMARY PARAMETERS: CAN BE CHANGED BY USERS OR OVERRIDEN BY ENV VARS
#

#CPU ARCHITECTURE
DATA_W ?=32
ADDR_W ?=12

#ETH DIRECTORY ON REMOTE MACHINES
REMOTE_ETH_DIR ?=sandbox/iob_ethmac

#SIMULATION
# Uses Open Cores Ethernet original testbench

####################################################################
# DERIVED FROM PRIMARY PARAMETERS: DO NOT CHANGE BELOW THIS POINT
####################################################################

#sw paths
ETH_SW_DIR=$(ETH_DIR)/software

#hw paths
ETH_HW_DIR=$(ETH_DIR)/hardware
ETH_SIM_DIR=$(ETH_HW_DIR)/simulation

LIB_DIR?=$(ETH_DIR)/submodules/LIB
ETHOC_DIR?=$(ETH_DIR)/submodules/ETHMAC
WB2AXIL_DIR:=$(ETH_DIR)/submodules/WB2AXIL

MEM_DIR:=$(LIB_DIR)

#RULES
ethernet_gen_clean:
	@rm -f *# *~

.PHONY: gen-clean