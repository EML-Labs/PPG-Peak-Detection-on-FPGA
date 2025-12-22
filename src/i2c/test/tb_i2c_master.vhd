library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;

entity tb_i2c_master is
end tb_i2c_master;

architecture sim of tb_i2c_master is
    -- DUT signals
    signal clk       : std_logic := '0';
    signal reset_n   : std_logic := '0';
    signal ena       : std_logic := '0';
    signal addr      : std_logic_vector(6 downto 0) := (others => '0');
    signal rw        : std_logic := '0';
    signal data_wr   : std_logic_vector(7 downto 0) := (others => '0');
    signal busy      : std_logic;
    signal data_rd   : std_logic_vector(7 downto 0);
    signal ack_error : std_logic;
    signal sda       : std_logic := 'Z';
    signal scl       : std_logic := 'Z';

    constant clk_period : time := 20 ns; -- 50 MHz clock for TB convenience
    constant sim_time   : time := 200 ms;
begin

    -- Instantiate DUT
    uut: entity work.i2c_master
        port map (
            clk     => clk,
            reset_n => reset_n,
            ena     => ena,
            addr    => addr,
            rw      => rw,
            data_wr => data_wr,
            busy    => busy,
            data_rd => data_rd,
            ack_error => ack_error,
            sda     => sda,
            scl     => scl
        );

    -- Clock generation
    clk_proc: process
    begin
        while now < sim_time loop
            clk <= '0';
            wait for clk_period/2;
            clk <= '1';
            wait for clk_period/2;
        end loop;
        wait;
    end process clk_proc;

    -- Stimulus process: perform a write then a read transaction and log results
    stim: process
        file out_f : text open write_mode is "i2c_tb_output.txt";
        variable L : line;
    begin
        -- reset
        reset_n <= '0';
        ena <= '0';
        wait for 200 ns;
        reset_n <= '1';
        wait for 200 ns;

        -- First transaction: WRITE to slave 0x50 with data 0xA5
        addr <= "1010000"; -- 7-bit address 0x50 (example)
        rw <= '0';
        data_wr <= x"A5";
        ena <= '1';
        wait for clk_period;
        ena <= '0';

        -- wait for transaction to start
        wait until busy = '1';
        report "Write transaction started";
        -- wait for transaction to complete
        wait until busy = '0';
        report "Write transaction completed";

        -- Log results
        write(L, string'("WRITE, addr=0x"));
        write(L, integer'image(to_integer(unsigned(addr))));
        write(L, string'(", data_wr=0x"));
        write(L, integer'image(to_integer(unsigned(data_wr))));
        write(L, string'(", ack_error="));
        if ack_error = '1' then
            write(L, string'("1"));
        else
            write(L, string'("0"));
        end if;
        writeline(out_f, L);

        wait for 1 ms;

        -- Second transaction: READ from slave 0x50
        addr <= "1010000";
        rw <= '1';
        data_wr <= (others => '0');
        ena <= '1';
        wait for clk_period;
        ena <= '0';

        wait until busy = '1';
        report "Read transaction started";
        wait until busy = '0';
        report "Read transaction completed";

        -- Log read results
        write(L, string'("READ, addr=0x"));
        write(L, integer'image(to_integer(unsigned(addr))));
        write(L, string'(", data_rd=0x"));
        write(L, integer'image(to_integer(unsigned(data_rd))));
        write(L, string'(", ack_error="));
        if ack_error = '1' then
            write(L, string'("1"));
        else
            write(L, string'("0"));
        end if;
        writeline(out_f, L);

        -- End simulation
        wait for 2 ms;
        report "End of TB";
        wait;
    end process stim;

end sim;
