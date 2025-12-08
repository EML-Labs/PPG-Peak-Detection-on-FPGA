library IEEE; 
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.ALL;
use work.filter_types.all;

entity tb_bandpass_absolute_ma is
end tb_bandpass_absolute_ma;

architecture Behavioral of tb_bandpass_absolute_ma is
    -- Testbench signals
    signal clk       : std_logic := '0';
    signal rst       : std_logic := '0';
    signal x_in      : signed(15 downto 0) := (others => '0');
    signal y_out     : signed(15 downto 0);
    signal valid_in  : std_logic := '0';
    signal valid_out : std_logic;

    constant clk_period : time := 10 ns;
    constant sim_time   : time := 100000 ns;

begin 
    -- Instantiate the DUT
    uut: entity work.bandpass_absolute_ma
        port map (
            clk    => clk,
            rst    => rst,
            valid_in  => valid_in,
            x_in   => x_in,
            valid_out => valid_out,
            y_out  => y_out
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

    stim_proc: process
        file infile : text open read_mode is "ppg.txt";
        file outfile : text open write_mode is "filter_output.txt";
        variable L : line;
        -- variable time_val, ppg_val, ecg_val, resp_val : real;
        variable ppg_val : real;
        variable out_val : real;
        -- variable header_line : line;
        variable out_line : line;
    begin
        -- Reset
        rst <= '1';
        wait for 2*clk_period;
        rst <= '0';
        wait for clk_period;

        -- Skip header line if file is not empty
        -- if not endfile(infile) then
        --     readline(infile, header_line); -- Read and ignore header line
        -- end if;

        -- Read data from CSV file
        while not endfile(infile) loop
            readline(infile, L);
            -- read(L, time_val);
            read(L, ppg_val);
            -- report "Read PPG: " & real'image(ppg_val);
            -- read(L, ecg_val);
            -- read(L, resp_val);

            -- Apply PPG value to filter input (scaled to Q1.15)
            x_in <= to_signed(integer(ppg_val * 32767.0), 16);
            valid_in <= '1';
            
            wait until rising_edge(clk);
            
            -- Write output if valid
            if valid_out = '1' then
                -- out_val := real(to_integer(y_out)) / 32768.0; -- Convert back from Q1.15
                out_val := real(to_integer(y_out)); -- Convert back from Q1.15
                write(out_line, ppg_val);
                write(out_line, string'(","));
                write(out_line, out_val);
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