library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_ppg_system is
end tb_ppg_system;

architecture sim of tb_ppg_system is
    constant clk_period : time := 20 ns;

    -- top-level lines
    signal clk     : std_logic := '0';
    signal reset_n : std_logic := '0';

    -- I2C physical lines
    signal sda : std_logic := 'H';
    signal scl : std_logic := 'H';

    -- bridge signals
    signal sample_valid : std_logic;
    signal sample_out   : signed(15 downto 0);
    signal peak_out     : std_logic;

    signal addr : std_logic_vector(6 downto 0) := "1010000";

    -- Dummy slave internal
    signal sda_slave_drive : std_logic := '1';
    signal slave_data      : std_logic_vector(7 downto 0) := x"20";
    signal slave_bit_cnt   : integer := 7;
    signal scl_prev        : std_logic := '1';
    signal first_byte_done : std_logic := '0';

    -- sample waveform for the slave to serve (simple sequence with a peak)
    type sample_array_t is array (natural range <>) of std_logic_vector(7 downto 0);
    constant samples : sample_array_t := (
        x"10", x"18", x"20", x"2A", x"3C", x"55", x"7F", x"55", x"3C", x"2A", x"20", x"18"
    );
    signal sample_idx : integer := 0;

begin

    clk <= not clk after clk_period / 2;

    -- instantiate bridge
    bridge: entity work.ppg_i2c_bridge
        port map (
            clk => clk,
            reset_n => reset_n,
            addr => addr,
            sda => sda,
            scl => scl,
            sample_valid => sample_valid,
            sample_out => sample_out,
            peak_out => peak_out
        );

    -- populate sda with open-drain behaviour
    sda <= '0' when sda_slave_drive = '0' else 'H';

    -- Dummy slave: drive data during read transactions
    slave_proc : process(clk)
    begin
        if rising_edge(clk) then
            scl_prev <= scl;
            -- drive scl high by default (master controls pull-down)
            scl <= 'H';

            if scl_prev = '1' and scl = '0' then
                -- on falling edge, prepare data for next bit if master is busy
                -- we cannot directly know master busy here, but we just drive bits in sequence when addressed
                if slave_bit_cnt = -1 then
                    -- ACK cycle: drive ACK (0)
                    sda_slave_drive <= '0';
                    slave_bit_cnt <= 7;
                    -- after ACK, load next sample value
                    slave_data <= samples(sample_idx);
                    sample_idx <= (sample_idx + 1) mod samples'length;
                    first_byte_done <= '1';
                else
                    -- drive next data bit
                    sda_slave_drive <= slave_data(slave_bit_cnt);
                    slave_bit_cnt <= slave_bit_cnt - 1;
                end if;
            elsif scl_prev = '0' and scl = '1' then
                -- on rising edge, release SDA
                sda_slave_drive <= '1';
            end if;
        end if;
    end process;

    -- Stimulus: reset and run for a fixed time
    stim: process
    begin
        reset_n <= '0';
        wait for 200 ns;
        reset_n <= '1';
        wait for 500 ms; -- run for a while so bridge can sample repeatedly
        report "TB finished";
        std.env.stop;
        wait;
    end process;

    -- Simple monitor
    monitor_proc: process(clk)
    begin
        if rising_edge(clk) then
            if sample_valid = '1' then
                report "Sample read: " & integer'image(to_integer(sample_out));
            end if;
            if peak_out = '1' then
                report "Peak detected at sample index=" & integer'image(sample_idx);
            end if;
        end if;
    end process;

end architecture;
