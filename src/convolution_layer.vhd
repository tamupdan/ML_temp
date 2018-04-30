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
	
	signal float_size : float32;   
    signal layer1 : std_logic;


	signal bias : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
	signal bias2 : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    signal wt_pool_bias2 : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    signal scaling : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    
	signal convol_en_con_mux : std_logic;
	signal out_vld_con_mux : std_logic;
    signal pxl_out_con_mux : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);

    signal buffer_we      : std_logic;
    signal pxl_buf_mux : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);

    signal valid_mux_bias : std_logic;
    signal pxl_mux_bias : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);

    --signal pixelValid_MuxToF2F : std_logic;
    --signal pixel_MuxToF2F : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);

    
    signal valid_bias_tanh : std_logic;
    signal pxl_bias_tanh : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    
    signal valid_tanh_pool : std_logic;
    --signal pxl_tanh_pool : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    
    signal valid_pool_scaling : std_logic;
    signal pxl_pool_scaling : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);

    signal valid_scaling_bias2 : std_logic;
    signal pxl_scaling_bias2 : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    
    signal valid_bias2_tanh2 : std_logic;
    signal pxl_bias2_tanh2 : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);

    signal valid_tanh2_out : std_logic;
    --signal pxl_tanh_out : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);

    signal valid_float_out : std_logic;
    signal pxl_float_out : float32;
    
    --signal y1        	: sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    --signal y2            : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);

    
begin

	conv : convolution port map (
		clk				=> clk,
		reset			=> reset,
		convol_en 		=> convol_en,
		lyr_nmbr        => lyr_nmbr,
		wt_we		=> wt_we,
		wt_data 	=> wt_data,
		pxl_in 		=> pxl_in,
		out_valid	=> out_vld_con_mux,--dv_conv_to_buf_and_mux,
		conv_en_out		=> convol_en_con_mux,
		pxl_out 		=> pxl_out_con_mux,--data_conv_to_buf_and_mux,
		bias    		=> bias
	
	);

    is_layer_1_process : process (lyr_nmbr)
    begin
        --if lyr_nmbr = 1 or lyr_nmbr = 2 then
            --layer1 <= '1';
        --else
            layer1 <= '0';
        --end if;
    end process;
    
    buffer_we <= layer1 and out_vld_con_mux;
    
    intermediate_buffer : sfixed_fifo port map (
        clk => clk,
        reset => reset,
        write_en => buffer_we,
        lyr_nmbr => lyr_nmbr,
        data_in => pxl_out_con_mux,
        data_out => pxl_buf_mux
    );

    mux : process(clk)
    begin
        if rising_edge(clk) then
            --if lyr_nmbr = 0 then
                pxl_mux_bias <= pxl_out_con_mux;
                valid_mux_bias <= out_vld_con_mux;
            --elsif lyr_nmbr = 1 or lyr_nmbr = 2 then
            --    if final_set = '1' then
            --        pxl_mux_bias <= resize(pxl_out_con_mux + pxl_buf_mux, BITS_INT_PART-1, -BITS_FRAC_PART);
            --        valid_mux_bias <= out_vld_con_mux;
            --    else
            --        pxl_mux_bias <= (others => '0');
            --        valid_mux_bias <= '0';
            --    end if;
            --end if;
        end if;

    end process;
	
	add_bias : process(clk)
	begin
	   if rising_edge(clk) then
	       pxl_bias_tanh <= resize(bias + pxl_mux_bias, BITS_INT_PART-1, -BITS_FRAC_PART);
	       valid_bias_tanh <= valid_mux_bias;
	   end if;
	end process;
	
    activation_function : tan_h port map (
	    clk => clk,
	    in_valid => valid_bias_tanh,
        tanh_in => pxl_bias_tanh(BITS_INT_PART-1 downto -BITS_FRAC_PART),
        out_valid => valid_tanh_pool,
        tanh_out => pxl_tanh_pool
	);

	
	avg_pooler : average_pooler port map ( 
		clk 			=> clk,
        reset           => reset,
        convol_en			=> convol_en,
        lyr_nmbr        => lyr_nmbr,
        wt_in       => bias,
        wt_we       => wt_we,
        in_valid		=> valid_tanh_pool,
        data_in         => pxl_tanh_pool,
        data_out		=> pxl_pool_scaling,
	  	out_valid 	=> valid_pool_scaling,
        wt_out   => wt_pool_bias2
    );

    apply_scaling : process(clk)
    begin
        if rising_edge(clk) then
            pxl_scaling_bias2 <= resize(scaling*pxl_pool_scaling, BITS_INT_PART-1, -BITS_FRAC_PART);
            valid_scaling_bias2 <= valid_pool_scaling;
        end if;
    end process;
    
    
    adding_bias_pooler : process(clk)
    begin
       if rising_edge(clk) then
           pxl_bias2_tanh2 <= resize(bias2 + pxl_scaling_bias2, BITS_INT_PART-1, -BITS_FRAC_PART);
           valid_bias2_tanh2 <= valid_scaling_bias2;
       end if;
    end process;

    
    activation_function2 : tan_h port map (
	    clk => clk,
	    in_valid => valid_bias2_tanh2,
        tanh_in => pxl_bias2_tanh2(BITS_INT_PART-1 downto -BITS_FRAC_PART),
        out_valid => valid_tanh2_out,
        tanh_out => pxl_tanh_out
	);

    FixedToFloat : process (clk)
    begin
        if rising_edge(clk) then
            pxl_float_out <= to_float(pxl_tanh_pool);
            valid_float_out <= valid_tanh_pool;
        end if;
    end process;

    OutputProcess : process(clk)
    begin
        if rising_edge(clk) then
            --if lyr_nmbr = 0 then
                pxl_out <= pxl_tanh_out;
                pxl_valid <= valid_tanh2_out;
            --elsif lyr_nmbr = 1 then
            --    pxl_out <= to_slv(pxl_tanh_out); 
            --    pxl_valid <= valid_tanh2_out and (final_set);
            --else
            --    pxl_out <= to_slv(pxl_float_out);
            --    pxl_valid <= valid_float_out;
            --end if;
        end if;
    end process;
    
    bias2_reg : process (clk)
    begin
        if rising_edge(clk) then
            if reset = '0' then
                bias2 <= (others => '0');
            elsif wt_we = '1' then
                bias2 <= wt_pool_bias2; 
           end if;
        end if;     
    end process;

    scaling_reg : process(clk)
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

