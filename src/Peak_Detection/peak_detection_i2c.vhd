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

    component i2c_master
        port(
            generic map (
            input_clk => 50_000_000,
            bus_clk   => 400_000
            )
        );
        port (
            clk       : in STD_LOGIC;
            reset_n   : in STD_LOGIC;
            ena       : in STD_LOGIC;
            addr      : in STD_LOGIC_VECTOR(6 DOWNTO 0);
            rw        : in STD_LOGIC;
            data_wr   : in STD_LOGIC_VECTOR(7 DOWNTO 0);
            busy      : out STD_LOGIC;
            data_rd   : out STD_LOGIC_VECTOR(7 DOWNTO 0);
            ack_error : out STD_LOGIC;
            sda       : inout STD_LOGIC;
            scl       : inout STD_LOGIC
        );
    end component;


    

end architecture Behavioral;


