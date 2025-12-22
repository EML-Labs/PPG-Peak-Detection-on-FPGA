-------------------------------------------------------------------------------
-- Research Group : EML Labs,CSE, University of Moratuwa
-- Authors        : Weijith Wimalasiri, Yasantha Niroshan,Chathuranga Hettiarachchi
-- 
-- Create Date    : 23-12-2025
-- Design Name    : Testbench for Absolute Value Calculator
-- Module Name    : tb_absolute_value.vhd
-- Project Name.  : PPG Peak Detection on FPGA
-- Target Devices : Basys3 / Artix-7
-- Tool Versions  : Vivado 2019.1
-- Description    : This testbench verifies the functionality of the Absolute Value Calculator. It applies a unity impulse
--
-- Dependencies    : None
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--   - Designed for single-channel input
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_absolute_value is
end tb_absolute_value;

architecture sim of tb_absolute_value is

    -- DUT signals
    signal clk   : std_logic := '0';
    signal rst   : std_logic := '1';
    signal valid_in  : std_logic := '0';
    signal x_in  : signed(15 downto 0) := (others => '0');
    signal valid_out : std_logic := '0';
    signal y_out : signed(15 downto 0);

    constant CLK_PERIOD : time := 10 ns;
    constant Q16_15 : integer := 32767; -- 2^15

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
    DUT: entity work.absolute_value
        port map (
            clk   => clk,
            rst   => rst,
            valid_in  => valid_in,
            x_in  => x_in,
            valid_out => valid_out,
            y_out => y_out
        );

    -- stimulus
    stim_proc: process
    begin
        -- reset
        rst <= '1';
        valid_in <= '0';
        wait for 2*CLK_PERIOD;
        rst <= '0';
        wait for CLK_PERIOD;

        
        -- Enable valid_in to process data
        valid_in <= '1';

        -- Test positive value
        x_in <= to_signed(0, 16);
        wait for CLK_PERIOD;
        -- Test negative value
        x_in <= to_signed(-1 * Q16_15, 16);
        wait for CLK_PERIOD;
        -- Test zero
        x_in <= to_signed(0, 16);
        wait for CLK_PERIOD;
        -- Test max positive
        x_in <= to_signed(1 * Q16_15, 16);
        wait for CLK_PERIOD;
        -- Test max negative
        x_in <= to_signed(-1 * Q16_15, 16);
        wait for CLK_PERIOD;
        -- Test random negative
        x_in <= to_signed(-1 * Q16_15, 16);
        wait for CLK_PERIOD;
        -- Test random positive
        x_in <= to_signed(1 * Q16_15, 16);
        wait for CLK_PERIOD;

        wait;
    end process;
end sim;
