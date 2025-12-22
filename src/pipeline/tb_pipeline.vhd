-- Simple impulse-based testbench for pipeline
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
