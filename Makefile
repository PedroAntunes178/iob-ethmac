ETH_DIR:=.

include ./config.mk

#
# SIMULATE RTL
#

sim-build:
	make -C $(ETH_SIM_DIR) build

sim-run: sim-build
	make -C $(ETH_SIM_DIR) run

sim-clean:
	make -C $(ETH_SIM_DIR) clean

sim: sim-run sim-clean

#
# BUILD TARGETS
#
build-ethernet:
	cd hardware && \
	  ethernet_gen iob_mii.yml


.PHONY: sim-build sim-run sim-clean sim