library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;
use ieee_proposed.float_pkg.all;

entity convolution_layer is
	generic (
		IMG_DIM 		    : Natural := 8;
		KERNEL_DIM 		    : Natural := 3;
		POOLING_DIM    	    : Natural := 2;
		BITS_INT_PART 		: Natural := 8;
		BITS_FRAC_PART 		: Natural := 8
	);
	
	
	port ( 
		clk 		            : in std_logic;
		reset		            : in std_logic;
		convol_en		        : in std_logic;
        final_set               : in std_logic;
		lyr_nmbr	            : in Natural;
		wt_we	                : in std_logic;
		wt_data               	: in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
		pxl_in	                : in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
		pxl_valid	            : out std_logic;
		pxl_out 	            : out sfixed(BITS_INT_PART+BITS_FRAC_PART-1 downto 0);
		pxl_tanh_pool        	: inout sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
		pxl_tanh_out        	: inout sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART)
	);
end convolution_layer;

architecture Behavioral of convolution_layer is
	
	component convolution
		generic 	(
			IMG_DIM	        : Natural := IMG_DIM;
			KERNEL_DIM 	    : Natural := KERNEL_DIM;
			BITS_INT_PART	: Natural := BITS_INT_PART;
			BITS_FRAC_PART	: Natural := BITS_FRAC_PART
		);
		port ( 
			clk				: in std_logic;
			reset			: in std_logic;
			convol_en 		: in std_logic;
			lyr_nmbr        : in natural;
			wt_we		    : in std_logic;
			wt_data 	    : in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
			pxl_in 		    : in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
			out_valid	    : out std_logic; 
			conv_en_out		: out std_logic;
			pxl_out 		: out sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
			bias     		: out sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART)
		);
	end component;
	
	component average_pooler
        generic (
            IMG_DIM         : Natural := IMG_DIM-KERNEL_DIM+1;
            KERNEL_DIM      : Natural := KERNEL_DIM;
            POOLING_DIM     : Natural := POOLING_DIM;
            BITS_INT_PART   : Natural := BITS_INT_PART;
            BITS_FRAC_PART  : Natural := BITS_FRAC_PART
            );
        Port ( 
            clk         : in std_logic;
            reset       : in std_logic;
            convol_en   : in std_logic;
            lyr_nmbr    : in natural;
            wt_in       : in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
            wt_we       : in std_logic;
            in_valid    : in std_logic;
            data_in     : in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
            data_out    : out sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
            out_valid   : out std_logic;
            wt_out      : out sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART)
            
        );
	end component;
	
	component sfixed_fifo is
		generic (
			BITS_INT_PART 	: Natural := BITS_INT_PART;
			BITS_FRAC_PART 	: Natural := BITS_FRAC_PART;
            FIFO_DEPTH : Natural := (((IMG_DIM-KERNEL_DIM+1)/2)-KERNEL_DIM+1)*(((IMG_DIM-KERNEL_DIM+1)/2)-KERNEL_DIM+1)
		);
		Port ( 
            clk		 : in  std_logic;
            reset	 : in  std_logic;
            write_en : in  std_logic;
            lyr_nmbr    : in  Natural;
            data_in	 : in  sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
            data_out : out sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART)			
		);
	end component;
	
	component tan_h is
		Port (
            clk 	     : in std_logic;
			in_valid  : in std_logic;
			tanh_in 		     : in  sfixed (BITS_INT_PART-1 downto -BITS_FRAC_PART);
			out_valid : out std_logic;
			tanh_out 		     : out sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART)
		);
	end component;
	


	signal bias : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
	signal bias2 : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    signal wt_pool_bias2 : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    signal scaling : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    
	signal convEn_convToMux : std_logic;
	signal outputValid_convToMux : std_logic;
    signal pixelOut_convToMux : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);

    signal pixel_BufToMux : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    signal buffer_we      : std_logic;
    
    signal pixel_MuxToBias : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    signal valid_MuxToBias : std_logic;

    signal pixel_MuxToF2F : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    signal pixelValid_MuxToF2F : std_logic;
    
    signal valid_biasToTanh : std_logic;
    signal pixel_biasToTanh : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    
    signal pixelValid_TanhToAvgPool : std_logic;
    --signal pxl_tanh_pool : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    
    signal pixelValid_AvgPoolToScaleFactor : std_logic;
    signal pixelOut_AvgPoolToScaleFactor : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);

    signal pixelValid_ScaleFactorToBias2 : std_logic;
    signal pixelOut_ScaleFactorToBias2 : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    
    signal pixelValid_Bias2ToTanh2 : std_logic;
    signal pixelOut_Bias2ToTanh2 : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);

    signal pixelValid_Tanh2ToOut : std_logic;
    --signal pxl_tanh_out : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);

    signal pixelValid_F2FToOut : std_logic;
    signal pixelOut_F2FToOut : float32;
    
    --signal y1        	: sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    --signal y2            : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);

    signal float_size : float32;

    signal is_layer_1 : std_logic;
begin

	conv : convolution port map (
		clk				=> clk,
		reset			=> reset,
		convol_en 		=> convol_en,
		lyr_nmbr        => lyr_nmbr,
		wt_we		=> wt_we,
		wt_data 	=> wt_data,
		pxl_in 		=> pxl_in,
		out_valid	=> outputValid_convToMux,--dv_conv_to_buf_and_mux,
		conv_en_out		=> convEn_convToMux,
		pxl_out 		=> pixelOut_convToMux,--data_conv_to_buf_and_mux,
		bias    		=> bias
	
	);

    is_layer_1_process : process (lyr_nmbr)
    begin
        --if lyr_nmbr = 1 or lyr_nmbr = 2 then
            --is_layer_1 <= '1';
        --else
            is_layer_1 <= '0';
        --end if;
    end process;
    
    buffer_we <= is_layer_1 and outputValid_convToMux;
    
    intermediate_buffer : sfixed_fifo port map (
        clk => clk,
        reset => reset,
        write_en => buffer_we,
        lyr_nmbr => lyr_nmbr,
        data_in => pixelOut_convToMux,
        data_out => pixel_bufToMux
    );

    mux : process(clk)
    begin
        if rising_edge(clk) then
            --if lyr_nmbr = 0 then
                pixel_MuxToBias <= pixelOut_convToMux;
                valid_MuxToBias <= outputValid_convToMux;
            --elsif lyr_nmbr = 1 or lyr_nmbr = 2 then
            --    if final_set = '1' then
            --        pixel_MuxToBias <= resize(pixelOut_convToMux + pixel_bufToMux, BITS_INT_PART-1, -BITS_FRAC_PART);
            --        valid_MuxToBias <= outputValid_convToMux;
            --    else
            --        pixel_MuxToBias <= (others => '0');
            --        valid_MuxToBias <= '0';
            --    end if;
            --end if;
        end if;

    end process;
	
	add_bias : process(clk)
	begin
	   if rising_edge(clk) then
	       pixel_biasToTanh <= resize(bias + pixel_MuxToBias, BITS_INT_PART-1, -BITS_FRAC_PART);
	       valid_biasToTanh <= valid_MuxToBias;
	   end if;
	end process;
	
    activation_function : tan_h port map (
	    clk => clk,
	    in_valid => valid_biasToTanh,
        tanh_in => pixel_biasToTanh(BITS_INT_PART-1 downto -BITS_FRAC_PART),
        out_valid => pixelValid_TanhToAvgPool,
        tanh_out => pxl_tanh_pool
	);

	
	avg_pooler : average_pooler port map ( 
		clk 			=> clk,
        reset           => reset,
        convol_en			=> convol_en,
        lyr_nmbr        => lyr_nmbr,
        wt_in       => bias,
        wt_we       => wt_we,
        in_valid		=> pixelValid_TanhToAvgPool,
        data_in         => pxl_tanh_pool,
        data_out		=> pixelOut_AvgPoolToScaleFactor,
	  	out_valid 	=> pixelValid_AvgPoolToScaleFactor,
        wt_out   => wt_pool_bias2
    );

    apply_scale_factor : process(clk)
    begin
        if rising_edge(clk) then
            pixelOut_ScaleFactorToBias2 <= resize(scaling*pixelOut_AvgPoolToScaleFactor, BITS_INT_PART-1, -BITS_FRAC_PART);
            pixelValid_ScaleFactorToBias2 <= pixelValid_AvgPoolToScaleFactor;
        end if;
    end process;
    
    
    add_bias_after_ap : process(clk)
    begin
       if rising_edge(clk) then
           pixelOut_Bias2ToTanh2 <= resize(bias2 + pixelOut_ScaleFactorToBias2, BITS_INT_PART-1, -BITS_FRAC_PART);
           pixelValid_Bias2ToTanh2 <= pixelValid_ScaleFactorToBias2;
       end if;
    end process;

    
    activation_function2 : tan_h port map (
	    clk => clk,
	    in_valid => pixelValid_Bias2ToTanh2,
        tanh_in => pixelOut_Bias2ToTanh2(BITS_INT_PART-1 downto -BITS_FRAC_PART),
        out_valid => pixelValid_Tanh2ToOut,
        tanh_out => pxl_tanh_out
	);

    FixedToFloat : process (clk)
    begin
        if rising_edge(clk) then
            pixelOut_F2FToOut <= to_float(pxl_tanh_pool);
            pixelValid_F2FToOut <= pixelValid_TanhToAvgPool;
        end if;
    end process;

    OutputProcess : process(clk)
    begin
        if rising_edge(clk) then
            --if lyr_nmbr = 0 then
                pxl_out <= pxl_tanh_out;
                pxl_valid <= pixelValid_Tanh2ToOut;
            --elsif lyr_nmbr = 1 then
            --    pxl_out <= to_slv(pxl_tanh_out); 
            --    pxl_valid <= pixelValid_Tanh2ToOut and (final_set);
            --else
            --    pxl_out <= to_slv(pixelOut_F2FToOut);
            --    pxl_valid <= pixelValid_F2FToOut;
            --end if;
        end if;
    end process;
    
    bias2_register : process (clk)
    begin
        if rising_edge(clk) then
            if reset = '0' then
                bias2 <= (others => '0');
            elsif wt_we = '1' then
                bias2 <= wt_pool_bias2; 
           end if;
        end if;     
    end process;

    scale_factor_reg : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '0' then
                scaling <= (others => '0');
            elsif wt_we = '1' then
                scaling <= bias2;
            end if;
        end if;
    end process;
	

end Behavioral;

