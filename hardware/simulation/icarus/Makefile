ETH_DIR:=../../..

defmacro:=-D
incdir:=-I

SIMULATOR=icarus
SIM_SERVER=$(IVSIM_SERVER)
SIM_USER=$(IVSIM_USER)
SIM_PROC=a.out

include ../simulation.mk

VSRC_CP=$(VSRC)
VSRC:=$(filter-out ../../../hardware/src/eth_oc/xilinx_dist_ram_16x32.v , $(VSRC))
VSRC+=iob_ethoc_tb.v
#simulator flags
VLOG = iverilog -Wall -g2005-sv $(INCLUDE) $(DEFINE)

comp: $(SIM_PROC)

#simulation executable
$(SIM_PROC):
	$(VLOG) $(VSRC)

exec:
	./$(SIM_PROC)

clean: clean-remote
	@rm -f $(SIM_PROC)

.PHONY: comp exec clean
