#DEFINES

#default freq and real time clock freq for simulation
BAUD ?=5000000
FREQ ?=100000000

#define for testbench
DEFINE+=$(defmacro)BAUD=$(BAUD)
DEFINE+=$(defmacro)FREQ=$(FREQ)

#produce waveform dump
VCD ?=0

ifeq ($(VCD),1)
DEFINE+=$(defmacro)VCD
endif

include $(ETH_DIR)/hardware/hardware.mk
include $(MEM_DIR)/hardware/ram/iob_ram_sp_be/hardware.mk

#define macros
DEFINE+=$(defmacro)DATA_W=$(DATA_W)
DEFINE+=$(defmacro)ADDR_W=$(ADDR_W)
DEFINE+=$(defmacro)N_CORES=$(N_CORES)

#testbench sources
VSRC+=$(wildcard $(ETH_DIR)/hardware/simulation/common/eth_oc/*.v)  
VSRC+=$(ETH_DIR)/hardware/simulation/common/iob_ethmac_sim_wrapper.v 

INCLUDE+=$(incdir)$(ETH_DIR)/hardware/simulation/common/eth_oc/

# TEST FILE (Contains frame to transfer)
TEST_FILE = $(ETH_DIR)/hardware/simulation/common/test.txt
TEST_FILE_HEX = test.hex

$(TEST_FILE_HEX): $(TEST_FILE)
	$(LIB_DIR)/software/python/makehex.py $(TEST_FILE) 13 > $(TEST_FILE_HEX)

#RULES
build: $(VSRC) $(VHDR) $(TEST_FILE_HEX)
ifeq ($(SIM_SERVER),)
	bash -c "trap 'make kill-sim' INT TERM KILL EXIT; make comp"
else
	ssh $(SIM_SSH_FLAGS) $(SIM_USER)@$(SIM_SERVER) "if [ ! -d $(REMOTE_ETH_DIR) ]; then mkdir -p $(REMOTE_ETH_DIR); fi"
	rsync -avz --delete --force --exclude .git $(SIM_SYNC_FLAGS) $(ETH_DIR) $(SIM_USER)@$(SIM_SERVER):$(REMOTE_ETH_DIR)
	bash -c "trap 'make kill-remote-sim' INT TERM KILL; ssh $(SIM_SSH_FLAGS) $(SIM_USER)@$(SIM_SERVER) 'make -C $(REMOTE_ETH_DIR) sim-build SIMULATOR=$(SIMULATOR) INIT_MEM=$(INIT_MEM) USE_DDR=$(USE_DDR) RUN_EXTMEM=$(RUN_EXTMEM) VCD=$(VCD) TEST_LOG=\"$(TEST_LOG)\"'"
endif

run: sim
ifeq ($(VCD),1)
	if [ ! "`pgrep -u $(USER) gtkwave`" ]; then gtkwave -a ../waves.gtkw iob_ethmac.vcd; fi &
endif

sim:
ifeq ($(SIM_SERVER),)
	bash -c "make exec"
else
	ssh $(SIM_SSH_FLAGS) $(SIM_USER)@$(SIM_SERVER) "if [ ! -d $(REMOTE_ETH_DIR) ]; then mkdir -p $(REMOTE_ETH_DIR); fi"
	rsync -avz --force --exclude .git $(SIM_SYNC_FLAGS) $(ETH_DIR) $(SIM_USER)@$(SIM_SERVER):$(REMOTE_ETH_DIR)
	bash -c "ssh $(SIM_SSH_FLAGS) $(SIM_USER)@$(SIM_SERVER) 'make -C $(REMOTE_ETH_DIR) sim-run SIMULATOR=$(SIMULATOR) INIT_MEM=$(INIT_MEM) USE_DDR=$(USE_DDR) RUN_EXTMEM=$(RUN_EXTMEM) VCD=$(VCD) TEST_LOG=\"$(TEST_LOG)\"'"
ifneq ($(TEST_LOG),)
	scp $(SIM_USER)@$(SIM_SERVER):$(REMOTE_ETH_DIR)/hardware/simulation/$(SIMULATOR)/test.log $(ETH_SIM_DIR)
endif
ifeq ($(VCD),1)
	scp $(SIM_USER)@$(SIM_SERVER):$(REMOTE_ETH_DIR)/hardware/simulation/$(SIMULATOR)/*.vcd $(ETH_SIM_DIR)
endif
endif

#clean target common to all simulators
clean-remote: ethernet_hw_clean
	@rm -f iob_ethmac.vcd
ifneq ($(SIM_SERVER),)
	ssh $(SIM_SSH_FLAGS) $(SIM_USER)@$(SIM_SERVER) "if [ ! -d $(REMOTE_ETH_DIR) ]; then mkdir -p $(REMOTE_ETH_DIR); fi"
	rsync -avz --delete --force --exclude .git $(SIM_SYNC_FLAGS) $(ETH_DIR) $(SIM_USER)@$(SIM_SERVER):$(REMOTE_ETH_DIR)
	ssh $(SIM_SSH_FLAGS) $(SIM_USER)@$(SIM_SERVER) 'make -C $(REMOTE_ETH_DIR) sim-clean SIMULATOR=$(SIMULATOR)'
endif

.PRECIOUS: iob_ethmac.vcd

.PHONY: build run sim \
	kill-remote-sim clean-remote kill-sim
