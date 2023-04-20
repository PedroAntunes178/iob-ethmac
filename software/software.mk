include $(UART16550_DIR)/config.mk

UART16550_SW_DIR:=$(UART16550_DIR)/software

#include
INCLUDE+=-I$(UART16550_SW_DIR)

#headers
HDR+=$(wildcard $(UART16550_SW_DIR)/*.h)

#sources
SRC+=$(UART16550_SW_DIR)/iob-uart.c
