# iob-ethmac
This ethernet MAC repository is an adaptation of the [ethmac](https://opencores.org/projects/ethmac) from Open Cores.
(WIP)

## Requirements
- Verilator
- Icarus Verilog

## Optional
- 

# Sintax observations
Signals can have suffixes that may appear after `_` (for example, `signal_er`). The order of the letter does not matter. However, through out the files the same order should be used.
- Signals with a suffix `e` are enables.
- Signals with a suffix `m` are masks.
- Signals with a suffix `r` are registers.
- Signals with a suffix `i` are module inputs.
- Signals with a suffix `o` are module outputs.
Signals can also have prefixes.
- Signals with a prefix `s` are slave interface bus signal.
- Signals with a prefix `m` are master interface bus signal.

## Makefile Targets
- clean-all: do all of the cleaning above
