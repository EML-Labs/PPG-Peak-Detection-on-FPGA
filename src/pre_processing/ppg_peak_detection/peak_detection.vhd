library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity peak_detection is
    Port ( clk        : in  STD_LOGIC;
           rst        : in  STD_LOGIC;
           valid_in   : in  STD_LOGIC;
           x_in       : in  signed(15 downto 0);

           -- intermediate filter outputs
           bp_y_out      : out signed(15 downto 0);
           abs_y_out     : out signed(15 downto 0);
           ma_y_out      : out signed(15 downto 0);
           lp_y_out      : out signed(15 downto 0);

        y_out      : out signed(15 downto 0);
        peak_detected  : out std_logic;
        valid_out  : out STD_LOGIC
         );
end peak_detection;


architecture rtl of peak_detection is
    signal bp_y_s, abs_y_s, ma_y_s, lp_y_s : signed(15 downto 0);
    signal valid_bp    : std_logic;
    signal valid_abs   : std_logic;
    signal valid_lp    : std_logic;
    signal valid_ma    : std_logic;
    signal valid_pd    : std_logic;

    begin 
        bp_instance: entity work.type_4_bandpass_filter
            port map (
                clk       => clk,
                rst       => rst,
                valid_in  => '1',
                x_in      => x_in,
                valid_out => valid_bp,
                y_out     => bp_y_s
            );
        abs_instance: entity work.absolute_value
            port map (
                clk       => clk,
                rst       => rst,
                valid_in  => valid_bp,
                x_in      => bp_y_s,
                valid_out => valid_abs,
                y_out     => abs_y_s
            );

        ma_instance: entity work.moving_average_filter
            port map (
                clk       => clk,
                rst       => rst,
                valid_in  => valid_abs,
                x_in      => abs_y_s,
                valid_out => valid_ma,
                y_out     => ma_y_s
                -- sum_debug => open  -- Optional debug output, not used
            );

        lp_instance: entity work.type_1_lowpass_filter
            port map (
                clk       => clk,
                rst       => rst,
                valid_in  => valid_ma,
                x_in      => ma_y_s,
                valid_out => valid_lp,
                y_out     => lp_y_s
            );
        
        pd_instance: entity work.peak_detector
            port map (
                clk        => clk,
                rst        => rst,
                valid_in   => valid_lp,
                x_in       => lp_y_s,
                valid_out  => valid_pd,
                peak_detected  => peak_detected
            );
        bp_y_out  <= bp_y_s;
        abs_y_out <= abs_y_s;
        ma_y_out  <= ma_y_s;
        lp_y_out  <= lp_y_s;
        y_out     <= lp_y_s;
        valid_out <= valid_pd;
end rtl;
