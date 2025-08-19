library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_and_gate is
end tb_and_gate;

architecture behavior of tb_and_gate is

    signal A, B, Y : std_logic;

begin
    uut: entity work.AND_Gate
        port map (
            A => A,
            B => B,
            Y => Y
        );

    stim_proc: process
    begin
        A <= '0'; B <= '0';
        wait for 10 ns;

        A <= '0'; B <= '1';
        wait for 10 ns;

        A <= '1'; B <= '0';
        wait for 10 ns;

        A <= '1'; B <= '1';
        wait for 10 ns;

        wait;
    end process;

end behavior;
