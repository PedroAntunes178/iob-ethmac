ETH_DIR:=.

include ./config.mk

#
# SIMULATE RTL
#
sim-run:
	$(MAKE) -C $(ETH_SIM_DIR) run

sim-clean:
	make -C $(ETH_SIM_DIR) clean

vcd:
	gtkwave $(ETHOC_DIR)/build/sim/ethmac.vcd &

logs:
	cat $(ETHOC_DIR)/log/eth_tb.log 

#
# BUILD TARGETS
#
build-ethernet:
	cd hardware && \
	  ethernet_gen iob_mii.yml


.PHONY: sim-build sim-run sim-clean sim