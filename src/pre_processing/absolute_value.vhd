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

