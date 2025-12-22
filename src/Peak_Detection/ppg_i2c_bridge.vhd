library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ppg_i2c_bridge is
    generic (
        READ_PERIOD_CYCLES : integer := 50000
    );
    port (
        clk       : in  std_logic;
        reset_n   : in  std_logic;
        addr      : in  std_logic_vector(6 downto 0);
        -- I2C physical lines (shared with slave in testbench)
        sda       : inout std_logic;
        scl       : inout std_logic;

        -- Sample interface
        sample_valid : out std_logic;
        sample_out   : out signed(15 downto 0);

        -- peak detector output
        peak_out     : out std_logic
    );
end entity;

architecture rtl of ppg_i2c_bridge is

    -- Instantiate i2c_master signals
    signal ena       : std_logic := '0';
    signal rw        : std_logic := '1'; -- we will issue reads
    signal data_wr   : std_logic_vector(7 downto 0) := (others => '0');
    signal busy      : std_logic;
    signal data_rd   : std_logic_vector(7 downto 0);
    signal ack_error : std_logic;

    -- sample register
    signal sample_reg : signed(15 downto 0) := (others => '0');
    signal valid_reg  : std_logic := '0';

    signal cycle_ctr : integer := READ_PERIOD_CYCLES;

    -- bridge FSM states
    type st_t is (idle, wait_busy_assert, wait_busy_deassert);
    signal state : st_t := idle;

begin

    master_inst: entity work.i2c_master
        generic map (
            input_clk => 50_000_000,
            bus_clk   => 400_000
        )
        port map (
            clk       => clk,
            reset_n   => reset_n,
            ena       => ena,
            addr      => addr,
            rw        => rw,
            data_wr   => data_wr,
            busy      => busy,
            data_rd   => data_rd,
            ack_error => ack_error,
            sda       => sda,
            scl       => scl
        );

    -- Simple peak detector instance
    pd_inst: entity work.peak_detector
        port map (
            clk => clk,
            rst => not reset_n,
            signal_in => sample_reg,
            peak_out => peak_out
        );

    -- Output assignments
    sample_out <= sample_reg;
    sample_valid <= valid_reg;

    -- Controller process: periodically trigger a read and latch the result
    controller: process(clk, reset_n)
    begin
        if reset_n = '0' then
            cycle_ctr <= READ_PERIOD_CYCLES;
            ena <= '0';
            valid_reg <= '0';
            state <= idle;
            sample_reg <= (others => '0');
        elsif rising_edge(clk) then
            valid_reg <= '0';
            case state is
                when idle =>
                    if cycle_ctr = 0 then
                        -- request a read
                        rw <= '1';
                        ena <= '1';
                        state <= wait_busy_assert;
                    else
                        cycle_ctr <= cycle_ctr - 1;
                    end if;

                when wait_busy_assert =>
                    -- hold ena until busy asserted by master
                    if busy = '1' then
                        ena <= '0';
                        state <= wait_busy_deassert;
                    end if;

                when wait_busy_deassert =>
                    if busy = '0' then
                        -- transaction complete, latch data
                        sample_reg <= signed("00000000" & data_rd);
                        valid_reg <= '1';
                        cycle_ctr <= READ_PERIOD_CYCLES;
                        state <= idle;
                    end if;
            end case;
        end if;
    end process;

end architecture;
