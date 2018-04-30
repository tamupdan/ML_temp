library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

entity buffer_cnn is
	generic (
		BITS_INT_PART 	: Natural := 8;
		BITS_FRAC_PART 	: Natural := 8
	);
	Port ( 
        clk : in std_logic;
        reset : in std_logic;
        we : in std_logic;
        data_in : in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
        data_out : out sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART)
	);
end buffer_cnn;

architecture Behavioral of buffer_cnn is
	signal buff_val : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
begin
	data_out <= buff_val;
	data : process(clk)
	begin
		if rising_edge(clk) then
			if (reset ='0') then
				buff_val <= (others => '0');
			elsif (we='1') then
				buff_val <= data_in;
			end if;
		end if;
	end process;
end Behavioral;

