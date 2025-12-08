-- Testbench for iir_filter
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.ALL;
use work.filter_types.all;  -- <-- include this


entity tb_type_4_bandpass_filter is
end tb_type_4_bandpass_filter;

architecture Behavioral of tb_type_4_bandpass_filter is

    file outfile : text open write_mode is "filter_output.txt";

    -- DUT signals
    signal clk    : std_logic := '0';
    signal rst    : std_logic := '0';
    signal x_in   : signed(15 downto 0) := (others => '0');
    signal y_out  : signed(15 downto 0);
    signal acc_out : signed(55 downto 0);
    signal a1_mult_result : signed(47 downto 0);
    -- For observing internal states (optional)
    signal x_0 : signed(15 downto 0);
    signal x_1 : signed(15 downto 0);
    signal x_2 : signed(15 downto 0);
    signal x_3 : signed(15 downto 0);
    signal x_4 : signed(15 downto 0);
    signal y_1 : signed(15 downto 0);
    signal y_2 : signed(15 downto 0);
    signal y_3 : signed(15 downto 0);
    signal y_4 : signed(15 downto 0);

    -- Clock period
    constant clk_period : time := 10 ns;
    constant sim_time   : time := 1000 ns;

begin
    -- Instantiate the DUT
    uut: entity work.type_4_bandpass_filter
        port map (
            clk    => clk,
            rst    => rst,
            x_in   => x_in,
            y_out  => y_out,
            x_0    => x_0,
            x_1    => x_1,
            x_2    => x_2,
            x_3    => x_3,
            x_4    => x_4,
            y_1    => y_1,  
            y_2    => y_2,
            y_3    => y_3,
            y_4    => y_4, 
            acc_out => acc_out,
            a1_mult_result => a1_mult_result
        );

    -- Clock generation
    clk_process : process
    begin
        while now < sim_time loop
            clk <= '0';
            wait for clk_period/2;
            clk <= '1';
            wait for clk_period/2;
        end loop;
        wait; -- stop simulation after 1000 ns
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Reset
        rst <= '1';
        wait for 2*clk_period;
        rst <= '0';
        wait for clk_period;

        -- Apply input samples
        x_in <= to_signed(0, 16);
        wait for clk_period;
        x_in <= to_signed(0, 16);
        wait for clk_period;
        x_in <= to_signed(32767, 16);
        wait for clk_period;
        x_in <= to_signed(0, 16);
        wait for clk_period;
        x_in <= to_signed(0, 16);
        wait for clk_period;
        x_in <= to_signed(0, 16);
        wait for clk_period;
        x_in <= to_signed(0, 16);
        wait for 10*clk_period;
        x_in <= to_signed(0, 16);
        wait for clk_period;
        x_in <= to_signed(0, 16);
        wait for clk_period;
        x_in <= to_signed(0, 16);
        wait for clk_period;
        x_in <= to_signed(0, 16);
        wait for 10*clk_period;
        x_in <= to_signed(0, 16);
        wait for clk_period;
        x_in <= to_signed(0, 16);
        wait for clk_period;
        x_in <= to_signed(0, 16);
        wait for clk_period;
        x_in <= to_signed(0, 16);
        wait for 10*clk_period;

        wait; -- no infinite wait, sim ends with clock process
    end process;

    -- Output logging
    write_proc: process(clk)
        variable float_val : real;
        variable L : line;
    begin
        if rising_edge(clk) then
            write(L, string'("x_in = "));
            write(L, integer(to_integer(x_in)));
            write(L, string'("; y_out = "));
            write(L, integer(to_integer(y_out)));
            -- -- Convert to normalized real values
            -- float_val := real(to_integer(x_in)) / 32768.0;  -- Q1.15 -> [-1.0, +1.0)
            -- write(L, string'("; x_in (float) = "));
            -- write(L, float_val);
            write(L, string'("; acc = "));
            write(L, integer(to_integer(acc_out(55 downto 24))));
            float_val := real(to_integer(y_out)) / 32768.0; -- Q1.15 -> [-1.0, +1.0)
            write(L, string'("; y_out (float) = "));
            write(L, float_val);
        
            writeline(outfile, L);
        end if;
    end process;

end Behavioral;
