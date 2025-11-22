library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_master is
end tb_master;

architecture sim of tb_master is 
    constant clk_period : time := 20 ns;

    -- DUT signals
    signal clk       : std_logic := '0'; 
    signal reset_n   : std_logic := '0';                    
    signal ena       : std_logic := '0';
    signal addr      : std_logic_vector(6 downto 0) := "1010000";
    signal rw        : std_logic := '0';                    
    signal data_wr   : std_logic_vector(7 downto 0) := (others => '0'); 
    signal busy      : std_logic;                    
    signal data_rd   : std_logic_vector(7 downto 0); 
    signal ack_error : std_logic;

    -- I2C lines (open drain modelling)
    signal sda      : std_logic := 'H';                               -- Pulled up to ensure SDA is already high
    signal scl      : std_logic := 'H';                               -- Pulled up to ensure SCL is already high

    -- Dummy slave signals
    signal sda_slave_drive : std_logic := '1';                        -- 
    signal slave_data      : std_logic_vector(7 downto 0) := x"5A";
    signal slave_bit_cnt   : integer := 7;
    signal first_byte_done : std_logic := '0';
    signal scl_prev        : std_logic := '1';
    signal sda_prev        : std_logic := '1';
    signal slave_ack_fail  : std_logic := '0';
    signal slave_stretch   : std_logic := '0';
    signal stretch_count   : integer := 0;

begin
            -- Instantiate DUT
    dut: entity work.i2c_master
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
--------------------------------------------------------------------
            -- Clock generation
--------------------------------------------------------------------
    clk <= not clk after clk_period / 2;

--------------------------------------------------------------------
            -- Dummy i2c Slave
--------------------------------------------------------------------
    sda <= '0' when sda_slave_drive = '0' else 'H';

    slave_proc : process(clk)
    begin
        if rising_edge(clk) then 
            scl_prev <= scl;
            sda_prev <= sda;

            scl <= 'H';

            -- Clock stretching (requested by stim via slave_stretch = '1')
            if slave_stretch = '1' and scl = '1' then
                if stretch_count < 10 then 
                    scl <= '0';
                    stretch_count <= stretch_count + 1;
                else
                    -- scl <= '1';
                    -- stim will clear slave_stretch after transaction
                    stretch_count <= 0;
                end if;
            end if;

            if scl_prev = '1' and scl = '0' then 
                if busy = '1' then 
                    --ACK and NACK handling
                    if slave_bit_cnt = -1 then
                        if slave_ack_fail = '1' then
                            sda_slave_drive <= '1';    -- NACK
                            -- stim will clear slave_ack_fail after the transaction
                        else
                            sda_slave_drive <= '0';    -- ACK
                        end if;
                        slave_bit_cnt <= 7;
                        -- first byte (address+R/W) completed; subsequent bytes are data bytes
                        first_byte_done <= '1';
                    elsif rw = '1' then
                        -- Only drive data bits after the address/ack cycle has completed
                        if first_byte_done = '1' then
                            sda_slave_drive <= slave_data(slave_bit_cnt);
                        else
                            -- during address phase do not drive data
                            sda_slave_drive <= '1';
                        end if;
                        slave_bit_cnt <= slave_bit_cnt - 1;
                    else
                        sda_slave_drive <= '1';       -- Release SDA for write
                        slave_bit_cnt <= slave_bit_cnt -1;
                    end if;
                end if;
            end if;

            if scl_prev = '0' and scl = '1' then
                sda_slave_drive <= '1'; -- release SDA
            end if;

            if busy = '0' then
                first_byte_done <= '0';
                slave_bit_cnt <= 7;
            end if;
        end if;
    end process;

--------------------------------------------------------------------
            -- Stimulus process
--------------------------------------------------------------------
    stim: process
        variable timeout_cnt : integer := 0;
    begin 

    ----------------------------------------------------------------
        -- Reset
    ----------------------------------------------------------------
        reset_n <= '0';
        wait for 200 ns;
        reset_n <= '1';
        wait for 200 ns;
    
    ----------------------------------------------------------------
        -- Write Transaction (Single byte)
    ----------------------------------------------------------------
        report "Single Byte Write Transaction";
        data_wr <= x"A5";
        rw <= '0';
        ena <= '1';
        -- keep ena asserted until master samples it (data_clk) and asserts busy
        for k in 0 to 200000 loop
            wait until rising_edge(clk);
            if busy = '1' then
                report "Write: busy asserted after " & integer'image(k) & " cycles";
                exit;
            end if;
            if (k mod 2000) = 0 then
                report "Write: waiting for busy to assert: k=" & integer'image(k) & " sda=" & std_logic'image(sda) & " scl=" & std_logic'image(scl);
            end if;
        end loop;
        ena <= '0';
        wait until busy = '0';
        report "Write Transaction Completed. ack_error=" & std_logic'image(ack_error);  
        wait for 100 ns; 

    ----------------------------------------------------------------
        -- Read Transaction (Single byte)
    ----------------------------------------------------------------
        report "Single Byte Read Transaction";
        rw <= '1';
        ena <= '1';
        -- keep ena asserted until master asserts busy (to align with data_clk)
        for i in 0 to 200000 loop
            wait until rising_edge(clk);
            if busy = '1' then
                report "Read: busy asserted after " & integer'image(i) & " cycles";
                exit;
            end if;
            if (i mod 2000) = 0 then
                report "Read: waiting for busy to assert: cycle=" & integer'image(i) & " sda=" & std_logic'image(sda) & " scl=" & std_logic'image(scl) & " rw=" & std_logic'image(rw);
            end if;
        end loop;
        ena <= '0';

    -- wait for transaction to finish (busy deasserted) with timeout and periodic debug
    report "Waiting for busy to deassert...";
        for j in 0 to 200000 loop
            wait until rising_edge(clk);
            if busy = '0' then
                report "busy deasserted after " & integer'image(j) & " clk cycles";
                exit;
            end if;
            if (j mod 2000) = 0 then
                report "busy still asserted: cycle=" & integer'image(j) & " sda=" & std_logic'image(sda) & " scl=" & std_logic'image(scl) & " data_rd=" & integer'image(to_integer(unsigned(data_rd))) & " slave_bit_cnt=" & integer'image(slave_bit_cnt);
            end if;
            timeout_cnt := j;
        end loop;
        if busy = '1' then
            report "ERROR: busy did not deassert within timeout (" & integer'image(timeout_cnt) & ")" severity warning;
        end if;

        report "Read Transaction Completed. data_rd=0x" & integer'image(to_integer(unsigned(data_rd))) & " ack_error=" & std_logic'image(ack_error);
        wait for 100 ns;

    ----------------------------------------------------------------
        -- NACK Handling Test
    ----------------------------------------------------------------
        report "NACK Handling Test";
        -- Request slave to NACK the next byte
        slave_ack_fail <= '1';
        data_wr <= x"FF";
        rw <= '0';

        -- Hold ena until master acknowledges the request (busy asserted)
        ena <= '1';
        report "NACK test: asserting ena and waiting for busy to assert";
        for n in 0 to 200000 loop
            wait until rising_edge(clk);
            if busy = '1' then
                report "NACK test: busy asserted after " & integer'image(n) & " cycles";
                exit;
            end if;
            if (n mod 2000) = 0 then
                report "NACK test: still waiting for busy to assert: n=" & integer'image(n) & " sda=" & std_logic'image(sda) & " scl=" & std_logic'image(scl);
            end if;
        end loop;
        ena <= '0';

        -- Wait for transaction to finish with debug
        report "NACK test: waiting for busy to deassert";
        for m in 0 to 200000 loop
            wait until rising_edge(clk);
            if busy = '0' then
                report "NACK test: busy deasserted after " & integer'image(m) & " cycles";
                exit;
            end if;
            if (m mod 2000) = 0 then
                report "NACK test: busy still asserted: m=" & integer'image(m) & " sda=" & std_logic'image(sda) & " scl=" & std_logic'image(scl) & " ack_error=" & std_logic'image(ack_error);
            end if;
        end loop;

        if ack_error = '1' then
            report "NACK correctly detected on write";
        else
            report "ERROR: NACK not detected on write";
        end if;
        -- clear the NACK request for subsequent tests
        slave_ack_fail <= '0';
        wait for 100 ns;

    ----------------------------------------------------------------
        -- Clock Stretching Test (robust)
    ----------------------------------------------------------------
        report "Clock Stretching Test";
        -- Request slave to stretch SCL during the transaction
        slave_stretch <= '1';
        data_wr <= x"55";
        rw <= '0';

        -- Hold ena until master acknowledges the request (busy asserted)
        ena <= '1';
        report "Stretch test: asserting ena and waiting for busy to assert";
        for s in 0 to 200000 loop
            wait until rising_edge(clk);
            if busy = '1' then
                report "Stretch test: busy asserted after " & integer'image(s) & " cycles";
                exit;
            end if;
            if (s mod 2000) = 0 then
                report "Stretch test: waiting for busy to assert: s=" & integer'image(s) & " sda=" & std_logic'image(sda) & " scl=" & std_logic'image(scl);
            end if;
        end loop;
        ena <= '0';

        -- Wait for transaction to finish with debug and timeout
        report "Stretch test: waiting for busy to deassert";
        for t in 0 to 200000 loop
            wait until rising_edge(clk);
            if busy = '0' then
                report "Stretch test: busy deasserted after " & integer'image(t) & " cycles";
                exit;
            end if;
            if (t mod 2000) = 0 then
                report "Stretch test: busy still asserted: t=" & integer'image(t) & " sda=" & std_logic'image(sda) & " scl=" & std_logic'image(scl) & " ack_error=" & std_logic'image(ack_error);
            end if;
        end loop;

        -- clear stretch request
        slave_stretch <= '0';
        report "Clock Stretching Write Completed.";
        wait for 100 ns;

    ----------------------------------------------------------------
        -- Multi-byte Write/Read Transaction (robust)
    ----------------------------------------------------------------
        report "Multi-byte Write/Read Test";
        -- WRITE first byte
        data_wr <= x"11";
        rw <= '0';
        ena <= '1';
        report "Multi: write1 asserting ena and waiting for busy";
        for w1 in 0 to 200000 loop
            wait until rising_edge(clk);
            if busy = '1' then
                report "Multi: write1 busy asserted after " & integer'image(w1) & " cycles";
                exit;
            end if;
            if (w1 mod 2000) = 0 then
                report "Multi: write1 waiting for busy: w1=" & integer'image(w1);
            end if;
        end loop;
        ena <= '0';
        report "Multi: write1 waiting for busy deassert";
        for w1d in 0 to 200000 loop
            wait until rising_edge(clk);
            if busy = '0' then
                report "Multi: write1 busy deasserted after " & integer'image(w1d) & " cycles";
                exit;
            end if;
        end loop;

        -- WRITE second byte
        data_wr <= x"22";
        ena <= '1';
        report "Multi: write2 asserting ena and waiting for busy";
        for w2 in 0 to 200000 loop
            wait until rising_edge(clk);
            if busy = '1' then
                report "Multi: write2 busy asserted after " & integer'image(w2) & " cycles";
                exit;
            end if;
        end loop;
        ena <= '0';
        report "Multi: write2 waiting for busy deassert";
        for w2d in 0 to 200000 loop
            wait until rising_edge(clk);
            if busy = '0' then
                report "Multi: write2 busy deasserted after " & integer'image(w2d) & " cycles";
                exit;
            end if;
        end loop;

        -- READ first byte (slave returns 0x5A)
        rw <= '1';
        ena <= '1';
        report "Multi: read1 asserting ena and waiting for busy";
        for r1 in 0 to 200000 loop
            wait until rising_edge(clk);
            if busy = '1' then
                report "Multi: read1 busy asserted after " & integer'image(r1) & " cycles";
                exit;
            end if;
        end loop;
        ena <= '0';
        report "Multi: read1 waiting for busy deassert";
        for r1d in 0 to 200000 loop
            wait until rising_edge(clk);
            if busy = '0' then
                report "Multi: read1 busy deasserted after " & integer'image(r1d) & " cycles";
                exit;
            end if;
        end loop;
        report "Read byte 1: " & integer'image(to_integer(unsigned(data_rd)));

        -- READ second byte
        ena <= '1';
        report "Multi: read2 asserting ena and waiting for busy";
        for r2 in 0 to 200000 loop
            wait until rising_edge(clk);
            if busy = '1' then
                report "Multi: read2 busy asserted after " & integer'image(r2) & " cycles";
                exit;
            end if;
        end loop;
        ena <= '0';
        report "Multi: read2 waiting for busy deassert";
        for r2d in 0 to 200000 loop
            wait until rising_edge(clk);
            if busy = '0' then
                report "Multi: read2 busy deasserted after " & integer'image(r2d) & " cycles";
                exit;
            end if;
        end loop;
        report "Read byte 2: " & integer'image(to_integer(unsigned(data_rd)));
    
    ------------------------------------------------------------------
        -- End simulation
    ------------------------------------------------------------------
        REPORT "Simulation complete";
        WAIT;
        
    end process stim;
end sim;

