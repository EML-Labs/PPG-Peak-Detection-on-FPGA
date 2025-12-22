PROJ = master
TB = tb_$(PROJ)
CC = ghdl
VT = gtkwave

VHDL_FILES = $(PROJ).vhd $(TB).vhd

all: $(TB)

$(TB): $(VHDL_FILES)
	$(CC) -a -fsynopsys $(VHDL_FILES) 
	$(CC) -e -fsynopsys $(TB)

run: $(TB)
	$(CC) -r $(TB) --vcd=$(PROJ).vcd --stop-time=2us
	$(VT) --dump=$(PROJ).vcd 

clean:
	rm -f *.o *.cf $(PROJ).vcd $(TB)