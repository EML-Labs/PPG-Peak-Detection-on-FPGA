library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity peak_detector is
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           signal_in : in  STD_LOGIC_VECTOR (15 downto 0);
           peak_out : out  STD_LOGIC);
end peak_detector;

architecture Behavioral of peak_detector is 
    signal bandpass_filtered : STD_LOGIC_VECTOR (15 downto 0);
    signal absolute_value : STD_LOGIC_VECTOR (15 downto 0);
    signal moving_average_filtered : STD_LOGIC_VECTOR (15 downto 0);
    signal low_pass_filtered : STD_LOGIC_VECTOR (15 downto 0);

    component iir_filter
        Port ( 
            clk       : in  STD_LOGIC;
            rst       : in  STD_LOGIC;
            x_in      : in  signed(15 downto 0);   
            y_out     : out signed(31 downto 0)   
           );
    end component;

    component absolute_value
        Port (
            clk    : in  STD_LOGIC;
            rst    : in  STD_LOGIC;
            x_in   : in  signed(15 downto 0);   
            y_out  : out signed(15 downto 0)   
        );
    end component;

    component moving_average
        Port (
            clk    : in  STD_LOGIC;
            rst    : in  STD_LOGIC;
            x_in   : in  signed(15 downto 0);   
            y_out  : out signed(15 downto 0)    
        );
    end component;

    component low_pass_iir_filter
        Port (
            clk   : in  STD_LOGIC;
            rst   : in  STD_LOGIC;
            x_in  : in  signed(15 downto 0);   
            y_out : out signed(31 downto 0)   
        );
    end component;

    

end architecture Behavioral;


