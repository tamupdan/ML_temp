LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

ENTITY pooling_tb IS
	generic (
        IMG_DIM : Natural := 6;
        POOLING_DIM : Natural:= 2;
        BITS_INT_PART : Natural := 8;
        BITS_FRAC_PART : Natural := 8
	);
END pooling_tb;
 
ARCHITECTURE behavior OF pooling_tb IS 
  
    component pooling is
        generic (
            IMG_DIM : Natural := IMG_DIM;
            POOLING_DIM : Natural := POOLING_DIM;
            BITS_INT_PART : Natural := BITS_INT_PART;
            BITS_FRAC_PART : Natural := BITS_FRAC_PART
        );
        Port ( 
            clk : in std_logic;
            reset : in std_logic;
            convol_en : in std_logic;
            lyr_nmbr : in Natural;
            wt_in : in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
            wt_we : in std_logic;
            in_valid : in std_logic;
            data_in : in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
            data_out : out sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
            out_valid : out std_logic

        );
    end component;

    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    signal convol_en : std_logic := '0';
    signal lyr_nmbr : Natural := 1;
    signal wt_in : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := (others => '0');
    signal wt_we : std_logic := '0';
    signal in_valid : std_logic := '0';
    signal data_in : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := (others => '0');
    signal data_out : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    signal out_valid : std_logic;
  
    constant clk_period : time := 1 ns;
    
    constant val_minus_one : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := to_sfixed(-1, BITS_INT_PART-1, -BITS_FRAC_PART);
    constant val_zero : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := to_sfixed(0, BITS_INT_PART-1, -BITS_FRAC_PART);
    constant val_one : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := to_sfixed(1, BITS_INT_PART-1, -BITS_FRAC_PART);
    constant val_two : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := to_sfixed(2, BITS_INT_PART-1, -BITS_FRAC_PART);
    constant val_three : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := to_sfixed(3, BITS_INT_PART-1, -BITS_FRAC_PART); 
    constant val_four : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := to_sfixed(4, BITS_INT_PART-1, -BITS_FRAC_PART);
    constant val_five : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := to_sfixed(5, BITS_INT_PART-1, -BITS_FRAC_PART);
	signal weight : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := to_sfixed(0.25, BITS_INT_PART-1, -BITS_FRAC_PART);
	
	type arr is array ((IMG_DIM*IMG_DIM)-1 downto 0) of sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
	signal in_arr : arr := (
            val_one, val_one,     val_two, val_two,     val_three, val_three,
            val_one, val_one,     val_two, val_two,     val_three, val_three,          
            val_four, val_four,   val_five, val_five,     val_one, val_two,
            val_four, val_four,   val_five, val_five,     val_three, val_two,     
            val_three, val_two,     val_one, val_one,     val_minus_one, val_minus_one,
            val_three, val_four,    val_five, val_one,    val_minus_one, val_minus_one
        );
        
BEGIN

   pooling_inst : pooling PORT MAP (
          clk => clk,
          reset => reset,
          convol_en => convol_en,
          lyr_nmbr => lyr_nmbr,
          wt_in => wt_in,
          wt_we => wt_we,
          in_valid => in_valid,
          data_in => data_in,
          data_out => data_out,
          out_valid => out_valid
        );

   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;

    input: process
    begin		
        reset <= '0';
        wait for 10*clk_period;

        reset <= '1';
        wt_we <= '1';
        wt_in <= weight;
        wait for clk_period;
        
        wt_we <= '0';
        convol_en <= '1';

        for i in 0 to IMG_DIM-1 loop
            in_valid <= '1';
            for j in 0 to IMG_DIM-1 loop
                data_in <= in_arr(((IMG_DIM*IMG_DIM)-1)-((i*(IMG_DIM))+j));
                wait for clk_period;        
            end loop;
            in_valid <= '0';
            wait for 2*clk_period;
        end loop;
        
        convol_en <= '0';
        in_valid <= '0';
        
        wait;
    end process;

END;
