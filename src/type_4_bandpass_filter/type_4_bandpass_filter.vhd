library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Package for array types
package filter_types is
    type x_array_type is array(0 to 4) of signed(15 downto 0);
    type y_array_type is array(1 to 4) of signed(15 downto 0);
end package;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.filter_types.all;

entity type_4_bandpass_filter is
    Port (
        clk   : in  STD_LOGIC;
        rst   : in  STD_LOGIC;
        x_in  : in  signed(15 downto 0);     -- Q1.15 input
        y_out : out signed(15 downto 0);     -- Q1.15 output (extended to 32 bits)

        -- Debug ports
        acc_out                 : out signed(55 downto 0);
        x_0, x_1, x_2, x_3, x_4 : out signed(15 downto 0);
        y_1, y_2, y_3, y_4      : out signed(15 downto 0);
        a1_mult_result          : out signed(47 downto 0)
    );
end type_4_bandpass_filter;

architecture Behavioral of type_4_bandpass_filter is

    -- Coefficients in Q2.30 fixed-point
    constant b0 : signed(31 downto 0) := to_signed(625451352, 32);
    constant b1 : signed(31 downto 0) := to_signed(0, 32);
    constant b2 : signed(31 downto 0) := to_signed(-1251168932, 32);
    constant b3 : signed(31 downto 0) := to_signed(0, 32);
    constant b4 : signed(31 downto 0) := to_signed(625451352, 32);

    constant a1 : signed(31 downto 0) := to_signed(-737915354, 32);
    constant a2 : signed(31 downto 0) := to_signed(-875560496, 32);
    constant a3 : signed(31 downto 0) := to_signed(208097889, 32);
    constant a4 : signed(31 downto 0) := to_signed(373198311, 32);

    -- Delay registers
    signal x_reg : x_array_type;
    signal y_reg : y_array_type;

    signal y_out_int : signed(15 downto 0);
    signal acc_out_int : signed(55 downto 0);
    signal a1_mult_result_int : signed(47 downto 0);

begin

    process(clk, rst)
        variable acc  : signed(55 downto 0);  -- wide accumulator
        variable mult : signed(47 downto 0);  -- 16x32 multiplication
    begin
        if rst = '1' then
            x_reg       <= (others => (others => '0'));
            y_reg       <= (others => (others => '0'));
            y_out_int   <= (others => '0');
            acc_out_int <= (others => '0');
            a1_mult_result_int <= (others => '0');
            
        elsif rising_edge(clk) then
            -- Reset accumulator
            acc := (others => '0');

            -- Feedforward (b coefficients * inputs)
            mult := b0 * x_in;
            acc := acc + resize(mult, 56);
            
            mult := b1 * x_reg(0);
            acc := acc + resize(mult, 56);

            mult := b2 * x_reg(1);
            acc := acc + resize(mult, 56);

            mult := b3 * x_reg(2);
            acc := acc + resize(mult, 56);

            mult := b4 * x_reg(3);
            acc := acc + resize(mult, 56);

            -- Feedback (a coefficients * outputs)
            mult := a1 * y_reg(1);
            a1_mult_result_int <= mult;
            acc := acc - resize(mult, 56);

            mult := a2 * y_reg(2);
            acc := acc - resize(mult, 56);

            mult := a3 * y_reg(3);
            acc := acc - resize(mult, 56);

            mult := a4 * y_reg(4);
            acc := acc - resize(mult, 56);

            acc_out_int <= acc;

            -- Normalize back to Q1.15 (shift right by 30)
            y_out_int <= resize(shift_right(acc, 30), 16);

            -- Update delay lines
            x_reg(1 to 4) <= x_reg(0 to 3);
            x_reg(0)      <= x_in;

            y_reg(2 to 4) <= y_reg(1 to 3);
            y_reg(1)      <= resize(shift_right(acc, 30), 16);
        end if;
    end process;

    -- Debug assignments
    x_0 <= x_reg(0);
    x_1 <= x_reg(1);
    x_2 <= x_reg(2);
    x_3 <= x_reg(3);
    x_4 <= x_reg(4);

    y_1 <= y_reg(1);
    y_2 <= y_reg(2);
    y_3 <= y_reg(3);
    y_4 <= y_reg(4);

    y_out <= y_out_int;

    acc_out <= acc_out_int;

    a1_mult_result <= a1_mult_result_int;

end Behavioral;
