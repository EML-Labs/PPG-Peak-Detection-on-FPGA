PIPELINE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

include $(PIPELINE_DIR)../components/sources.mk
include $(PIPELINE_DIR)../externals/sources.mk

VHDL_SYNTH_SOURCES += $(PIPELINE_DIR)pipeline.vhd
VHDL_TB_SOURCES += $(PIPELINE_DIR)tb_pipeline.vhd