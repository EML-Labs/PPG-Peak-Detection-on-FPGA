library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;

entity mimic_slave is
    port (
        clk      : in  std_logic;
        reset_n  : in  std_logic;
        -- I2C physical lines (open-drain style)
        sda      : inout std_logic;
        scl      : inout std_logic;
        -- control signals (connect the same tb-level signals used for master)
        rw       : in  std_logic;  -- testbench-level rw connected to master.rw
        busy     : in  std_logic;  -- master busy (observe when transaction active)
        addr_in  : in  std_logic_vector(6 downto 0) := (others => '0')
    );
end entity;

architecture behavioral of mimic_slave is
    constant MAX_SAMPLES : integer := 20000;
    type sample_mem_t is array (0 to MAX_SAMPLES-1) of std_logic_vector(7 downto 0);
    signal samples : sample_mem_t;
    signal num_samples : integer := 0;

    -- drive signal for open-drain SDA
    signal sda_drive : std_logic := '1'; -- '0' to pull low, '1' to release

    -- local state for bit counting / indexing
    signal slave_bit_cnt   : integer := 7;
    signal first_byte_done : std_logic := '0';
    signal scl_prev        : std_logic := '1';
    signal sample_idx      : integer := 0;
    signal slave_data      : std_logic_vector(7 downto 0) := (others => '0');

    -- file variables for reading
    file fin : text open read_mode is "ppg_only.txt";

begin

    -- open-drain SDA mapping (release as 'Z')
    sda <= '0' when sda_drive = '0' else 'Z';

    -- Initialization: read samples from text file into memory
    init_proc: process
        variable line_v : line;
        variable r      : real;
        variable scaled : integer;
    begin
        num_samples <= 0;
        while not endfile(fin) loop
                readline(fin, line_v);
                -- read a real value from the line (file is expected to contain valid floats)
                read(line_v, r);
            -- scale to 8-bit (0..255)
            scaled := integer(r * 255.0 + 0.5);
            if scaled < 0 then
                scaled := 0;
            elsif scaled > 255 then
                scaled := 255;
            end if;
            if num_samples < MAX_SAMPLES then
                samples(num_samples) <= std_logic_vector(to_unsigned(scaled, 8));
                num_samples <= num_samples + 1;
            end if;
        end loop;
        if num_samples = 0 then
            -- default single value so slave still responds
            samples(0) <= x"00";
            num_samples <= 1;
        end if;
        wait;
    end process;

    -- Slave behaviour: drive ACK and data bits during transactions
    slave_proc : process(clk)
    begin
        if rising_edge(clk) then
            scl_prev <= scl;

            -- default: release SDA unless we actively drive
            -- (sda_drive maintained by transitions below)

            if scl_prev = '1' and scl = '0' then
                -- falling edge of SCL: prepare next drive level when bus is active
                if busy = '1' then
                    if slave_bit_cnt = -1 then
                        -- ACK cycle after address or data: respond ACK and prepare next data
                        sda_drive <= '0'; -- ACK (pull low)
                        slave_bit_cnt <= 7;
                        -- if master is reading (rw='1'), load next sample value
                        if rw = '1' then
                            slave_data <= samples(sample_idx mod num_samples);
                            sample_idx <= (sample_idx + 1) mod num_samples;
                        end if;
                        first_byte_done <= '1';
                    elsif rw = '1' then
                        -- master is reading; drive data bit if we're in data phase
                        if first_byte_done = '1' then
                            sda_drive <= slave_data(slave_bit_cnt);
                        else
                            sda_drive <= '1'; -- release during address phase
                        end if;
                        slave_bit_cnt <= slave_bit_cnt - 1;
                    else
                        -- master writing to slave: release SDA (we are not capturing writes here)
                        sda_drive <= '1';
                        slave_bit_cnt <= slave_bit_cnt - 1;
                    end if;
                end if;
            end if;

            if scl_prev = '0' and scl = '1' then
                -- rising edge: release SDA to allow ACK sampling etc.
                sda_drive <= '1';
            end if;

            if busy = '0' then
                -- transaction finished, reset counters
                first_byte_done <= '0';
                slave_bit_cnt <= 7;
            end if;
        end if;
    end process;

end architecture behavioral;