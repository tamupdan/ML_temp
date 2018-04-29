library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

entity mac is
	generic  (
					BITS_INT_PART 	: Natural := 8;
					BITS_FRAC_PART 	: Natural := 8
				);
	Port( 	
			clk 		: in std_logic;
			reset 		: in std_logic;		
			wt_we 	: in std_logic;
			weight_in 	: in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
			multi_value : in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
			acc_value 	: in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
			weight_out	: out sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
			result 		: out sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART)
		);
end mac;

architecture Behavioral of mac is
	
	signal weight_reg 	: sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
	signal sum 			: sfixed(BITS_INT_PART*2 downto -BITS_FRAC_PART*2);
    signal product      : sfixed((BITS_INT_PART*2)-1 downto -BITS_FRAC_PART*2);
	
begin	
	
	weight_out <= weight_reg;
	
	weight_register : process(clk) 
	begin
		if rising_edge(clk) then
			if (reset = '0') then
				weight_reg <= (others => '0');
			elsif(wt_we = '1') then
				weight_reg <= weight_in;
			end if;
		end if;
	end process;
	
    result_register : process(clk) 
    begin
        if rising_edge(clk) then
            result <= resize(sum, BITS_INT_PART-1, -BITS_FRAC_PART);
        end if;
    end process;
    
    mult_and_acc : process(product, weight_reg, acc_value, multi_value) 
    begin
        product <= weight_reg*multi_value;
        sum <= product+acc_value;
    end process;
	

end Behavioral;

