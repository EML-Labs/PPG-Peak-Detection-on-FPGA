library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity peak_detector is
    Port(
        clk         : in  std_logic;
        rst         : in  std_logic;
        valid_in    : in  std_logic;              
        x_in        : in  signed(15 downto 0);    
        valid_out   : out std_logic;                  
        peak_detected  : out std_logic       
    );
end peak_detector;

architecture Behavioral of peak_detector is

    signal x_prev1, x_prev2      : signed(15 downto 0) := (others => '0');
    signal peak_detected_local   : std_logic := '0';
    signal counter               : integer range 0 to 1000 := 50;

begin
    process(clk, rst)
    begin
        if rst = '1' then
            x_prev1      <= (others => '0');
            x_prev2      <= (others => '0');
            peak_detected <= '0';
            counter      <= 50;

        elsif rising_edge(clk) then
            if valid_in = '1' then

                -- shift samples
                x_prev2 <= x_prev1;
                x_prev1 <= x_in;

                -- detect peak at middle sample
                if (x_prev1 > x_prev2) and (x_prev1 > x_in) then
                    peak_detected_local <= '1';
                else
                    peak_detected_local <= '0';
                end if;

                -- time validation
                if (peak_detected_local = '1') and (counter >= 50) then
                    peak_detected <= '1';
                    counter      <= 0;
                else
                    peak_detected <= '0';
                    counter <= counter + 1;
                end if;
                valid_out <= '1';
            else
                valid_out <= '0';
            end if;
        end if;
    end process;
end Behavioral;
