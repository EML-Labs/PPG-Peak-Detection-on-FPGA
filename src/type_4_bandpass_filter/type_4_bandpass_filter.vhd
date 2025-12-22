library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity iir_filter is
    Port ( clk       : in  STD_LOGIC;
           rst       : in  STD_LOGIC;
           x_in      : in  signed(15 downto 0);   -- input sample
           y_out     : out signed(31 downto 0)    -- output sample
         );
end iir_filter;

architecture Behavioral of iir_filter is
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

    -- Array type definitions for delay registers
    type x_array_type is array(4 downto 0) of signed(15 downto 0);
    type y_array_type is array(4 downto 1) of signed(31 downto 0);
    -- Delay registers
    signal x_reg : x_array_type;
    signal y_reg : y_array_type;
    signal y_out_int : signed(31 downto 0); -- internal output signal

begin
    process(clk, rst)
        variable acc : signed(31 downto 0);
    begin
        if rst = '1' then
            x_reg <= (others => (others => '0'));
            y_reg <= (others => (others => '0'));
            y_out_int <= (others => '0');

        elsif rising_edge(clk) then
            -- shift input history
            x_reg(4 downto 1) <= x_reg(3 downto 0);
            x_reg(0) <= x_in;

            -- shift output history
            y_reg(4 downto 2) <= y_reg(3 downto 1);
            y_reg(1) <= y_out_int;

            -- compute: y[n] = Σ b*x - Σ a*y
            acc := resize(b0 * x_reg(0), 32) +
                   resize(b1 * x_reg(1), 32) +
                   resize(b2 * x_reg(2), 32) +
                   resize(b3 * x_reg(3), 32) +
                   resize(b4 * x_reg(4), 32);

            acc := acc -
                   resize(a1 * y_reg(1)(31 downto 16), 32) -
                   resize(a2 * y_reg(2)(31 downto 16), 32) -
                   resize(a3 * y_reg(3)(31 downto 16), 32) -
                   resize(a4 * y_reg(4)(31 downto 16), 32);

            y_out_int <= acc;
        end if;
    end process;

    -- Assign internal output to port
    y_out <= y_out_int;
end Behavioral;
