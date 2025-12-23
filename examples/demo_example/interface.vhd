library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
    port(
        clk     : in  std_logic;
        btn0    : in  std_logic;
        led     : out std_logic_vector(10 downto 0);
        scl     : inout std_logic;
        sda     : inout std_logic
    );
end entity;

architecture Behavioral of top is
    
    signal clk_internal   : std_logic;
    signal clk_locked     : std_logic;
    signal reset_internal : std_logic;
    constant GND : std_logic := '0';
    signal reset         : std_logic := '0';
    signal trigger       : std_logic := '0';
    signal restart       : std_logic := '0';
    signal last_byte     : std_logic := '0';
    signal address       : std_logic_vector(6 downto 0) := "1010111"; -- 0x57
    signal rw            : std_logic := '0';
    signal write_data    : std_logic_vector(7 downto 0) := (others=>'0');
    signal busy          : std_logic;
    signal ack_error     : std_logic;
    signal read_data     : std_logic_vector(7 downto 0);

    signal delay_counter : unsigned(23 downto 0) := (others=>'0');
    signal reg_index     : integer range 0 to 7 := 0;
    signal byte_index    : integer range 0 to 5 := 0;  -- For reading 6 bytes
    signal init_done     : std_logic := '0';
    
    -- Button debounce
    signal btn0_prev     : std_logic := '0';
    signal btn0_edge     : std_logic := '0';

    -- Storage for 6-byte FIFO data (RED + IR, 3 bytes each)
    type fifo_data_t is array (0 to 5) of std_logic_vector(7 downto 0);
    signal fifo_buffer   : fifo_data_t := (others => (others => '0'));
    
    -- Reconstructed 18-bit values
    signal red_value     : unsigned(17 downto 0) := (others => '0');
    signal ir_value      : unsigned(17 downto 0) := (others => '0');
    
    -- Peak detection signals
    signal ppg_q115      : signed(15 downto 0) := (others => '0');  -- Q1.15 format
    signal ppg_valid     : std_logic := '0';
    signal peak_detected : std_logic;
    signal peak_valid    : std_logic;

    type reg_array_t is array (0 to 7) of std_logic_vector(7 downto 0);
    constant reg_list : reg_array_t := (x"04", x"05", x"06", x"08", x"09", x"0A", x"0C", x"0D");
    constant val_list : reg_array_t := (x"00", x"00", x"00", x"00", x"03", x"27", x"24", x"24");

    type t_fsm_state is (
        IDLE,
        -- Initialization states
        SETUP_REG_ADDR, PULSE_TRIGGER_REG, WAIT_BUSY_HIGH_REG, WAIT_BUSY_LOW_REG,
        SETUP_REG_VAL, PULSE_TRIGGER_VAL, WAIT_BUSY_HIGH_VAL, WAIT_BUSY_LOW_VAL,
        DELAY_BETWEEN_REGS,
        -- Reading states
        READ_SETUP_FIFO_REG, READ_PULSE_FIFO_REG, READ_WAIT_HIGH_REG, READ_WAIT_LOW_REG,
        READ_RESTART, READ_PULSE_RESTART, READ_WAIT_RESTART_HIGH, READ_WAIT_RESTART_LOW,
        READ_SETUP_BYTE, READ_PULSE_BYTE, READ_WAIT_BYTE_HIGH, READ_WAIT_BYTE_LOW,
        READ_PROCESS_DATA, READ_DELAY
    );
    signal state : t_fsm_state := IDLE;

begin

    ---------------------------------------------------------------------------
    -- CLOCK WIZARD IP - Generate 75 MHz from input clock
    ---------------------------------------------------------------------------
    -- CLOCK_IP : entity work.clk_wiz_0
    --     port map(
    --         clk_in1  => clk,           -- Input clock (100 MHz from board)
    --         clk_out1 => clk_internal,  -- Output clock (75 MHz)
    --         reset    => GND,           -- No external reset for clock wizard
    --         locked   => clk_locked     -- High when clock is stable
    --     );
    clk_internal <= clk;  -- Bypass clock wizard for now
    -- Generate reset signal when clock is not locked
    reset_internal <= not clk_locked;

    ---------------------------------------------------------------------------
    -- LED DEBUG OUTPUTS
    ---------------------------------------------------------------------------
    led(0) <= busy;
    led(1) <= ack_error;
    led(2) <= init_done;
    led(3) <= peak_detected;  -- Show peak detection
    -- Show upper bits of Q1.15 PPG value when reading
    led(10 downto 4) <= std_logic_vector(ppg_q115(15 downto 9)) when init_done = '1' 
                        else std_logic_vector(to_unsigned(reg_index, 4)) & write_data(6 downto 4);

    ---------------------------------------------------------------------------
    -- BUTTON EDGE DETECTION
    ---------------------------------------------------------------------------
    process(clk_internal)
    begin
        if rising_edge(clk_internal) then
            btn0_prev <= btn0;
            btn0_edge <= btn0 and not btn0_prev;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- MAIN FSM
    ---------------------------------------------------------------------------
    process(clk_internal)
        variable red_temp : std_logic_vector(23 downto 0);
        variable ir_temp  : std_logic_vector(23 downto 0);
    begin
        if rising_edge(clk_internal) then
            trigger <= '0';
            restart <= '0';

            case state is
                -----------------------------------------------------------
                -- IDLE: Press button to start initialization
                -----------------------------------------------------------
                when IDLE =>
                    init_done <= '0';
                    if btn0_edge = '1' then
                        reg_index <= 0;
                        state <= SETUP_REG_ADDR;
                    end if;

                -----------------------------------------------------------
                -- INITIALIZATION PHASE (Write 8 registers)
                -----------------------------------------------------------
                when SETUP_REG_ADDR =>
                    write_data <= reg_list(reg_index);
                    last_byte  <= '0';
                    rw         <= '0';
                    state      <= PULSE_TRIGGER_REG;

                when PULSE_TRIGGER_REG =>
                    trigger <= '1';
                    state   <= WAIT_BUSY_HIGH_REG;

                when WAIT_BUSY_HIGH_REG =>
                    if busy = '1' then state <= WAIT_BUSY_LOW_REG; end if;

                when WAIT_BUSY_LOW_REG =>
                    if busy = '0' then state <= SETUP_REG_VAL; end if;

                when SETUP_REG_VAL =>
                    write_data <= val_list(reg_index);
                    last_byte  <= '1';  -- Generate STOP
                    state      <= PULSE_TRIGGER_VAL;

                when PULSE_TRIGGER_VAL =>
                    trigger <= '1';
                    state   <= WAIT_BUSY_HIGH_VAL;

                when WAIT_BUSY_HIGH_VAL =>
                    if busy = '1' then state <= WAIT_BUSY_LOW_VAL; end if;

                when WAIT_BUSY_LOW_VAL =>
                    if busy = '0' then
                        if reg_index = 7 then
                            init_done <= '1';
                            delay_counter <= (others => '0');
                            state <= READ_DELAY;  -- Move to reading
                        else
                            delay_counter <= (others => '0');
                            state <= DELAY_BETWEEN_REGS;
                        end if;
                    end if;

                when DELAY_BETWEEN_REGS =>
                    if delay_counter < 750000 then  -- Adjusted for 75 MHz (10ms)
                        delay_counter <= delay_counter + 1;
                    else
                        reg_index <= reg_index + 1;
                        state <= SETUP_REG_ADDR;
                    end if;

                -----------------------------------------------------------
                -- READING PHASE: Read FIFO_DATA (0x07) - 6 bytes
                -----------------------------------------------------------
                
                -- Short delay before starting read loop
                when READ_DELAY =>
                    if delay_counter < 3750000 then  -- 50ms at 75 MHz
                        delay_counter <= delay_counter + 1;
                    else
                        state <= READ_SETUP_FIFO_REG;
                    end if;

                -- Step 1: Send register address (0x07) in WRITE mode
                when READ_SETUP_FIFO_REG =>
                    write_data <= x"07";  -- FIFO_DATA register
                    last_byte  <= '0';    -- DON'T stop - we'll do repeated START
                    rw         <= '0';    -- Write mode
                    state      <= READ_PULSE_FIFO_REG;

                when READ_PULSE_FIFO_REG =>
                    trigger <= '1';
                    state   <= READ_WAIT_HIGH_REG;

                when READ_WAIT_HIGH_REG =>
                    if busy = '1' then state <= READ_WAIT_LOW_REG; end if;

                when READ_WAIT_LOW_REG =>
                    if busy = '0' then
                        -- Register address sent, now do REPEATED START
                        state <= READ_RESTART;
                    end if;

                -- Step 2: Generate REPEATED START and switch to READ mode
                when READ_RESTART =>
                    restart    <= '1';  -- Signal restart
                    rw         <= '1';  -- Switch to READ mode
                    byte_index <= 0;    -- Reset byte counter
                    state      <= READ_PULSE_RESTART;

                when READ_PULSE_RESTART =>
                    trigger <= '1';
                    state   <= READ_WAIT_RESTART_HIGH;

                when READ_WAIT_RESTART_HIGH =>
                    if busy = '1' then state <= READ_WAIT_RESTART_LOW; end if;

                when READ_WAIT_RESTART_LOW =>
                    if busy = '0' then
                        -- Restart complete, now read bytes
                        state <= READ_SETUP_BYTE;
                    end if;

                -- Step 3: Read 6 bytes
                when READ_SETUP_BYTE =>
                    if byte_index = 5 then
                        last_byte <= '1';  -- Last byte, send NACK and STOP
                    else
                        last_byte <= '0';  -- Send ACK, continue reading
                    end if;
                    state <= READ_PULSE_BYTE;

                when READ_PULSE_BYTE =>
                    trigger <= '1';
                    state   <= READ_WAIT_BYTE_HIGH;

                when READ_WAIT_BYTE_HIGH =>
                    if busy = '1' then state <= READ_WAIT_BYTE_LOW; end if;

                when READ_WAIT_BYTE_LOW =>
                    if busy = '0' then
                        -- Store the byte we just read
                        fifo_buffer(byte_index) <= read_data;
                        
                        if byte_index = 5 then
                            -- All 6 bytes read, process data
                            state <= READ_PROCESS_DATA;
                        else
                            -- Read next byte
                            byte_index <= byte_index + 1;
                            state <= READ_SETUP_BYTE;
                        end if;
                    end if;

                -- Step 4: Process the 6 bytes into RED and IR values
                when READ_PROCESS_DATA =>
                    -- RED = bytes 0,1,2 (concatenate and mask to 18 bits)
                    red_temp := fifo_buffer(0) & fifo_buffer(1) & fifo_buffer(2);
                    red_value <= unsigned(red_temp(17 downto 0));  -- Full 18-bit value
                    
                    -- IR = bytes 3,4,5
                    ir_temp := fifo_buffer(3) & fifo_buffer(4) & fifo_buffer(5);
                    ir_value <= unsigned(ir_temp(17 downto 0));
                    
                    -- Extract 16-bit Q1.15 value from RED (bits 17:2)
                    -- This takes the most significant 16 bits from the 18-bit value
                    ppg_q115 <= signed(red_temp(17 downto 2));
                    
                    -- Assert valid signal for one cycle
                    ppg_valid <= '1';
                    
                    -- Start next read cycle
                    delay_counter <= (others => '0');
                    state <= READ_DELAY;

                when others =>
                    state <= IDLE;
            end case;
            
            -- Clear valid signal after one cycle (pulse)
            if ppg_valid = '1' and state /= READ_PROCESS_DATA then
                ppg_valid <= '0';
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- I2C CONTROLLER INSTANCE
    ---------------------------------------------------------------------------
    I2C_INST : entity work.i2c_controller
        port map(
            clock      => clk_internal,
            reset      => reset_internal,
            trigger    => trigger,
            restart    => restart,
            last_byte  => last_byte,
            address    => address,
            read_write => rw,
            write_data => write_data,
            read_data  => read_data,
            ack_error  => ack_error,
            busy       => busy,
            scl        => scl,
            sda        => sda
        );

    ---------------------------------------------------------------------------
    -- PEAK DETECTION INSTANCE
    ---------------------------------------------------------------------------
    PEAK_INST : entity work.pipeline
        port map(
            clk           => clk_internal,
            rst           => reset_internal,
            valid_in      => ppg_valid,
            signal_in     => ppg_q115,
            peak_detected => peak_detected,
            valid_out     => peak_valid
        );

end architecture;