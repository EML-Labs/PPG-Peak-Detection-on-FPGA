library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity tb_moving_average is
end tb_moving_average;

architecture sim of tb_moving_average is
    signal clk   : std_logic := '0';
    signal rst   : std_logic := '1';
    signal x_in  : signed(15 downto 0) := (others => '0');
    signal y_out : signed(15 downto 0);

    constant CLK_PERIOD : time := 10 ns;
begin
    -- DUT
    uut: entity work.moving_average
        port map (
            clk   => clk,
            rst   => rst,
            x_in  => x_in,
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
        wait for 5*CLK_PERIOD;
        rst <= '0';
        for i in 1 to 100 loop
            x_in <= to_signed(i, 16);
            wait for CLK_PERIOD;
        end loop;
        wait;
    end process;
end architecture sim;
