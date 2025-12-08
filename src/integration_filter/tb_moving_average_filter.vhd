library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.ALL;

entity tb_moving_average_filter is
end tb_moving_average_filter;

architecture sim of tb_moving_average_filter is
    file outfile : text open write_mode is "moving_average_output.txt";
    
    signal clk   : std_logic := '0';
    signal rst   : std_logic := '1';
    signal x_in  : signed(15 downto 0) := (others => '0');
    signal y_out : signed(15 downto 0);
    signal sum_debug : signed(15 downto 0);
    
    -- Signals to store previous cycle values
    signal prev_x_in  : signed(15 downto 0) := (others => '0');

    constant CLK_PERIOD : time := 10 ns;
begin
    -- DUT
    uut: entity work.moving_average_filter
        port map (
            clk   => clk,
            rst   => rst,
            x_in  => x_in,
            y_out => y_out,
            sum_debug => sum_debug
        );

    -- Clock generator
    clk_process : process
    begin
        loop
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
    end process;

    -- Stimulus
    stim_proc : process
    begin
        wait for 5*CLK_PERIOD;
        rst <= '0';
        for i in 1 to 100 loop
            x_in <= to_signed(i, 16);
            wait for CLK_PERIOD;
        end loop;
        wait;
    end process;
    
    -- Store previous input value
    sync_proc: process(clk)
    begin
        if rising_edge(clk) then
            prev_x_in <= x_in;
        end if;
    end process;
    
    -- Output logging
    write_proc: process(clk)
        variable L : line;
    begin
        if rising_edge(clk) and rst = '0' then
            -- Skip writing during the first few cycles when outputs aren't valid
            if to_integer(prev_x_in) > 0 then
                write(L, string'("x_in = "));
                write(L, integer(to_integer(prev_x_in))); -- Use previous input
                write(L, string'("; y_out = "));
                write(L, integer(to_integer(y_out)));
                
                -- Write sum_debug value (equivalent to acc in your bandpass filter)
                write(L, string'("; sum = "));
                write(L, integer(to_integer(sum_debug)));
            
                writeline(outfile, L);
            end if;
        end if;
    end process;
end architecture sim;
