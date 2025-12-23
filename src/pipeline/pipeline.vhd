-- SPDX-License-Identifier: CC-BY-4.0
-- Copyright (c) 2025 EML Labs, CSE, University of Moratuwa
-- Licensed under CC-BY 4.0: https://creativecommons.org/licenses/by/4.0/

-------------------------------------------------------------------------------
-- Research Group : EML Labs,CSE, University of Moratuwa
-- Authors        : Weijith Wimalasiri, Yasantha Niroshan,Chathuranga Hettiarachchi
-- 
-- Create Date    : 23-12-2025
-- Design Name    : Pipeline for PPG Peak Detection
-- Module Name    : pipeline.vhd
-- Project Name.  : PPG Peak Detection on FPGA
-- Target Devices : Basys3 / Artix-7
-- Tool Versions  : Vivado 2019.1
-- Description    : This module implements a processing pipeline for PPG peak detection. 
--                  It consists of a series of processing stages including a band-pass filter,
--                  absolute value calculation, moving average filter, low-pass filter, and 
--                  peak detection. Each stage processes the input signal sequentially to extract
--                  relevant features for peak detection.
--
-- Dependencies    : None
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--   - Designed for single-channel input
-------------------------------------------------------------------------------

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
