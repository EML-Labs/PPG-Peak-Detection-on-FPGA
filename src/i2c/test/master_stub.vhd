library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Simple behavioral stub for i2c_master used by TBs when the full
-- implementation is not compiled. It exposes the same ports but only
-- models busy/read behavior deterministically.
entity i2c_master is
  generic(
    input_clk : integer := 50_000_000;
    bus_clk   : integer := 400_000
  );
  port(
    clk       : in  std_logic;
    reset_n   : in  std_logic;
    ena       : in  std_logic;
    addr      : in  std_logic_vector(6 downto 0);
    rw        : in  std_logic;
    data_wr   : in  std_logic_vector(7 downto 0);
    busy      : out std_logic;
    data_rd   : out std_logic_vector(7 downto 0);
    ack_error : buffer std_logic;
    sda       : inout std_logic;
    scl       : inout std_logic
  );
end entity;

architecture behavioral of i2c_master is
  constant CYCLES_BUSY : integer := 1000;
  signal busy_cnt : integer := 0;
  signal active : std_logic := '0';
begin

  -- Tri-state lines left released in this stub
  sda <= 'Z';
  scl <= 'Z';

  process(clk, reset_n)
  begin
    if reset_n = '0' then
      busy <= '0';
      data_rd <= (others => '0');
      ack_error <= '0';
      busy_cnt <= 0;
      active <= '0';
    elsif rising_edge(clk) then
      if ena = '1' and active = '0' then
        active <= '1';
        busy <= '1';
        busy_cnt <= CYCLES_BUSY;
        ack_error <= '0';
        report "stub: transaction started";
      elsif active = '1' then
        if busy_cnt > 0 then
          busy_cnt <= busy_cnt - 1;
          if busy_cnt = 1 then
            report "stub: busy about to deassert";
          end if;
        else
          busy <= '0';
          active <= '0';
          report "stub: transaction completed";
          if rw = '1' then
            -- deterministic read value based on address (addr + 85) mod 256
            data_rd <= std_logic_vector(to_unsigned((to_integer(unsigned(addr)) + 85) mod 256, 8));
            report "stub: produced read data";
          else
            data_rd <= (others => '0');
            report "stub: write transaction finished";
          end if;
        end if;
      end if;
    end if;
  end process;

end architecture behavioral;
