library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

entity tanh is
    generic (
        BITS_INT_PART : Natural := 8;
        BITS_FRAC_PART : Natural := 8
    );
	Port (
		clk : in std_logic;
		in_valid : in std_logic;
		tanh_in : in  sfixed (BITS_INT_PART-1 downto -BITS_FRAC_PART);
		out_valid : out std_logic;
		tanh_out : out sfixed (BITS_INT_PART-1 downto -BITS_FRAC_PART)
	);
end tanh;
 
architecture Behavioral of tanh is

	constant m1 : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := to_sfixed(-0.54324*0.5, BITS_INT_PART-1, -BITS_FRAC_PART); 
	constant m2 : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := to_sfixed(-0.16957*0.5, BITS_INT_PART-1, -BITS_FRAC_PART);
	constant c1 : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := to_sfixed(1, BITS_INT_PART-1, -BITS_FRAC_PART);
	constant c2 : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := to_sfixed(0.42654, BITS_INT_PART-1, -BITS_FRAC_PART);
	constant d1 : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := to_sfixed(0.016, BITS_INT_PART-1, -BITS_FRAC_PART);
	constant d2 : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := to_sfixed(0.4519, BITS_INT_PART-1, -BITS_FRAC_PART);
	constant a : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := to_sfixed(1.52, BITS_INT_PART-1, -BITS_FRAC_PART);
	constant b : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := to_sfixed(2.57, BITS_INT_PART-1, -BITS_FRAC_PART);
	
	signal tanh_in_absol : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
	signal tanh_in_absol_c1 : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);	
	signal tanh_in_power_c1 : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);	
	signal sign_c1 : std_logic;
	signal sign_c2 : std_logic;
	signal sign_c3 : std_logic;
	signal tanh_in_valid_c1 : std_logic;
	signal tanh_in_valid_c2 : std_logic;
	signal tanh_in_valid_c3 : std_logic;
	signal tanh_in_c3 : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
	signal c2_1 : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
	signal c2_2 : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
	signal c2_3 : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
	
begin
    
    tanh_in_absol <= resize(abs(tanh_in), tanh_in_absol); -- Absolute value of tanh_in
  
    input_of_c1 : process(clk) 
    begin
        if rising_edge(clk) then
            tanh_in_absol_c1 <= tanh_in_absol;
            tanh_in_power_c1 <= resize(tanh_in_absol*tanh_in_absol, BITS_INT_PART-1, -BITS_FRAC_PART);
            sign_c1 <= tanh_in(BITS_INT_PART-1);
            tanh_in_valid_c1 <= in_valid;
        end if;
    end process;
    
    
    calculate_terms_c2 : process(clk)
    begin
        if rising_edge(clk) then
            sign_c2 <= sign_c1;
            tanh_in_valid_c2 <= tanh_in_valid_c1;
            if tanh_in_absol_c1 <= a and tanh_in_absol_c1 >= 0 then
                c2_1 <= resize(m1*tanh_in_power_c1, BITS_INT_PART-1, -BITS_FRAC_PART);
                c2_2 <= resize(c1*tanh_in_absol_c1, BITS_INT_PART-1, -BITS_FRAC_PART);
                c2_3 <= d1;
            elsif tanh_in_absol_c1 <= b and tanh_in_absol_c1 > a then
                c2_1 <= resize(m2*tanh_in_power_c1, BITS_INT_PART-1, -BITS_FRAC_PART);
                c2_2 <= resize(c2*tanh_in_absol_c1, BITS_INT_PART-1, -BITS_FRAC_PART);
                c2_3 <= d2;
            else
                c2_1 <= (others => '0');
                c2_2 <= (others => '0');
                c2_3 <= to_sfixed(1, BITS_INT_PART-1, -BITS_FRAC_PART);
            end if;
        end if;
    end process;
    
    add_terms_c3 : process(clk) 
    begin
        if rising_edge(clk) then
            sign_c3 <= sign_c2;
            tanh_in_valid_c3 <= tanh_in_valid_c2;
            tanh_in_c3 <= resize(c2_1 + c2_2 + c2_3, BITS_INT_PART-1, -BITS_FRAC_PART);
        end if;
    end process;
    
    output_cal: process(clk)
        begin 
            if rising_edge(clk) then
                if sign_c3 = '1' then
                    tanh_out <= resize(-tanh_in_c3, BITS_INT_PART-1, -BITS_FRAC_PART);
                else
                    tanh_out <= tanh_in_c3;
                end if;
                out_valid <= tanh_in_valid_c3;
            end if;
        end process;
        
end Behavioral;
