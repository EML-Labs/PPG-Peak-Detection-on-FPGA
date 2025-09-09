library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity low_pass_iir_filter is
    Port ( clk   : in  STD_LOGIC;
           rst   : in  STD_LOGIC;
           x_in  : in  signed(15 downto 0);   -- input sample (Q1.15)
           y_out : out signed(31 downto 0)    -- output sample (Q1.15 in 32-bit container)
         );
end low_pass_iir_filter;

architecture Behavioral of low_pass_iir_filter is
    -- Coefficients in Q1.15 format (scaled by 32768)
    constant b0 : signed(15 downto 0) := to_signed(1937, 16);
    constant b1 : signed(15 downto 0) := to_signed(1937, 16);
    constant a1 : signed(15 downto 0) := to_signed(-28888, 16); -- note: already negative

    -- Input delay line (x[n], x[n-1])
    type x_array_type is array(1 downto 0) of signed(15 downto 0);
    signal x_reg : x_array_type := (others => (others => '0'));

    -- Output delay line (y[n-1]) – only one past value needed
    signal y_reg : signed(31 downto 0) := (others => '0');

    -- Internal output
    signal y_out_int : signed(31 downto 0) := (others => '0');

begin
    process(clk, rst)
        variable acc : signed(31 downto 0);
    begin
        if rst = '1' then
            x_reg     <= (others => (others => '0'));
            y_reg     <= (others => '0');
            y_out_int <= (others => '0');

        elsif rising_edge(clk) then
            -- shift input history
            x_reg(1) <= x_reg(0);
            x_reg(0) <= x_in;

            -- difference equation:
            -- y[n] = b0*x[n] + b1*x[n-1] + a1*y[n-1]

            acc := resize(b0 * x_reg(0), 32) +
                   resize(b1 * x_reg(1), 32) +
                   resize(a1 * resize(y_reg(31 downto 16), 16), 32);

            -- update output history
            y_reg <= acc;

            -- output
            y_out_int <= acc;
        end if;
    end process;

    y_out <= y_out_int;
end Behavioral;
