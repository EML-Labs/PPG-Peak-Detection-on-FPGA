COMPONENT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

include $(wildcard $(COMPONENT_DIR)/*/sources.mk)
