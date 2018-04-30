library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

entity tanh_tb is
    generic (
        BITS_INT_PART : natural := 8;
        BITS_FRAC_PART : natural := 8
    );
end tanh_tb;

architecture behavior of tanh_tb is

  -- Component Declaration
	component tan_h
		generic (
            BITS_INT_PART : Natural := 8;
            BITS_FRAC_PART : Natural := 8;
            CONST_INT_WIDTH : Natural := 8;
            CONST_FRAC_WIDTH : Natural := 8
        );
        Port (
            clk : in std_logic;
            in_valid : in std_logic;
            x : in  sfixed (BITS_INT_PART-1 downto -BITS_FRAC_PART);
            out_valid : out std_logic;
            y : out sfixed (BITS_INT_PART-1 downto -BITS_FRAC_PART)
        );
	end component;
	
	signal clk : std_logic := '0';
	signal in_valid : std_logic := '0';
	signal x :  sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := (others => '0');
	signal out_valid : std_logic := '0';
	signal y :  sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := (others => '0');
	
	constant clk_period : time := 2 ns;	
	
	constant m1 : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := to_sfixed(-0.54324, BITS_INT_PART-1, -BITS_FRAC_PART);
	
begin

    
    tanh_port : tan_h PORT MAP(
        clk => clk,
        in_valid => in_valid,
        x => x,
        out_valid => out_valid,
        y => y
    );

	clk_process :process
	begin
		clk <= '0';
		wait for clk_period/2;  --for 0.5 ns signal is '0'.
		clk <= '1';
		wait for clk_period/2;  --for next 0.5 ns signal is '1'.
	end process;
	
	tb : process
	begin
        wait for clk_period*5;
        in_valid <= '1';
        x <= to_sfixed(0.5, x);
        wait for clk_period;
        x <= to_sfixed(1, x);
        wait for clk_period;
        x <= (others => '0');
        wait for clk_period;
        x <= to_sfixed(-0.5, x);
        wait for clk_period;
        x <= to_sfixed(-1, x);
        wait for clk_period;
        x <= to_sfixed(1.67, x);
        wait for clk_period;
        x <= to_sfixed(-5, x);
        wait for clk_period;
        x <= to_sfixed(-0.26000, x);
        wait for clk_period;
        in_valid <= '0';
        x <= (others => '0');
        wait; -- wait forever
	end process tb;

end;
