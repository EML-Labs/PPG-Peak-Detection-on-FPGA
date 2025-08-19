PROJ = AND_gate
TB = tb_$(PROJ)
CC = ghdl
VT = gtkwave

VHDL_FILES = $(PROJ).vhd $(TB).vhd

all: $(TB)

$(TB): $(VHDL_FILES)
	$(CC) -a $(VHDL_FILES)
	$(CC) -e $(TB)

run: $(TB)
	$(CC) -r $(TB) --vcd=wave.vcd
	$(VT) --dump=wave.vcd

clean:
	rm -f *.o *.cf wave.vcd $(TB)
