library IEEE; 
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity moving_average is
    Port(
        clk    : in  STD_LOGIC;
        rst    : in  STD_LOGIC;
        x_in   : in  signed(15 downto 0);   -- input sample
        y_out  : out signed(15 downto 0)    -- output sample
    ); 
end moving_average;

architecture Behavioral of moving_average is
    constant WINDOW_SIZE : integer := 38;
    constant SCALE       : integer := 6891; -- 1/38 in Q18
    constant SHIFT_BITS  : integer := 18;

    type shift_reg_type is array (0 to WINDOW_SIZE-1) of signed(15 downto 0);
    signal shift_reg : shift_reg_type := (others => (others => '0'));

    -- 16 + ceil(log2(38)) = 22 bits
    signal acc : signed(21 downto 0) := (others => '0');

begin 
    process(clk, rst)
        variable sum : signed(21 downto 0);
    begin
        if rst = '1' then 
            shift_reg <= (others => (others => '0'));
            acc <= (others => '0');
            y_out <= (others => '0');

        elsif rising_edge(clk) then
            -- Use variable for proper sequential update
            sum := acc;

            -- Subtract oldest
            sum := sum - resize(shift_reg(WINDOW_SIZE-1), sum'length);

            -- Shift register
            for i in WINDOW_SIZE-1 downto 1 loop
                shift_reg(i) <= shift_reg(i-1);
            end loop;
            shift_reg(0) <= x_in;

            -- Add newest
            sum := sum + resize(x_in, sum'length);

            -- Update accumulator
            acc <= sum;

            -- Divide by 38 using fixed-point scaling
            y_out <= resize((sum * to_signed(SCALE, 32)) srl SHIFT_BITS, 16);
        end if;
    end process;
end architecture Behavioral;
