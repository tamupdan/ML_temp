library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

ENTITY conv_layer_tb_wo_sig IS
	generic (
		IMG_DIM 		: Natural := 8;
		KERNEL_DIM 		: Natural := 3;
		POOL_DIM 	    : Natural := 2;
		INT_WIDTH 		: Natural := 8;
		FRAC_WIDTH 		: Natural := 8
	);
END conv_layer_tb_wo_sig;

ARCHITECTURE behavior OF conv_layer_tb_wo_sig IS 

	component convolution_layer is
		generic (
			IMG_DIM 		: Natural := IMG_DIM;
			KERNEL_DIM 		: Natural := KERNEL_DIM;
			POOL_DIM 	    : Natural := POOL_DIM;
			INT_WIDTH 		: Natural := INT_WIDTH;
			FRAC_WIDTH 		: Natural := FRAC_WIDTH
		);
		
		port ( 
			clk 		: in std_logic;
			reset		: in std_logic;
			conv_en		: in std_logic;
			final_set   : in std_logic;
			layer_nr	: in Natural;
			weight_we	: in std_logic;
			weight_data	: in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			pixel_in	: in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			pixel_valid	: out std_logic;
			pixel_out 	: out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			dummy_bias	: out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			pixelOut_Tanh2ToOut	: inout sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
            pixelOut_TanhToAvgPool    : inout sfixed(INT_WIDTH-1 downto -FRAC_WIDTH)
		);
	end component;
	
	signal clk 			: std_logic := '0';
	signal reset		: std_logic := '0';
	signal conv_en		: std_logic := '0';
	signal final_set    : std_logic := '0';
	signal layer_nr	    : Natural := 0;
	signal weight_we	: std_logic := '0';
	signal weight_data	: sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');
	signal pixel_in		: sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');
	signal pixel_valid	: std_logic := '0';
	signal pixel_out 	: sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');
	signal dummy_bias	: sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');
	signal pixelOut_TanhToAvgPool	:  sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    signal pixelOut_Tanh2ToOut    :  sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
	constant clk_period : time := 1 ns;
	
	-- INPUT/OUTPUT
	
	constant zero 	: sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000000000000000";
	constant one 	: sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000000100000000";
	constant two 	: sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000001000000000";
	constant three : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000001100000000";
	constant four 	: sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000010000000000";
	constant five 	: sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000010100000000";
	
    constant result0 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(84, 7, -8);
    constant result1 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(82, 7, -8);
    constant result2 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(84, 7, -8);
    constant result3 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(94, 7, -8);
    constant result4 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(47, 7, -8);
    constant result5 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(76, 7, -8);
    constant result6 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(93, 7, -8);
    constant result7 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(72, 7, -8);
    constant result8 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(82, 7, -8);
	
	constant OUTPUT_DIM : Natural := (IMG_DIM-KERNEL_DIM+1)/POOL_DIM;
	type img_array is array ((IMG_DIM*IMG_DIM)-1 downto 0) of sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	type kernel_array is array ((KERNEL_DIM*KERNEL_DIM) downto 0) of sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	type pooled_array is array ((OUTPUT_DIM*OUTPUT_DIM)-1 downto 0) of sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
	signal img : img_array := (
        zero, zero, zero, one, zero, zero, zero, zero, 
        zero, zero, zero, one, zero, zero, zero, zero,
        zero, zero, zero, one, zero, zero, zero, zero,
        zero, zero, zero, one, zero, zero, zero, zero,
        zero, zero, zero, one, zero, zero, zero, zero,
        zero, zero, zero, one, zero, zero, zero, zero,
        zero, zero, zero, one, zero, zero, zero, zero,
        zero, zero, zero, one, zero, zero, zero, zero
	);
	
	signal kernel : kernel_array := (
        zero, one, zero, 
        zero, one, zero, 
        zero, one, zero,
		three
	);
	
	signal result : pooled_array := (
        result8, result7, result6,
        result5, result4, result3,
        result2, result1, result0
    );
	
	signal nof_outputs : Natural := 0;
	
	
	
       
begin

	conv_layer : convolution_layer port map ( 
		clk 			=> clk,
		reset			=> reset,
		conv_en		=> conv_en,
		layer_nr	=> layer_nr,
		final_set => final_set,
		weight_we	=> weight_we,
		weight_data	=> weight_data,
		pixel_in		=> pixel_in,
		pixel_valid	=> pixel_valid,
		pixel_out 	=> pixel_out,
		dummy_bias	=> dummy_bias,
		pixelOut_TanhToAvgPool	 => pixelOut_TanhToAvgPool,
        pixelOut_Tanh2ToOut  => pixelOut_Tanh2ToOut
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
		
		layer_nr <= 0;
		reset <= '1';
		weight_we <= '1';
		for i in 0 to (KERNEL_DIM*KERNEL_DIM) loop
			weight_data <= kernel(i);
			wait for clk_period;
		end loop;
		weight_we <= '0';
		wait for clk_period;
		
		conv_en <= '1';
		for i in 0 to (IMG_DIM*IMG_DIM)-1 loop
			pixel_in <= img((IMG_DIM*IMG_DIM)-1-i);
			wait for clk_period;
		end loop;
		conv_en <= '0';
		wait; 
	end process;
	
	assert_outputs : process(clk)
	begin
		if rising_edge(clk) then
			if (pixel_valid ='1') then
				assert pixel_out = result(nof_outputs)
					report "Output nr. " & Natural'image(nof_outputs) & ". Expected value: " &
						to_string(result(nof_outputs)) & ". Actual value: " & to_string(pixel_out) & "."
					severity error;
				nof_outputs <= nof_outputs + 1;
			end if;
		end if; 
	end process;
	
	assert_correct_nof_outputs : process(clk)
	begin
		if rising_edge(clk) then
			if (nof_outputs >= 9) then
				assert nof_outputs = 9
					report "More values was set as valid outputs than expected!"
					severity error;
			end if;
		end if;
	end process;

end;
