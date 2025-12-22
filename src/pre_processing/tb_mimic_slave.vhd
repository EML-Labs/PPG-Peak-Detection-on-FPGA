library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_mimic_slave is
end entity;

architecture sim of tb_mimic_slave is
    signal clk       : std_logic := '0';
    signal reset_n   : std_logic := '0';
    signal ena       : std_logic := '0';
    signal addr      : std_logic_vector(6 downto 0) := "0101010";
    signal rw        : std_logic := '1'; -- master will perform reads
    signal data_wr   : std_logic_vector(7 downto 0) := (others => '0');
    signal busy      : std_logic;
    signal data_rd   : std_logic_vector(7 downto 0);
    signal ack_error : std_logic;
    signal sda       : std_logic := 'H';
    signal scl       : std_logic := 'H';
begin

    -- Instantiate master
    master_inst : entity work.i2c_master
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

    -- Instantiate mimic slave
    slave_inst : entity work.mimic_slave
        port map(
            clk => clk,
            reset_n => reset_n,
            sda => sda,
            scl => scl,
            rw => rw,
            busy => busy,
            addr_in => addr
        );

    -- clock: 50 MHz (20 ns period)
    clk_proc : process
    begin
        while true loop
            clk <= '0';
            wait for 10 ns;
            clk <= '1';
            wait for 10 ns;
        end loop;
    end process;

    stim_proc : process
    begin
        -- apply reset
        reset_n <= '0';
        ena <= '0';
        wait for 200 ns;
        reset_n <= '1';
        wait for 200 ns;

        -- perform a few read transactions, printing received bytes
        for i in 0 to 9 loop
            -- request a read transaction
            ena <= '1';
            -- hold ena until master asserts busy (start accepted)
            wait until busy = '1' or now > 100 ms;
            ena <= '0';

            -- wait for transaction to complete
            wait until busy = '0' or now > 100 ms;

            report "Read byte " & integer'image(i) & ": 0x" & to_hstring(data_rd);
            wait for 1 us;
        end loop;

        -- finish
        report "TB finished";
        std.env.stop(0);
        wait;
    end process;

end architecture sim;
