library IEEE; 
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity moving_average_filter is
    Port(
        clk       : in  STD_LOGIC;
        rst       : in  STD_LOGIC;
        valid_in  : in  STD_LOGIC;
        x_in      : in  signed(15 downto 0); 
        valid_out  : out STD_LOGIC; 
        y_out      : out signed(15 downto 0)
    ); 
end moving_average_filter;

architecture Behavioral of moving_average_filter is
    constant n : integer := 30;
    constant SCALE       : signed(15 downto 0) := to_signed(1093, 16);
    constant SHIFT_BITS  : integer := 15;

    type shift_reg_type is array (0 to n-1) of signed(15 downto 0);
    signal shift_reg : shift_reg_type := (others => (others => '0'));

    -- Running sum register (40 bits to handle 16-bit samples × 38 samples + growth)
    signal running_sum : signed(31 downto 0) := (others => '0');

begin 
    process(clk, rst)
        variable new_sum : signed(running_sum'range);
        variable mult_result : signed(47 downto 0);
        variable new_y   : signed(31 downto 0);
    begin
        if rst = '1' then 
            shift_reg <= (others => (others => '0'));
            running_sum <= (others => '0');
            y_out <= (others => '0');
            valid_out <= '0';

        elsif rising_edge(clk) then
            -- Update running sum: subtract oldest sample
            if valid_in = '1' then

                new_sum := running_sum - resize(shift_reg(n-1), running_sum'length) + resize(x_in, running_sum'length);
                running_sum <= new_sum;

                mult_result := resize(new_sum * SCALE, mult_result'length);
                -- shift by SHIFT_BITS (intended fixed-point scaling), then resize to new_y width
                new_y := resize(shift_right(mult_result, SHIFT_BITS), new_y'length);
                y_out <= resize(new_y, 16);
                -- sum_debug <= new_sum;
    
                -- Shift register
                for i in n-1 downto 1 loop
                    shift_reg(i) <= shift_reg(i-1);
                end loop;
                shift_reg(0) <= x_in;
                -- Divide by 30 using fixed-point scaling
                valid_out <= '1';
            else
                valid_out <= '0';
            end if;
        end if;
    end process;
end architecture Behavioral;
