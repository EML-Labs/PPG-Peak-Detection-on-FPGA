library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity master_buffer is
    Port(
        clk      : in STD_LOGIC;
        rst      : in STD_LOGIC;
        sda      : inout STD_LOGIC;
        scl      : inout STD_LOGIC;
    );
end master_buffer;

architecture rtl of master_buffer is
    signal buffer_in  : std_logic_vector(23 downto 0) := (others => '0');
    signal read_byte  : std_logic_vector(7 downto 0);
    signal ack_error  : std_logic := '0';
    signal buff_read  : std_logic := '0';
    signal x_in       : signed(15 downto 0);
    signal byte_count : integer range 0 to 2 := 0;
    signal valid_in   : std_logic := '0';
    begin
        master_instance: entity work.master
            port map(
                clk => clk, 
                rst => rst,
                ena => '1',
                addr => x"AF", 
                rw  => '1';
                data_wr => x"00",
                busy => open,
                ack_error => ack_error,
                data_rd => read_byte,
                sda => sda,
                scl => scl
            );

        -- Receiving 3 bytes and storing in buffer_in
        buffering: process(clk)
        -- variable nack_count : integer := 0;
        begin
            if rising_edge(clk) then 
                if rst = '1' then
                    byte_count <= 0;
                    buff_read <= '0';
                elsif ack_error = '0' then
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

        sample: process(clk)
        begin
            if rising_edge(clk) then
                if buff_read = '1' then
                    x_in <= signed(buffer_in(17 downto 2));
                    valid_in <= '1';
                    buff_read <= '0';
                else
                    valid_in <= '0';
                end if;
            end if;
        end process sample;
end rtl;
