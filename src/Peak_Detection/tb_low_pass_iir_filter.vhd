-- Testbench for low_pass_iir_filter
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_low_pass_iir_filter is
end tb_low_pass_iir_filter;

architecture Behavioral of tb_low_pass_iir_filter is
    -- DUT signals
    signal clk    : std_logic := '0';
    signal rst    : std_logic := '0';
    signal x_in   : signed(15 downto 0) := (others => '0');
    signal y_out  : signed(31 downto 0);

    -- Clock period
    constant clk_period : time := 10 ns;

begin
    -- Instantiate the DUT
    uut: entity work.low_pass_iir_filter
        port map (
            clk    => clk,
            rst    => rst,
            x_in   => x_in,
            y_out  => y_out
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
        -- Apply reset
        rst <= '1';
        wait for 2*clk_period;
        rst <= '0';
        wait for clk_period;

        -- Followed by zeros
        x_in <= to_signed(0, 16);
        wait for clk_period;
        x_in <= to_signed(0, 16);
        wait for clk_period;
        -- Impulse input in Q1.15 format (≈ 1.0 = 32767)
        x_in <= to_signed(1, 16);
        wait for clk_period;
        x_in <= to_signed(0, 16);
        wait for clk_period;
        x_in <= to_signed(0, 16);
        wait for clk_period;
        x_in <= to_signed(0, 16);
        wait for clk_period;
        x_in <= to_signed(0, 16);
        wait for 20*clk_period;

        -- End simulation
        wait;
    end process;
end Behavioral;