library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_master is
end entity;

architecture sim of tb_master is

  -- clock period
  constant CLK_PERIOD : time := 20 ns;

  constant A5_PATTERN : std_logic_vector(7 downto 0) := x"A5";
  signal tb_cycle : integer := 0;

  -- DUT signals
  signal clk        : std_logic := '0';
  signal reset_n    : std_logic := '0';
  signal ena        : std_logic := '0';
  signal addr       : std_logic_vector(6 downto 0) := "1010000";
  signal rw         : std_logic := '0'; -- write=0, read=1
  signal data_wr    : std_logic_vector(7 downto 0) := (others => '0');
  signal data_rd    : std_logic_vector(7 downto 0);
  signal busy       : std_logic;
  signal ack_error  : std_logic;

  -- I2C lines (open drain modelling)
  signal scl        : std_logic;
  signal sda        : std_logic;

  -- Slave-side signals
  signal sda_slave_drive : std_logic := 'Z';
  signal scl_slave_drive : std_logic := 'Z';

begin

  --------------------------------------------------------------------
  -- 1) Generate 50 MHz clock
  --------------------------------------------------------------------
  clk_process : process
  begin
    clk <= '0';
    wait for CLK_PERIOD/2;
    clk <= '1';
    wait for CLK_PERIOD/2;
  end process;


  process(clk)
    begin
    if rising_edge(clk) then
        tb_cycle <= tb_cycle + 1;
    end if;
   end process;



  --------------------------------------------------------------------
  -- 2) DUT instantiation
  --------------------------------------------------------------------
  uut: entity work.i2c_master
    port map(
      clk       => clk,
      reset_n   => reset_n,
      ena       => ena,
      addr      => addr,
      rw        => rw,
      data_wr   => data_wr,
      data_rd   => data_rd,
      busy      => busy,
      ack_error => ack_error,
      scl       => scl,
      sda       => sda
    );


  --------------------------------------------------------------------
  -- 3) Open-drain bus modeling
  --------------------------------------------------------------------
  -- Master drives SCL/SDA through DUT
  -- Slave can also drive via sda_slave_drive
  scl <= scl_slave_drive when scl_slave_drive /= 'Z' else 'H';
  sda <= sda_slave_drive when sda_slave_drive /= 'Z' else 'H';

  --------------------------------------------------------------------
  -- 4) Simple I2C Slave model (ACK + read byte)
  --------------------------------------------------------------------
  slave_model : process
  begin
    wait until rising_edge(scl); -- sample SDA when SCL high

    -- Detect master's address phase (9th clock = ACK)
    if busy = '1' then
      if sda = '1' then
        -- NACK? do nothing
      end if;

      -- SLAVE ACKs everything in this simple model
      if scl = '1' then
        -- During ACK cycle, drive SDA low
        sda_slave_drive <= '0';
        wait until falling_edge(scl);
        sda_slave_drive <= 'Z'; -- release after ACK
      end if;
    end if;

  end process;


  --------------------------------------------------------------------
  -- 5) Stimulus: reset, write transaction, read transaction
  --------------------------------------------------------------------
  stim : process
  begin
    ------------------------------------------------------------------
    -- Reset
    ------------------------------------------------------------------
    reset_n <= '0';
    wait for 200 ns;
    reset_n <= '1';
    wait for 200 ns;

    ------------------------------------------------------------------
    -- Test 1: Write to slave
    ------------------------------------------------------------------
    report "TEST 1: I2C WRITE operation";

    rw <= '0';                    -- write mode
    data_wr <= x"3C";            -- sample byte
    ena <= '1';
    wait for CLK_PERIOD;

    ena <= '0';                  -- pulse ena
    wait until busy = '0';

    report "Write finished. ack_error=" & std_logic'image(ack_error);

    ------------------------------------------------------------------
    -- Test 2: Read from slave
    ------------------------------------------------------------------
    report "TEST 2: I2C READ operation";

    rw <= '1';                   -- read mode
    ena <= '1';
    wait for CLK_PERIOD;
    ena <= '0';

    -- Slave returns constant data byte: 0xA5
    -- During read phase (SCL high), slave places bits
    while busy = '1' loop
      wait until rising_edge(scl);
      -- Output next bit of the read byte
      sda_slave_drive <= A5_PATTERN(7 - (tb_cycle mod 8));
      wait until falling_edge(scl);
      sda_slave_drive <= 'Z';
    end loop;

    report "Read finished. Data_read=" & integer'image(to_integer(unsigned(data_rd)));

    ------------------------------------------------------------------
    -- End simulation
    ------------------------------------------------------------------
    wait for 500 ns;
    report "Simulation finished";
    wait;
  end process;


end architecture;
