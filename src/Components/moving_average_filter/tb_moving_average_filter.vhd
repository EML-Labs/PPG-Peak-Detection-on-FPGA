library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.ALL;

entity tb_moving_average_filter is
end tb_moving_average_filter;

architecture sim of tb_moving_average_filter is
    
    signal clk   : std_logic := '0';
    signal rst   : std_logic := '1';
    signal valid_in  : std_logic := '0';
    signal x_in  : signed(15 downto 0) := (others => '0');
    signal valid_out : std_logic := '0';
    signal y_out : signed(15 downto 0);
    
    -- Signals to store previous cycle values
    signal prev_x_in  : signed(15 downto 0) := (others => '0');

    constant CLK_PERIOD : time := 10 ns;
    constant Q16_15 : integer := 32767; -- 2^15

begin
    -- DUT
    uut: entity work.moving_average_filter
        port map (
            clk   => clk,
            rst   => rst,
            valid_in  => valid_in,
            x_in  => x_in,
            valid_out => valid_out,
            y_out => y_out
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

        rst <= '1';
        valid_in <= '0';
        wait for 2*CLK_PERIOD;

        rst <= '0';
        wait for CLK_PERIOD;


        for i in 1 to 100 loop
            valid_in <= '1';
            x_in <= to_signed(i * Q16_15 / 100, 16);
            wait for CLK_PERIOD;
        end loop;
        valid_in <= '0';
        wait;
    end process;
    
    -- Store previous input value
    sync_proc: process(clk)
    begin
        if rising_edge(clk) then
            prev_x_in <= x_in;
        end if;
    end process;

end architecture sim;
