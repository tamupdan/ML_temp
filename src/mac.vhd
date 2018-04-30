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
			wt_in 	: in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
			mul_val : in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
			acc_val 	: in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
			mac_wt_out	: out sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
			result 		: out sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART)
		);
end mac;

architecture Behavioral of mac is
	
	signal wt_reg 	: sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
	signal sum 			: sfixed(BITS_INT_PART*2 downto -BITS_FRAC_PART*2);
    signal pro      : sfixed((BITS_INT_PART*2)-1 downto -BITS_FRAC_PART*2);
	
begin	
	
	mac_wt_out <= wt_reg;
	
	weight_register : process(clk) 
	begin
		if rising_edge(clk) then
			if (reset = '0') then
				wt_reg <= (others => '0');
			elsif(wt_we = '1') then
				wt_reg <= wt_in;
			end if;
		end if;
	end process;
	
    result_register : process(clk) 
    begin
        if rising_edge(clk) then
            result <= resize(sum, BITS_INT_PART-1, -BITS_FRAC_PART);
        end if;
    end process;
    
    mac_op : process(pro, wt_reg, acc_val, mul_val) 
    begin
        pro <= wt_reg*mul_val;
        sum <= pro+acc_val;
    end process;
	

end Behavioral;

