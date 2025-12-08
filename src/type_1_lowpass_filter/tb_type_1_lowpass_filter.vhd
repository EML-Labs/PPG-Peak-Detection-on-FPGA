-- Testbench for type_1_lowpass_filter
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.ALL;

entity tb_type_1_lowpass_filter is
end tb_type_1_lowpass_filter;

architecture Behavioral of tb_type_1_lowpass_filter is
    file outfile : text open write_mode is "lowpass_output.txt";

    -- DUT signals
    signal clk    : std_logic := '0';
    signal rst    : std_logic := '0';
    signal x_in   : signed(15 downto 0) := (others => '0');
    signal y_out  : signed(15 downto 0);

    -- Optional debug signals (only if DUT exposes them)
    -- signal acc_out : signed(55 downto 0);  -- accumulator
    -- signal x_0, x_1 : signed(15 downto 0);
    -- signal y_1     : signed(15 downto 0);

    -- Clock period
    constant clk_period : time := 10 ns;
    constant sim_time   : time := 1000 ns;

begin
    -- Instantiate the DUT
    uut: entity work.type_1_lowpass_filter
        port map (
            clk    => clk,
            rst    => rst,
            x_in   => x_in,
            y_out  => y_out
            -- Uncomment and connect these only if available in DUT
            -- , acc_out => acc_out
            -- , x_0 => x_0
            -- , x_1 => x_1
            -- , y_1 => y_1
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

        -- Impulse input sequence
        x_in <= to_signed(0, 16);
        wait for clk_period;
        x_in <= to_signed(32767, 16); -- impulse
        wait for clk_period;
        x_in <= to_signed(0, 16);

        -- Keep zeros for the rest of the sim
        wait for 100*clk_period;

        wait;
    end process;

    -- Output logging
    write_proc: process(clk)
        variable L : line;
        variable float_val : real;
    begin
        if rising_edge(clk) then
            write(L, string'("x_in = "));
            write(L, integer(to_integer(x_in)));
            write(L, string'("; y_out = "));
            write(L, integer(to_integer(y_out)));

            float_val := real(to_integer(y_out)) / 32768.0;
            write(L, string'("; y_out (float) = "));
            write(L, float_val);

            -- Uncomment if DUT has acc_out
            -- write(L, string'("; acc = "));
            -- write(L, integer(to_integer(acc_out(55 downto 24))));

            writeline(outfile, L);
        end if;
    end process;

end Behavioral;
