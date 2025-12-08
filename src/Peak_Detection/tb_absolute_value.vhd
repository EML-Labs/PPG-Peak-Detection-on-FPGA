library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_absolute_value is
end tb_absolute_value;

architecture sim of tb_absolute_value is
    -- DUT component declaration
    component absolute_value is
        Port (
            clk    : in  STD_LOGIC;
            rst    : in  STD_LOGIC;
            x_in   : in  signed(15 downto 0);
            y_out  : out signed(15 downto 0)
        );
    end component;

    -- signals
    signal clk   : std_logic := '0';
    signal rst   : std_logic := '1';
    signal x_in  : signed(15 downto 0) := (others => '0');
    signal y_out : signed(15 downto 0);

    constant CLK_PERIOD : time := 10 ns;

begin
    -- clock generation
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
    end process;

    -- instantiate DUT
    DUT: absolute_value
        port map (
            clk   => clk,
            rst   => rst,
            x_in  => x_in,
            y_out => y_out
        );

    -- stimulus
    stim_proc: process
    begin
        -- reset
        rst <= '1';
        wait for 2*CLK_PERIOD;
        rst <= '0';
        wait for CLK_PERIOD;

        -- Test positive value
        x_in <= to_signed(0, 16);
        wait for CLK_PERIOD;
        -- Test negative value
        x_in <= to_signed(-1, 16);
        wait for CLK_PERIOD;
        -- Test zero
        x_in <= to_signed(0, 16);
        wait for CLK_PERIOD;
        -- Test max positive
        x_in <= to_signed(1, 16);
        wait for CLK_PERIOD;
        -- Test max negative
        x_in <= to_signed(-1, 16);
        wait for CLK_PERIOD;
        -- Test random negative
        x_in <= to_signed(-1, 16);
        wait for CLK_PERIOD;
        -- Test random positive
        x_in <= to_signed(1, 16);
        wait for CLK_PERIOD;

        wait;
    end process;
end sim;
