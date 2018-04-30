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
		INT_WIDTH	: Natural := 8;
		BITS_FRAC_PART	: Natural := 8
	);
END convolution_tb;

ARCHITECTURE behavior OF convolution_tb IS 

-- Component Declaration
	COMPONENT convolution
		generic 	(
			IMG_DIM	: Natural := IMAGE_DIM;
			KERNEL_DIM 	: Natural := KERNEL_DIM;
			INT_WIDTH	: Natural := INT_WIDTH;
			BITS_FRAC_PART	: Natural := BITS_FRAC_PART
		);
		port ( 
			clk					: in std_logic;
			reset				: in std_logic;
			lyr_nmbr            : in Natural;
			conv_en			    : in std_logic;
			wt_we			: in std_logic;
			weight_data 		: in sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART);
			pixel_in 			: in sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART);
			out_valid		: out std_logic; 
			conv_en_out			: out std_logic;
			pixel_out 			: out sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART);
			bias				: out sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART)
		);
	END COMPONENT;
	
    constant val_zero 	: sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := "0000000000000000";
	constant val_one 	: sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := "0000000100000000";
	constant val_two 	: sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := "0000001000000000";
	constant val_three : sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := "0000001100000000";
	constant val_four 	: sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := "0000010000000000";
	constant val_five 	: sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := "0000010100000000";
	
	constant result0 	: sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(71, 7, -8);
	constant result1 	: sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(84, 7, -8);
	constant result2 	: sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(74, 7, -8);
	constant result3 	: sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(82, 7, -8);
	constant result4 	: sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(84, 7, -8);
	constant result5 	: sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(69, 7, -8);
	
	constant result6 	: sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(44, 7, -8);
	constant result7 	: sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(42, 7, -8);
	constant result8 	: sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(55, 7, -8);
	constant result9 	: sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(80, 7, -8);
	constant result10	: sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(81, 7, -8);
	constant result11	: sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(60, 7, -8);
	
	constant result12	: sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(73, 7, -8);
	constant result13	: sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(43, 7, -8);
	constant result14	: sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(41, 7, -8);
	constant result15	: sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(38, 7, -8);
	constant result16 	: sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(36, 7, -8);
    constant result17     : sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(50, 7, -8);
    
    constant result18     : sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(94, 7, -8);
    constant result19     : sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(63, 7, -8);
    constant result20     : sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(34, 7, -8);
    constant result21     : sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(47, 7, -8);
    constant result22     : sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(76, 7, -8);
    constant result23     : sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(57, 7, -8);
    
    constant result24     : sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(79, 7, -8);
    constant result25     : sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(63, 7, -8);
    constant result26    : sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(67, 7, -8);
    constant result27    : sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(44, 7, -8);
    constant result28    : sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(73, 7, -8);
    constant result29    : sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(82, 7, -8);
    
    constant result30    : sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(93, 7, -8);
    constant result31    : sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(75, 7, -8);
    constant result32    : sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(72, 7, -8);
    constant result33    : sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(69, 7, -8);
    constant result34    : sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(75, 7, -8);
    constant result35    : sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := to_sfixed(45, 7, -8);
    
	
	type img_array is array (IMAGE_DIM*IMAGE_DIM-1 downto 0) of sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART);
	type kernel_array is array (KERNEL_DIM*KERNEL_DIM downto 0) of sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART);
	type conv_array is array (35 downto 0) of sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART);
	
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
	
	signal kernel 	: kernel_array := (
        val_zero, val_one, val_zero, 
        val_zero, val_one, val_zero, 
        val_zero, val_one, val_zero,
		val_one -- bias
		);
		
	signal result : conv_array := (
        result35, result34, result33, result32, result31, result30,
        result29, result28, result27, result26, result25, result24,
        result23, result22, result21, result20, result19, result18,
        result17, result16, result15, result14, result13, result12,
        result11, result10, result9, result8, result7, result6,
        result5, result4, result3, result2, result1, result0
    );
		 

	signal clk			   : std_logic := '0';
	signal reset		   : std_logic := '1';
	signal conv_en_in	   : std_logic := '0';
	signal lyr_nmbr        : Natural := 0;
	signal wt_we	   : std_logic := '0';
	signal weight_data     : sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := (others => '0');
    signal pixel_in        : sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART) := (others => '0');
	signal out_valid    : std_logic; 
	signal pixel_out       : sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART);
	signal conv_en_out     : std_logic;
	signal bias_out        : sfixed(INT_WIDTH-1 downto -BITS_FRAC_PART);
	
	constant clk_period : time := 1 ns;
	signal nof_outputs 	: Natural := 0;
	constant Nof_Convs 	: Natural := 2;
BEGIN

	convolution_test : convolution port map(
		clk => clk,
		reset => reset,
		conv_en => conv_en_in,
		lyr_nmbr => lyr_nmbr,
		wt_we => wt_we,
		weight_data => weight_data,
		pixel_in => pixel_in,
		out_valid => out_valid,
		pixel_out => pixel_out,
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
			weight_data <= kernel(i);
			wait for clk_period;
		end loop;
		
		wt_we <= '0';
		wait;
		
	end process;
	
	
	create_input : PROCESS
	BEGIN
		wait for clk_period*(KERNEL_DIM*KERNEL_DIM+3); -- wait until weights are loaded. 
		conv_en_in <= '1';
		for test_nr in 0 to Nof_Convs-1 loop
			for i in 0 to ((IMAGE_DIM*IMAGE_DIM)-1) loop
				pixel_in <= image(IMAGE_DIM*IMAGE_DIM-1-i);
				wait for clk_period;
			end loop;
		end loop;
		conv_en_in <= '0';
		
		wait; -- will wait forever
	END PROCESS;
	
	assert_outputs : process(clk)
		variable convs_tested : Natural := 0;
	begin
		if rising_edge(clk) then
			if (convs_tested < Nof_Convs) then
				if (out_valid ='1') then
					assert pixel_out = result(nof_outputs)
						report "Output nr. " & Natural'image(nof_outputs) & ". Expected value: " &
							to_string(result(nof_outputs)) & ". Actual value: " & to_string(pixel_out) & "."
						severity error;
					if (nof_outputs = 35) then
						convs_tested := convs_tested + 1;
						nof_outputs <= 0;
					else
						nof_outputs <= nof_outputs + 1;
					end if;
				end if;
			end if;
		end if; 
	end process;
	
	assert_correct_nof_outputs : process(clk)
	begin
		if rising_edge(clk) then
			if (nof_outputs >= 72) then
				assert nof_outputs = 32
					report "More values was set as valid outputs than expected!"
					severity error;
			end if;
		end if;
	end process;
--  End Test Bench 

END;
