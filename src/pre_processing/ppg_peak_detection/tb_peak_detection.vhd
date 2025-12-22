library IEEE; 
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.ALL;

entity tb_peak_detection is
end tb_peak_detection;

architecture Behavioral of tb_peak_detection is
    -- Testbench signals
    signal clk           : std_logic := '0';
    signal rst           : std_logic := '0';
    signal x_in          : signed(15 downto 0) := (others => '0');
    signal valid_in      : std_logic := '0';

    signal bp_y_out      : signed(15 downto 0);
    signal abs_y_out     : signed(15 downto 0);
    signal ma_y_out      : signed(15 downto 0);
    signal lp_y_out      : signed(15 downto 0);
    signal y_out         : signed(15 downto 0);
    signal valid_out     : std_logic;
    signal peak_detected : std_logic;

    constant clk_period : time := 10 ns;
    constant sim_time   : time := 10000 ns;

begin
    -- Instantiate the DUT
    uut: entity work.peak_detection
        port map (
            clk           => clk,
            rst           => rst,
            valid_in      => valid_in,
            x_in          => x_in,
            bp_y_out      => bp_y_out,
            abs_y_out     => abs_y_out,
            ma_y_out      => ma_y_out,
            lp_y_out      => lp_y_out,
            y_out         => y_out,
            valid_out     => valid_out,
            peak_detected => peak_detected
        );

    -- Clock generation
    clk_process : process
    begin
        while now < sim_time loop
            clk <= '0';
            wait for clk_period/2;
            clk <= '1';
            wait for clk_period/2;
        end loop;
        wait;
    end process;

    -- Stimulus process
    stim_proc: process
        file infile  : text open read_mode is "ppg_only.txt";
        file outfile : text open write_mode is "filter_output.txt";
        variable L       : line;
        variable out_line: line;
        variable ppg_val : real;
        variable pd_int  : integer;
    begin
        -- Reset
        rst <= '1';
        wait for 2*clk_period;
        rst <= '0';
        wait for clk_period;

        -- Read data from file
        while not endfile(infile) loop
            readline(infile, L);
            read(L, ppg_val);

            -- Apply PPG value to DUT input (Q1.15 format)
            x_in <= to_signed(integer(ppg_val * 32767.0), 16);
            valid_in <= '1';
            wait until rising_edge(clk);

            -- Write outputs
            if valid_out = '1' then
                write(out_line, ppg_val);
                write(out_line, string'(","));
                write(out_line, real(to_integer(bp_y_out)));
                write(out_line, string'(","));
                write(out_line, real(to_integer(abs_y_out)));
                write(out_line, string'(","));
                write(out_line, real(to_integer(ma_y_out)));
                write(out_line, string'(","));
                write(out_line, real(to_integer(lp_y_out)));
                write(out_line, string'(","));
                write(out_line, real(to_integer(y_out)));
                write(out_line, string'(","));
                -- Convert std_logic peak_detected to integer 0/1 and write
                if peak_detected = '1' then
                    pd_int := 1;
                else
                    pd_int := 0;
                end if;
                write(out_line, integer'image(pd_int)); -- 0/1
                writeline(outfile, out_line);
            end if;

            valid_in <= '0';
            wait for clk_period;
        end loop;

        wait for 10*clk_period;
        report "End of simulation";
        wait;
    end process;

end Behavioral;
