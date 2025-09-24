library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Package for array types
package filter_types is
    type x_array_type is array(0 to 4) of signed(15 downto 0);
    type y_array_type is array(1 to 4) of signed(31 downto 0);
end package;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.filter_types.all;

entity type_4_bandpass_filter is
        -- Array type definitions for delay registers

    Port ( clk       : in  STD_LOGIC;
           rst       : in  STD_LOGIC;
           x_in      : in  signed(15 downto 0);   -- input sample
           y_out     : out signed(31 downto 0);    -- output sample
           x_0     : out signed(15 downto 0);    -- debug
           x_1     : out signed(15 downto 0);    -- debug
           x_2     : out signed(15 downto 0);    -- debug
           x_3     : out signed(15 downto 0);    -- debug
           x_4     : out signed(15 downto 0);    -- debug
           y_1     : out signed(31 downto 0);    -- debug
           y_2     : out signed(31 downto 0);    -- debug
           y_3     : out signed(31 downto 0);    -- debug
           y_4     : out signed(31 downto 0)     -- debug
           );
end type_4_bandpass_filter;

architecture Behavioral of type_4_bandpass_filter
 is
    -- Coefficients in Q1.15 fixed-point
    constant b0 : signed(15 downto 0) := to_signed(19094, 16);
    constant b1 : signed(15 downto 0) := to_signed(0, 16);
    constant b2 : signed(15 downto 0) := to_signed(-38187, 16);
    constant b3 : signed(15 downto 0) := to_signed(0, 16);
    constant b4 : signed(15 downto 0) := to_signed(19094, 16);

    constant a1 : signed(15 downto 0) := to_signed(-22507, 16);
    constant a2 : signed(15 downto 0) := to_signed(-26735, 16);
    constant a3 : signed(15 downto 0) := to_signed(6359, 16);
    constant a4 : signed(15 downto 0) := to_signed(11377, 16);


    -- Delay registers
    signal x_reg : x_array_type;
    signal y_reg : y_array_type;
    signal y_out_int : signed(31 downto 0); -- internal output signal

begin
    process(clk, rst)
        variable acc    : signed(31 downto 0);
        variable y_tmp  : y_array_type; -- temporary storage
    begin
        if rst = '1' then
            x_reg     <= (others => (others => '0'));
            y_reg     <= (others => (others => '0'));
            y_out_int <= (others => '0');

        elsif rising_edge(clk) then
            -- compute output using OLD y_reg
            acc := resize(b0 * x_in, 32) +
                resize(b1 * x_reg(0), 32) +
                resize(b2 * x_reg(1), 32) +
                resize(b3 * x_reg(2), 32) +
                resize(b4 * x_reg(3), 32);

            acc := acc -
                resize(a1 * y_reg(1)(31 downto 16), 32) -
                resize(a2 * y_reg(2)(31 downto 16), 32) -
                resize(a3 * y_reg(3)(31 downto 16), 32) -
                resize(a4 * y_reg(4)(31 downto 16), 32);

            y_out_int <= acc;

            -- shift input history
            x_reg(1 to 4) <= x_reg(0 to 3);
            x_reg(0)      <= x_in;

            -- shift output history (via temporary)
            y_tmp := y_reg;   -- save old
            y_reg(2 to 4) <= y_tmp(1 to 3);
            y_reg(1)      <= acc;
        end if;
    end process;



    -- Assign internal output to port
    x_0 <= x_reg(0); -- debug outputs
    x_1 <= x_reg(1);
    x_2 <= x_reg(2);
    x_3 <= x_reg(3);
    x_4 <= x_reg(4);
    y_1 <= y_reg(1);
    y_2 <= y_reg(2);
    y_3 <= y_reg(3);
    y_4 <= y_reg(4);
    y_out <= y_out_int;
end Behavioral;
