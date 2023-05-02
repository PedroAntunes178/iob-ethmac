ETH_DIR:=.

include ./config.mk

#
# SIMULATE RTL
#
sim-run:
	$(MAKE) -C $(ETH_SIM_DIR) run

sim-clean:
	make -C $(ETH_SIM_DIR) clean

#
# BUILD TARGETS
#
build-ethernet:
	cd hardware && \
	  ethernet_gen iob_mii.yml


.PHONY: sim-build sim-run sim-clean sim