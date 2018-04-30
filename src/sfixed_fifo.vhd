library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;
use ieee_proposed.float_pkg.all;


entity fifo is
	Generic (
		constant BITS_INT_PART : natural := 16;
        constant BITS_FRAC_PART : natural := 16;
		constant FIFO_DEPTH	: natural := 128
	);
	Port ( 
		clk		 : in  std_logic;
		reset	 : in  std_logic;
		write_en : in  std_logic;
        lyr_nmbr : in  natural;
		data_in	 : in  sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
		data_out : out sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART)
	);
end fifo;

architecture Behavioral of fifo is

    type fifo is array (0 to FIFO_DEPTH - 1) of sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    signal mem : fifo;
    signal ind : natural range 0 to FIFO_DEPTH - 1;
    signal looped : boolean;
    signal LAYER_DEPTH : natural;
    
    
begin

    set_layer_depth : process(lyr_nmbr)
    begin
        if lyr_nmbr = 1 then
            LAYER_DEPTH <= FIFO_DEPTH;
        else
            LAYER_DEPTH <= 25;
        end if;
    end process;
    
    out_value : process(looped, mem, ind)
    begin
        if looped then
            data_out <= mem(ind);
        else
            data_out <= (others => '0');
        end if;
    end process;
	
	fifo_proc : process (clk, reset)
	begin
        if reset = '0' then
            ind <= 0;
            looped <= false;
        elsif rising_edge(clk) then				
            if (write_en = '1') then
                if looped then
                    mem(ind) <= resize(data_in + mem(ind), BITS_INT_PART-1, -BITS_FRAC_PART);
                else
                    mem(ind) <= data_in;
                end if;
                
                if ind = LAYER_DEPTH-1 then
                    ind <= 0;
                    looped <= true;
                else
                    ind <= ind+1;
                end if;
            end if;
        end if;
	end process;
		
end Behavioral;
