-- Testbench for iir_filter
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_type_4_bandpass_filter is
end tb_type_4_bandpass_filter;

architecture Behavioral of tb_type_4_bandpass_filter is
    -- DUT signals
    signal clk    : std_logic := '0';
    signal rst    : std_logic := '0';
    signal x_in   : signed(15 downto 0) := (others => '0');
    signal y_out  : signed(15 downto 0);
    signal valid_in : std_logic := '0';
    signal valid_out : std_logic;


    -- Clock period
    constant clk_period : time := 10 ns;

begin
    -- Instantiate the DUT
    uut: entity work.type_4_bandpass_filter
        port map (
            clk    => clk,
            rst    => rst,
            x_in   => x_in,
            y_out  => y_out,
            valid_in  => valid_in,
            valid_out => valid_out
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

        -- Apply input samples
        x_in <= to_signed(0, 16);
        wait for clk_period;
        x_in <= to_signed(0, 16);
        wait for clk_period;
        x_in <= to_signed(1, 16);
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
