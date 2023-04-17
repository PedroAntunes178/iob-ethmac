# iob-verilog-ethernet
(WIP)

## Requirements
- Verilator

## Optional
- 

# Sintax observations
Signals can have suffixes that may appear after `_` (for example, `signal_er`). The order of the letter does not matter. However, through out the files the same order should be used.
- Signals with a suffix `e` are enables.
- Signals with a suffix `m` are masks.
- Signals with a suffix `r` are registers.
- Signals with a suffix `i` are module inputs.
- Signals with a suffix `o` are module outputs.

## Makefile Targets
- clean-all: do all of the cleaning above
