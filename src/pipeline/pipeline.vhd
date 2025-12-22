library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pipeline is
    Port (
        clk       : in  STD_LOGIC;
        rst       : in  STD_LOGIC;
        valid_in  : in  STD_LOGIC;
        signal_in : in  signed(15 downto 0);     -- Q1.15 input
        peak_detected  : out STD_LOGIC;
        valid_out : out STD_LOGIC
    );
end pipeline;

architecture Behavioral of pipeline is 

    signal bandpass_filtered        : signed(15 downto 0);
    signal abs_value                : signed(15 downto 0);
    signal moving_average_filtered  : signed(15 downto 0);
    signal low_pass_filtered        : signed(15 downto 0);

    signal bandpass_valid_out : std_logic;
    signal abs_valid_out      : std_logic;
    signal ma_valid_out       : std_logic;
    signal lp_valid_out       : std_logic;

begin
    ------------------------------------------------------------------
    -- Band-pass filter
    ------------------------------------------------------------------
    bp_inst : entity work.type_4_bandpass_filter
        port map (
            clk   => clk,
            rst   => rst,
            x_in  => signal_in,
            y_out => bandpass_filtered,
            valid_in  => valid_in,
            valid_out => bandpass_valid_out
        );

    ------------------------------------------------------------------
    -- Absolute value
    ------------------------------------------------------------------
    abs_inst : entity work.absolute_value
        port map (
            clk   => clk,
            rst   => rst,
            x_in  => bandpass_filtered,
            y_out => abs_value,
            valid_in  => bandpass_valid_out,
            valid_out => abs_valid_out
        );

    ------------------------------------------------------------------
    -- Moving average
    ------------------------------------------------------------------
    ma_inst : entity work.moving_average_filter
        port map (
            clk   => clk,
            rst   => rst,
            x_in  => abs_value,
            y_out => moving_average_filtered,
            valid_in  => abs_valid_out,
            valid_out => ma_valid_out
        );

    ------------------------------------------------------------------
    -- Low-pass filter
    ------------------------------------------------------------------
    lp_inst : entity work.type_1_lowpass_filter
        port map (
            clk   => clk,
            rst   => rst,
            x_in  => moving_average_filtered,
            y_out => low_pass_filtered,
            valid_in  => ma_valid_out,
            valid_out => lp_valid_out
        );

    ------------------------------------------------------------------
    -- Peak detection 
    ------------------------------------------------------------------
    peak_detector_inst : entity work.peak_detector
        port map (
            clk           => clk,
            rst           => rst,
            x_in          => low_pass_filtered,
            valid_out     => valid_out,
            valid_in      => lp_valid_out,
            peak_detected => peak_detected
        );
        
end Behavioral;
