library IEEE; 
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity absolute_value is
    Port ( clk    : in  STD_LOGIC;
           rst    : in  STD_LOGIC;
           x_in   : in  signed(15 downto 0);   -- input sample
           y_out  : out signed(15 downto 0)    -- output sample
         );
end absolute_value;

architecture Behavioral of absolute_value is
    signal y_out_int : signed(15 downto 0); -- internal output signal
begin
    process(clk, rst)
    begin
        if rst = '1' then
            y_out_int <= (others => '0');
        elsif rising_edge(clk) then
            if x_in(15) = '1' then  -- if negative
                y_out_int <= -x_in; -- take two's complement
            else
                y_out_int <= x_in;  -- else pass through
            end if;
        end if;
    end process;                    
    y_out <= y_out_int;
end Behavioral; 

