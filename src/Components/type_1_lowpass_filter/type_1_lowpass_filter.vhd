-------------------------------------------------------------------------------
-- Research Group : EML Labs,CSE, University of Moratuwa
-- Authors        : Weijith Wimalasiri, Yasantha Niroshan,Chathuranga Hettiarachchi
-- 
-- Create Date    : 23-12-2025
-- Design Name    : Type-1 Lowpass Filter
-- Module Name    : type_1_lowpass_filter.vhd
-- Project Name.  : PPG Peak Detection on FPGA
-- Target Devices : Basys3 / Artix-7
-- Tool Versions  : Vivado 2019.1
-- Description    : This module implements a Type-1 Lowpass Filter. It uses a
--               Direct Form I structure to realize the filter using the given
--               coefficients. The filter processes input samples in Q1.15 format
--               and produces output samples in Q1.15 format as well. The design
--               includes valid signal handling to indicate when the output data
--               is valid. The filter coefficients are represented in Q1.15 format
--               to maintain precision during calculations. The filter uses
--               signed arithmetic for all calculations to handle both positive
--               and negative input samples.
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

entity type_1_lowpass_filter is
    Port ( clk       : in  STD_LOGIC;
           rst       : in  STD_LOGIC;
           valid_in  : in  STD_LOGIC;
           x_in      : in  signed(15 downto 0);   -- input sample (Q1.15)
           valid_out : out STD_LOGIC;
           y_out     : out signed(15 downto 0)    -- output sample (Q1.15 in 32-bit container)
         );
end type_1_lowpass_filter;

architecture Behavioral of type_1_lowpass_filter is
    -- Coefficients in Q1.15 format (scaled by 32768)
    constant b0 : signed(15 downto 0) := to_signed(1937, 16);
    constant b1 : signed(15 downto 0) := to_signed(1937, 16);
    constant a1 : signed(15 downto 0) := to_signed(-28888, 16); -- note: already negative

    -- Input delay line (x[n], x[n-1])
    type x_array_type is array(1 downto 0) of signed(15 downto 0);
    signal x_reg : signed(15 downto 0) := (others => '0');
    -- Output delay line (y[n-1]) – only one past value needed
    signal y_reg : signed(15 downto 0) := (others => '0');

begin
    process(clk, rst)
        variable acc : signed(39 downto 0);
        variable mult : signed(31 downto 0);
    begin
        if rst = '1' then
            x_reg     <= (others => '0');
            y_reg     <= (others => '0');
            y_out     <= (others => '0');
            valid_out <= '0';

        elsif rising_edge(clk) then
            if valid_in = '1' then
                acc := (others => '0');
                mult := (others => '0');

                -- difference equation:
                -- y[n] = b0*x[n] + b1*x[n-1] + a1*y[n-1]
                mult := b0 * x_in;
                acc := acc + resize(mult, 40);

                mult := b1 * x_reg;
                acc := acc + resize(mult, 40);

                mult := a1 * y_reg;
                acc := acc - resize(mult, 40);

                y_out <= resize(shift_right(acc, 15), 16);

                x_reg <= x_in;
                y_reg <= resize(shift_right(acc, 15), 16);
                
                valid_out <= '1';
            else
                valid_out <= '0';
            end if;
        end if;
    end process;

end Behavioral;
