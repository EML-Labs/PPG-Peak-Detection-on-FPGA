PROJ = pipeline
STOP_TIME = 700ns

VHDL_FILES = interface.vhd

include ../../src/pipeline/sources.mk

VHDL_FILES += $(VHDL_SYNTH_SOURCES) $(VHDL_TB_SOURCES)

include ../../scripts/Makefile.common
