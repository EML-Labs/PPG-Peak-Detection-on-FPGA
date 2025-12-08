PROJ = bandpass_absolute_ma
TB = tb_$(PROJ)
CC = ghdl
VT = gtkwave

# Dependencies must be compiled in order
VHDL_FILES = type_4_bandpass_filter.vhd \
             absolute_value.vhd \
			 moving_average_filter.vhd \
             $(PROJ).vhd \
             $(TB).vhd

all: $(TB)

$(TB): $(VHDL_FILES)
	$(CC) -a type_4_bandpass_filter.vhd
	$(CC) -a absolute_value.vhd
	$(CC) -a moving_average_filter.vhd
	$(CC) -a $(PROJ).vhd
	$(CC) -a $(TB).vhd
	$(CC) -e $(TB)

run: $(TB)
	$(CC) -r $(TB) --vcd=$(PROJ).vcd 
	$(VT) --dump=$(PROJ).vcd 

clean:
	rm -f *.o *.cf $(PROJ).vcd $(TB)