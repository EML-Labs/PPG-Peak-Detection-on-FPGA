-- SPDX-License-Identifier: CC-BY-4.0
-- Copyright (c) 2025 EML Labs, CSE, University of Moratuwa
-- Licensed under CC-BY 4.0: https://creativecommons.org/licenses/by/4.0/

-------------------------------------------------------------------------------
-- Research Group : EML Labs,CSE, University of Moratuwa
-- Authors        : Weijith Wimalasiri, Yasantha Niroshan,Chathuranga Hettiarachchi
-- 
-- Create Date    : 23-12-2025
-- Design Name    : Testbench for Pipeline Module
-- Module Name    : tb_pipeline.vhd
-- Project Name.  : PPG Peak Detection on FPGA
-- Target Devices : Basys3 / Artix-7
-- Tool Versions  : Vivado 2019.1
-- Description    : This testbench verifies the functionality of the pipeline module for PPG peak detection. 
--                  It applies a series of test stimuli to the pipeline and monitors the output signals.
--                  The testbench includes clock generation, reset sequence, and input signal driving.
--                  It helps validate the correct operation of the pipeline stages and peak detection.
--
-- Dependencies    : None
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--   - Designed for single-channel input
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_pipeline is
end tb_pipeline;

architecture Behavioral of tb_pipeline is
	-- DUT signals
	signal clk          : std_logic := '0';
	signal rst          : std_logic := '0';
	signal valid_in     : std_logic := '0';
	signal signal_in    : signed(15 downto 0) := (others => '0');
	signal valid_out    : std_logic;
	signal peak_detected: std_logic;

	-- Clock period
	constant clk_period : time := 10 ns;
	constant Q16_15     : integer := 32767; -- 2^15

begin
	-- Instantiate the DUT
	uut: entity work.pipeline
		port map (
			clk          => clk,
			rst          => rst,
			valid_in     => valid_in,
			signal_in    => signal_in,
			peak_detected=> peak_detected,
			valid_out    => valid_out
		);

	-- Clock generation
	clk_process : process
	begin
		while now < 2 ms loop
			clk <= '0';
			wait for clk_period/2;
			clk <= '1';
			wait for clk_period/2;
		end loop;
		wait;
	end process;

	-- Stimulus process: reset then a single impulse
	stim_proc: process
	begin
		-- Apply reset
		rst <= '1';
		valid_in <= '0';
		signal_in <= (others => '0');
		wait for 3*clk_period;

		rst <= '0';
		wait for clk_period;

		-- Enable and drive impulse
		valid_in <= '1';
		signal_in <= to_signed(0, 16);
		wait for clk_period;
		signal_in <= to_signed(1*Q16_15, 16);
		wait for clk_period;
		signal_in <= to_signed(0, 16);
		wait for clk_period;

		-- Hold zeros while pipeline flushes
		signal_in <= to_signed(0, 16);
		wait for 50*clk_period;

		-- Stop driving
		valid_in <= '0';
		wait for 20*clk_period;

		-- End simulation
		wait;
	end process;

end Behavioral;
