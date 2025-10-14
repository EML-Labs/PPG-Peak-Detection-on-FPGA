library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_preprocessing_pipeline is
end tb_preprocessing_pipeline;

architecture sim of tb_preprocessing_pipeline is
    signal clk        : STD_LOGIC := '0';
    signal rst        : STD_LOGIC := '0';
    signal x_in       : signed(15 downto 0) := (others => '0');
    signal y_out      : signed(15 downto 0);
    signal valid_out  : STD_LOGIC;

    constant clk_period : time := 10 ns;

begin
    -- Instantiate the Unit Under Test (UUT)
    uut: entity work.preprocessing_pipeline
        port map (
            clk        => clk,
            rst        => rst,
            x_in       => x_in,
            y_out      => y_out,
            valid_out  => valid_out
        );

    -- Clock generation
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
    end process;

    -- Stimulus process
    stim_process : process
    begin
        -- Reset the system
        rst <= '1';
        wait for clk_period;
        rst <= '0';

        -- Apply test vectors
        x_in <= to_signed(1000, 16);
        wait for clk_period;

        x_in <= to_signed(-2000, 16);
        wait for clk_period;

        x_in <= to_signed(3000, 16);
        wait for clk_period;

        x_in <= to_signed(1500, 16);
        wait for clk_period;

        -- Feed zeros afterwards
        for i in 0 to 20 loop
            x_in <= to_signed(0, 16);
            wait for clk_period;
        end loop;

        -- Finish simulation
        wait;
    end process;

end sim;
