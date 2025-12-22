-- Simple testbench for peak_detector
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_peak_detector is
end tb_peak_detector;

architecture Behavioral of tb_peak_detector is
    -- DUT signals
    signal clk           : std_logic := '0';
    signal rst           : std_logic := '0';
    signal x_in          : signed(15 downto 0) := (others => '0');
    signal valid_in      : std_logic := '0';
    signal y_valid       : std_logic;
    signal peak_detected : std_logic;

    -- Clock period
    constant clk_period : time := 10 ns;
    constant Q16_15 : integer := 32767; -- 2^15

begin
    -- Instantiate the DUT
    uut: entity work.peak_detector
        port map (
            clk           => clk,
            rst           => rst,
            valid_in      => valid_in,
            x_in          => x_in,
            valid_out     => y_valid,
            peak_detected => peak_detected
        );

    -- Clock generation
    clk_process : process
    begin
        while now < 1 ms loop
            clk <= '0';
            wait for clk_period/2;
            clk <= '1';
            wait for clk_period/2;
        end loop;
        wait;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Reset
        rst <= '1';
        valid_in <= '0';
        wait for 2*clk_period;
        rst <= '0';
        wait for clk_period;

        -- Enable valid_in to process data
        valid_in <= '1';

        -- Apply a simple impulse-like sequence
        x_in <= to_signed(0, 16);
        wait for clk_period;
        x_in <= to_signed(0, 16);
        wait for clk_period;
        x_in <= to_signed(1*Q16_15, 16);
        wait for clk_period;
        x_in <= to_signed(0, 16);
        wait for clk_period;
        x_in <= to_signed(0, 16);
        wait for clk_period;
        x_in <= to_signed(0, 16);
        wait for clk_period;
        x_in <= to_signed(0, 16);
        wait for 10*clk_period;

        -- End simulation
        wait;
    end process;

end Behavioral;
