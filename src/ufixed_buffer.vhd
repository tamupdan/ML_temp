library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

entity sfixed_buffer is
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
end sfixed_buffer;

architecture Behavioral of sfixed_buffer is
	signal stored_value : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
begin

	data_out <= stored_value;
	
	write_data : process(clk)
	begin
		if rising_edge(clk) then
			if (reset ='0') then
				stored_value <= (others => '0');
			elsif (we='1') then
				stored_value <= data_in;
			end if;
		end if;
	end process;


end Behavioral;

