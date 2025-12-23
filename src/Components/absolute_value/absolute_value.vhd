-- SPDX-License-Identifier: CC-BY-4.0
-- Copyright (c) 2025 EML Labs, CSE, University of Moratuwa
-- Licensed under CC-BY 4.0: https://creativecommons.org/licenses/by/4.0/

-------------------------------------------------------------------------------
-- Research Group : EML Labs,CSE, University of Moratuwa
-- Authors        : Weijith Wimalasiri, Yasantha Niroshan,Chathuranga Hettiarachchi
-- 
-- Create Date    : 23-12-2025
-- Design Name    : Absolute Value Calculator
-- Module Name    : absolute_value.vhd
-- Project Name.  : PPG Peak Detection on FPGA
-- Target Devices : Basys3 / Artix-7
-- Tool Versions  : Vivado 2019.1
-- Description    : This module calculates the absolute value of the input sample. 
--               It processes input samples in Q1.15 format and produces output samples in Q1.15 format as well. The design
--               includes valid signal handling to indicate when the output data is valid. The module checks the sign bit
--               of the input sample and negates the value if it is negative, otherwise it passes the value through unchanged.
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

entity absolute_value is
    Port ( clk       : in  STD_LOGIC;
           rst       : in  STD_LOGIC;
           valid_in  : in  STD_LOGIC;
           x_in      : in  signed(15 downto 0);   
           valid_out : out STD_LOGIC;
           y_out     : out signed(15 downto 0)   
         );
end absolute_value;

architecture Behavioral of absolute_value is
    signal y_out_int : signed(15 downto 0); 
begin
    process(clk, rst)
    begin
        if rst = '1' then
            y_out_int <= (others => '0');
            valid_out <= '0';
        elsif rising_edge(clk) then
            if valid_in = '1' then
                if x_in(15) = '1' then 
                    y_out_int <= -x_in; 
                else
                    y_out_int <= x_in;  
                end if;
                valid_out <= '1';
            else
                valid_out <= '0';
            end if;
        end if;
    end process;                    
    y_out <= y_out_int;
end Behavioral; 

-- Copyright (c) 2025 EML Labs, CSE, University of Moratuwa
-- Licensed under CC-BY 4.0: https://creativecommons.org/licenses/by/4.0/
-- SPDX-License-Identifier: CC-BY-4.0

