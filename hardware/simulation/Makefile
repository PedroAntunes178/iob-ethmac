ETH_DIR:=../..

include ../hardware.mk

ETHOC_SIM:=$(ETHOC_DIR)/scripts
ETHOC_SRC:=$(ETHOC_DIR)/rtl/verilog
ETHOC_SIM_SRC:=$(ETHOC_DIR)/bench/verilog

run: ethoc logs

ethoc:
	cp $(ETH_SRC_DIR)/*.v $(ETHOC_SRC)
	cp $(ETH_SIM_DIR)/*.v $(ETHOC_SIM_SRC)
	$(MAKE) -C $(ETHOC_SIM)

logs:
	cp -r $(ETHOC_DIR)/log .

clean: