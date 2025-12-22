library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_divider is
end entity;

architecture sim of tb_divider is
  -- Clock parameters (match master defaults)
  constant CLK_PERIOD : time := 20 ns; -- 50 MHz
  constant INPUT_CLK  : integer := 50_000_000;
  constant BUS_CLK    : integer := 400_000;

  -- DUT signals
  signal clk      : std_logic := '0';
  signal reset_n  : std_logic := '0';
  signal ena      : std_logic := '0';
  signal addr     : std_logic_vector(6 downto 0) := (others => '0');
  signal rw       : std_logic := '0';
  signal data_wr  : std_logic_vector(7 downto 0) := (others => '0');
  signal busy     : std_logic;
  signal data_rd  : std_logic_vector(7 downto 0);
  signal ack_error: std_logic;
  signal sda      : std_logic := 'Z';
  signal scl      : std_logic := 'Z';

begin

  -- Instantiate the real master under test
  uut: entity work.i2c_master
    port map(
      clk => clk,
      reset_n => reset_n,
      ena => ena,
      addr => addr,
      rw => rw,
      data_wr => data_wr,
      busy => busy,
      data_rd => data_rd,
      ack_error => ack_error,
      sda => sda,
      scl => scl
    );

  -- Clock generator
  clk_proc: process
  begin
    while now < 100 ms loop
      clk <= '0';
      wait for CLK_PERIOD/2;
      clk <= '1';
      wait for CLK_PERIOD/2;
    end loop;
    wait;
  end process;

  -- Stimulus: reset and start a transaction to enable SCL output
  stim: process
  begin
    -- reset
    reset_n <= '0';
    ena <= '0';
    wait for 200 ns;
    reset_n <= '1';
    wait for 200 ns;

    -- ensure address/data set
    addr <= "1010000";
    data_wr <= x"00";

    -- Pulse ena to request a transaction (start SCL toggling)
    ena <= '1';
    wait for CLK_PERIOD * 4;
    ena <= '0';

    -- wait until busy starts
    wait until busy = '1';
    report "TB_DIVIDER: busy asserted, monitoring SCL";

    -- let the transaction run a bit
    wait for 5 ms;

    report "TB_DIVIDER: done monitoring";
    wait;
  end process;

  -- Monitor SCL low/high durations (in system clock cycles)
  monitor: process
    variable clk_count : integer := 0;
    variable low_start : integer := 0;
    variable low_end   : integer := 0;
    variable high_start: integer := 0;
    variable high_end  : integer := 0;
    variable low_cycles: integer := 0;
    variable high_cycles: integer := 0;
    constant expected_low : integer := (INPUT_CLK / BUS_CLK) / 2; -- expected cycles SCL is driven low
    constant tolerance : integer := 2;
  begin
    -- count system clock cycles continuously
    wait until rising_edge(clk);
    clk_count := 0;
    while now < 50 ms loop
      wait until rising_edge(clk);
      clk_count := clk_count + 1;
      -- detect SCL asserted low
      if scl = '0' then
        -- wait for transition to low (first time)
        low_start := clk_count;
        wait until scl /= '0';
        low_end := clk_count;
        low_cycles := low_end - low_start;
        report "TB_DIVIDER: measured low_cycles = " & integer'image(low_cycles);

        -- now measure high (released) duration until next low
        high_start := clk_count;
        wait until scl = '0';
        high_end := clk_count;
        high_cycles := high_end - high_start;
        report "TB_DIVIDER: measured high_cycles = " & integer'image(high_cycles);

        -- check expected value
        if abs(low_cycles - expected_low) <= tolerance then
          report "TB_DIVIDER: PASS low cycles match expected (" & integer'image(expected_low) & ")";
        else
          report "TB_DIVIDER: FAIL low cycles mismatch: expected " & integer'image(expected_low) & 
                 ", measured " & integer'image(low_cycles);
        end if;

        -- done one measurement; exit
        wait for 1 ms;
        wait;
      end if;
    end loop;
    wait;
  end process monitor;

end architecture;
