# Template Project
This is a template project for developing FPGA-based systems using VHDL.

## How to run the simulation
1. Open a terminal and navigate to the `Template_Project` directory:
	```sh
	cd src/Template_Project
	```
2. Compile the VHDL files and run the simulation using the Makefile:
	```sh
	make run
	```
	This will compile `template.vhd` and `tb_template.vhd`, then run the testbench simulation.
3. View the simulation results in the terminal output. If you want to clean up generated files, run:
	```sh
	make clean
	```
