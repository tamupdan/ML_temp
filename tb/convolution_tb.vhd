library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;
  
ENTITY convolution_tb IS
	generic 	(
		IMAGE_DIM	: Natural := 8;
		KERNEL_DIM 	: Natural := 3;
		BITS_INT_PART	: Natural := 8;
		BITS_FRAC_PART	: Natural := 8
	);
END convolution_tb;

ARCHITECTURE behavior OF convolution_tb IS 

	COMPONENT convolution
		generic 	(
			IMG_DIM	: Natural := IMAGE_DIM;
			KERNEL_DIM 	: Natural := KERNEL_DIM;
			BITS_INT_PART	: Natural := BITS_INT_PART;
			BITS_FRAC_PART	: Natural := BITS_FRAC_PART
		);
		port ( 
			clk					: in std_logic;
			reset				: in std_logic;
			lyr_nmbr            : in Natural;
			convol_en			    : in std_logic;
			wt_we			: in std_logic;
			wt_data 		: in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
			pxl_in 			: in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
			out_valid		: out std_logic; 
			conv_en_out			: out std_logic;
			pxl_out 			: out sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
			bias				: out sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART)
		);
	END COMPONENT;
	
    constant val_zero 	: sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := "0000000000000000";
	constant val_one 	: sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := "0000000100000000";
	constant val_two 	: sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := "0000001000000000";
	constant val_three : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := "0000001100000000";
	constant val_four 	: sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := "0000010000000000";
	constant val_five 	: sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := "0000010100000000";
	
	type img_array is array (IMAGE_DIM*IMAGE_DIM-1 downto 0) of sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
	signal image 	: img_array := (
            val_zero, val_zero, val_zero, val_one, val_zero, val_zero, val_zero, val_zero, 
            val_zero, val_zero, val_zero, val_one, val_zero, val_zero, val_zero, val_zero, 
            val_zero, val_zero, val_zero, val_one, val_zero, val_zero, val_zero, val_zero, 
            val_zero, val_zero, val_zero, val_one, val_zero, val_zero, val_zero, val_zero, 
            val_zero, val_zero, val_zero, val_one, val_zero, val_zero, val_zero, val_zero, 
            val_zero, val_zero, val_zero, val_one, val_zero, val_zero, val_zero, val_zero, 
            val_zero, val_zero, val_zero, val_one, val_zero, val_zero, val_zero, val_zero, 
            val_zero, val_zero, val_zero, val_one, val_zero, val_zero, val_zero, val_zero
        );
        
	type kernel_array is array (KERNEL_DIM*KERNEL_DIM downto 0) of sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
	signal kernel 	: kernel_array := (
        val_zero, val_one, val_zero, 
        val_zero, val_one, val_zero, 
        val_zero, val_one, val_zero,
		val_one
		); 

	signal clk			   : std_logic := '0';
	signal reset		   : std_logic := '1';
	signal conv_en_in	   : std_logic := '0';
	signal lyr_nmbr        : Natural := 0;
	signal wt_we	   : std_logic := '0';
	signal wt_data     : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := (others => '0');
    signal pxl_in        : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART) := (others => '0');
	signal out_valid    : std_logic; 
	signal pxl_out       : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
	signal conv_en_out     : std_logic;
	signal bias_out        : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
	constant clk_period : time := 1 ns;
	signal nof_outputs 	: Natural := 0;
	constant Nof_Convs 	: Natural := 2;
	
BEGIN

	convolution_test : convolution port map(
		clk => clk,
		reset => reset,
		convol_en => conv_en_in,
		lyr_nmbr => lyr_nmbr,
		wt_we => wt_we,
		wt_data => wt_data,
		pxl_in => pxl_in,
		out_valid => out_valid,
		pxl_out => pxl_out,
		conv_en_out => conv_en_out,
		bias => bias_out
	);
	
	clock : process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;


	load_weights : process
	begin
		reset <= '0';
		wt_we <= '0';
		wait for clk_period;
		reset <= '1';
		wt_we <= '1';
		for i in 0 to KERNEL_DIM*KERNEL_DIM loop
			wt_data <= kernel(i);
			wait for clk_period;
		end loop;
		
		wt_we <= '0';
		wait;
		
	end process;
	
	
	create_input : PROCESS
	BEGIN
		wait for clk_period*(KERNEL_DIM*KERNEL_DIM+3);
		conv_en_in <= '1';
		for test_nr in 0 to Nof_Convs-1 loop
			for i in 0 to ((IMAGE_DIM*IMAGE_DIM)-1) loop
				pxl_in <= image(IMAGE_DIM*IMAGE_DIM-1-i);
				wait for clk_period;
			end loop;
		end loop;
		conv_en_in <= '0';
		
		wait; 
	END PROCESS;
END;
