EXT_COMPONENT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

include $(wildcard $(EXT_COMPONENT_DIR)/*/sources.mk)
