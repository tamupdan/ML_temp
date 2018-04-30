library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

ENTITY cnn_tb IS
	generic (
		IMG_DIM 	 : Natural := 8;
		KERNEL_DIM 	   : Natural := 3;
		POOLING_DIM     : Natural := 2;
		BITS_INT_PART 	: Natural := 8;
		BITS_FRAC_PART	: Natural := 8
	);
END cnn_tb;

ARCHITECTURE behavior OF cnn_tb IS 

	component convolution_layer is
		generic (
			IMG_DIM 	: Natural := IMG_DIM;
			KERNEL_DIM 	  : Natural := KERNEL_DIM;
			POOLING_DIM 	: Natural := POOLING_DIM;
			BITS_INT_PART 	: Natural := BITS_INT_PART;
			BITS_FRAC_PART	: Natural := BITS_FRAC_PART
		);	
		port ( 
			clk 	 : in std_logic;
			reset : in std_logic;
			convol_en : in std_logic;
			final_set   : in std_logic;
			lyr_nmbr	 : in Natural;
			wt_we	   : in std_logic;
			wt_data	    : in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
			pxl_in       : in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
			pxl_valid   : out std_logic;
			pxl_out     : out sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
			pxl_tanh_out: inout sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
            pxl_tanh_pool   : inout sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART)
		);
	end component;
	
	signal clk 	 : std_logic := '0';
	signal reset   : std_logic := '0';
	signal convol_en : std_logic := '0';
	signal final_set    : std_logic := '0';
	signal lyr_nmbr    : Natural := 0;
	signal wt_we    : std_logic := '0';
	signal wt_data     : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := (others => '0');
	signal pxl_in   : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := (others => '0');
	signal pxl_valid	  : std_logic := '0';
	signal pxl_out 	     : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := (others => '0');
	signal pxl_tanh_pool   :  sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    signal pxl_tanh_out    :  sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);		
	constant clk_period : time := 1 ns;	
	constant val_zero 	: sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := "0000000000000000";
	constant val_one 	: sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := "0000000100000000";
	constant val_two 	: sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := "0000001000000000";
	constant val_three : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := "0000001100000000";
	constant val_four 	: sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := "0000010000000000";
	constant val_five 	: sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := "0000010100000000";

	type image_array is array ((IMG_DIM*IMG_DIM)-1 downto 0) of sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
	signal image : image_array := (
        val_zero, val_zero, val_zero, val_one, val_zero, val_zero, val_zero, val_zero, 
        val_zero, val_zero, val_zero, val_one, val_zero, val_zero, val_zero, val_zero,
        val_zero, val_zero, val_zero, val_one, val_zero, val_zero, val_zero, val_zero,
        val_zero, val_zero, val_zero, val_one, val_zero, val_zero, val_zero, val_zero,
        val_zero, val_zero, val_zero, val_one, val_zero, val_zero, val_zero, val_zero,
        val_zero, val_zero, val_zero, val_one, val_zero, val_zero, val_zero, val_zero,
        val_zero, val_zero, val_zero, val_one, val_zero, val_zero, val_zero, val_zero,
        val_zero, val_zero, val_zero, val_one, val_zero, val_zero, val_zero, val_zero
	);
	
	type kernel_array is array ((KERNEL_DIM*KERNEL_DIM) downto 0) of sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
	signal kernel : kernel_array := (
        val_zero, val_one, val_zero, 
        val_zero, val_one, val_zero, 
        val_zero, val_one, val_zero,
		val_three
	);
       
begin
	conv_layer : convolution_layer port map ( 
		clk => clk,
		reset	=> reset,
		convol_en	=> convol_en,
		lyr_nmbr	 => lyr_nmbr,
		final_set   => final_set,
		wt_we	  => wt_we,
		wt_data	 => wt_data,
		pxl_in	   => pxl_in,
		pxl_valid	=> pxl_valid,
		pxl_out 	=> pxl_out,
		pxl_tanh_pool	 => pxl_tanh_pool,
        pxl_tanh_out  => pxl_tanh_out
	);

	clock : process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;
	
	create_input : process
	begin
		wait for clk_period;	
		lyr_nmbr <= 0;
		reset <= '1';
		wt_we <= '1';
		
		for i in 0 to (KERNEL_DIM*KERNEL_DIM) loop
			wt_data <= kernel(i);
			wait for clk_period;
		end loop;
		wt_we <= '0';
		
		wait for clk_period;
		convol_en <= '1';
		for i in 0 to (IMG_DIM*IMG_DIM)-1 loop
			pxl_in <= image((IMG_DIM*IMG_DIM)-1-i);
			wait for clk_period;
		end loop;
		convol_en <= '0';
		wait; 
	end process;
end;