library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity interface is
    Port(
        clk      : in STD_LOGIC;
        rst      : in STD_LOGIC;
        init_done : out STD_LOGIC;
        sda      : inout STD_LOGIC;
        scl      : inout STD_LOGIC;
    );
end interface;

architecture rtl of interface is
    signal ena        : std_logic := '0';
    signal addr       : std_logic_vector(7 downto 0) := "1010111"; -- 0x57
    signal buffer_in  : std_logic_vector(23 downto 0) := (others => '0');
    signal rw         : std_logic;
    signal data_wr    : std_logic_vector(7 downto 0) := (others => '0');
    signal busy       : std_logic;
    signal read_byte  : std_logic_vector(7 downto 0);
    signal ack_error  : std_logic := '0';
    signal buff_read  : std_logic := '0';

    signal init_steps : integer range 0 to 8 := 0;
    signal init_done  : std_logic := '0';
    signal x_in       : signed(15 downto 0);

    signal byte_count : integer range 0 to 2 := 0;
    signal valid_in   : std_logic := '0';

    type state_type is (idle, write_reg, write_value, read_reg, read_value);
    signal state      : state_type := idle;

    type read_state_type is (wait_init, start_read, collecting_bytes, wait_next_read);
    signal read_state : read_state_type := wait_init;

    constant BUSY_TIMEOUT : integer := 50000;
    signal busy_counter   : integer range 0 to BUSY_TIMEOUT := 0;
    signal busy_timed_out : std_logic := '0';

    -- If the master wants to communicate, it drives them to '0' to pull the bus.
    -- This ensure SDA and SCL are releasted at the startup.
    signal scl_output_enable : std_logic := '1';
    signal sda_output_enable : std_logic := '1';

    begin
        master_instance: entity work.master
            port map(
                clk => clk, 
                rst => rst,
                ena => ena,
                addr => addr,
                rw  => rw,
                data_wr => data_wr,
                busy => busy,
                ack_error => ack_error,
                data_rd => read_byte,
                sda => sda,
                scl => scl
            );
        
        -- Tri-state drivers
        scl <= '0' when scl_output_enable = '1' else 'Z';
        sda <= '0' when sda_output_enable = '1' else 'Z';

        procedure write_register(
            signal register_addr : std_logic_vector(7 downto 0), 
            signal data_to_write : std_logic_vector(7 downto 0)) is
            begin
                case state is
                    when idle => 
                        if not busy then 
                            data_wr <= register_addr;
                            rw <= '0';
                            ena <= '1';
                            state <= write_reg;
                        end if;
                    when write_reg =>
                        ena <= '0';
                        if not busy then 
                            data_wr <= data_to_write;
                            rw <= '0';
                            ena <= '1';
                            state <= write_value;
                        end if; 
                    when write_value =>
                        ena <= '0';
                        rw <= '0';
                        if not busy then 
                            state <= idle;
                        end if;
                    when others =>
                        null;
                end case;
        end procedure;

        procedure read_register(
            signal register_addr : std_logic_vector(7 downto 0)
        ) is
        begin
            case state is
                when idle =>
                    if not busy then
                        -- write where to read from
                        data_wr <= register_addr;
                        rw <= '0';
                        ena <= '1';
                        state <= read_reg;
                    end if;
                when read_reg =>
                    ena <= '0';
                    if not busy then
                        rw <= '1';
                        ena <= '1';
                        state <= read_value;
                    end if;
                when read_value =>
                    ena <= '0';
                    rw <= '0';
                    if not busy then
                        state <= idle;
                    end if;
                when others =>
                    null
            end case;
        end procedure;
        

        -- Initailize MAX30102 
        init_process: process(clk)
        begin 
            if rst = '1' then
                init_done <= '0';
                state <= idle;
            elsif rising_edge(clk) then
                if init_done = '0' then
                    case init_steps is
                        when 0 =>
                            if (state = idle) and (busy = '0') then
                                write_register(x"04", x"00");
                                init_steps <=  1;
                            end if;
                        when 1 =>
                            if (state = idle) and (busy = '0') then
                                write_register(x"05", x"00");
                                init_steps <=  2;
                            end if;
                        when 2 =>
                            if (state = idle) and (busy = '0') then
                                write_register(x"06", x"00");
                                init_steps <=  3;
                            end if;
                        when 3 =>
                            if (state = idle) and (busy = '0') then
                                -- Set FIFO configuration 
                                -- write_register(x"08", x"00");
                                write_register(x"08", x"3F");
                                init_steps <=  4;
                            end if;
                        when 4 =>
                            if (state = idle) and (busy = '0') then
                                -- Set mode configuration to HR mode
                                write_register(x"09", x"02");
                                init_steps <=  5;
                            end if;
                        when 5 =>
                            if (state = idle) and (busy = '0') then
                                -- Set SpO2 configuration
                                write_register(x"0A", x"25");
                                init_steps <=  6;
                            end if;
                        when 6 =>
                            if (state = idle) and (busy = '0') then
                                -- Set LED pulse amplitudes
                                write_register(x"0C", x"24"); -- RED
                                init_steps <=  7;
                            end if;
                        when 7 =>
                            if (state = idle) and (busy = '0') then
                                write_register(x"0D", x"00"); -- IR
                                init_steps <=  8;
                            end if;
                        when 8 =>   
                            if (state = idle) and (busy = '0') then
                                init_done <= '1';
                            end if;
                        when others =>
                            null;
                    end case;
                    -- write_register(x"04", x"00");
                    -- write_register(x"05", x"00");
                    -- write_register(x"06", x"00");
                    -- -- Set FIFO configuration 
                    -- write_register(x"08", x"3F");
                    
                    -- -- Set mode configuration to HR mode
                    -- write_register(x"09", x"02");

                    -- -- Set SpO2 configuration
                    -- write_register(x"0A", x"25");

                    -- -- Set LED pulse amplitudes
                    -- write_register(x"0C", x"24"); -- RED
                    -- write_register(x"0D", x"00"); -- IR

                    -- init_done <= '1';
                -- else
                -- -- After initialization, continuously read data
                --     if (state = idle) and (busy = '0') then
                --         read_register(x"07");
                --     end if;
                -- 
                end if;
            end if; 
        end process init_process;

        -- Busy watchdog to prevent deadlocks(hung I2C bus)
        busy_watchdog: process(clk, rst)
        begin
            if rst = '1' then
                busy_counter <= 0;
                busy_timed_out <= '0';
            elsif rising_edge(clk) then
                if busy = '1' then
                    if busy_counter < BUSY_TIMEOUT then
                        busy_counter <= busy_counter + 1;
                    else
                        busy_timed_out <= '1';
                    end if;
                else
                    busy_counter <= 0;
                    busy_timed_out <= '0';
                end if;
            end if;
        end process busy_watchdog;

        read_three_bytes: process(clk, rst)
        begin
            if rst = '1' then
                read_state <= wait_init;
            elsif rising_edge(clk) then
                if busy_timed_out = '1' then
                    state <= idle;
                    ena <= '0';
                    -- Because init_done is already '1', we can directly go to start_read
                    read_state <= start_read;
                end if;
                case read_state is
                    when wait_init =>
                        if init_done = '1' then
                            read_state <= start_read;
                        end if;
                    when start_read =>
                        if (state = idle) and (busy = '0') then
                            read_register(x"07");
                            read_state <= collecting_bytes;
                        end if;
                    when collecting_bytes =>
                        if ack_error = '1' then
                            read_state <= start_read;
                        elsif buff_read = '1' then
                            read_state <= wait_next_read;
                        end if;
                    when wait_next_read =>
                        if (state = idle) and (busy = '0') then
                            read_state <= start_read;
                        end if;
                    when others =>
                        read_state <= wait_init;
                end case;
            end if;
        end process read_three_bytes;

        -- Receiving 3 bytes and storing in buffer_in
        buffering: process(clk, rst)
        -- variable nack_count : integer := 0;
        begin
            if rst = '1' then
                byte_count <= 0;
                buff_read <= '0';
            elsif rising_edge(clk) then 
                if(ack_error = '0') and (state = read_value) then
                    case byte_count is
                        when 0 =>
                            buffer_in(23 downto 16) <= read_byte;
                            byte_count <= 1;
                        when 1 =>
                            buffer_in(15 downto 8) <= read_byte;
                            byte_count <= 2;
                        when 2 =>
                            buffer_in(7 downto 0) <= read_byte;
                            buff_read <= '1';
                            byte_count <= 0;
                        when others =>
                            byte_count <= 0;
                            report "Unexpected byte_count value" severity warning;
                    end case;
                else
                    buff_read <= '0';
                -- elsif (ack_error = '0') and (state = read_value) then
                --     if byte_count < 3 then
                --         case byte_count is
                --             when 0 =>
                --                 buffer_in(23 downto 16) <= read_byte;
                --             when 1 =>
                --                 buffer_in(15 downto 8) <= read_byte;
                --             when 2 =>
                --                 buffer_in(7 downto 0) <= read_byte;
                --             when others =>
                --                 null;
                --         end case;
                --         byte_count <= byte_count + 1;
                --     end if;
                --     if byte_count = 2 then
                --         buff_read <= '1';
                --         byte_count <= 0;
                --     end if;
                -- else
                --     buff_read <= '0';
                
                    -- if byte_count = 0 then 
                    --     buffer_in(23 downto 16) <= read_byte;
                    --     byte_count <= byte_count + 1;
                    -- elsif byte_count = 1 then
                    --     buffer_in(15 downto 8) <= read_byte;
                    --     byte_count <= byte_count + 1;
                    -- elsif byte_count = 2 then
                    --     buffer_in(7 downto 0) <= read_byte;
                    --     buff_read <= '1';
                    --     byte_count <= 0;
                    -- end if;
                -- if nack_count > 0 then
                --     nack_count <= 0;
                -- end if;
            -- else
            --     if byte_count = 0  then
            --         byte_count <= 2;
            --     elsif nack = 1 then
            --         byte_count <= byte_count - 1;
            --         nack_count <= nack_count + 1;
            --     end if;
                end if;
            end if;
        end process buffering;

        sample: process(clk, rst)
        begin
            if rst = '1' then
                x_in <= (others => '0');
                valid_in <= '0';
            elsif rising_edge(clk) then
                if buff_read = '1' then
                    x_in <= signed(buffer_in(17 downto 2));
                    valid_in <= '1';
                else
                    valid_in <= '0';
                end if;
            end if;
        end process sample;
end rtl;
