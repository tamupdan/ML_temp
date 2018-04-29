library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

entity average_pooler is
	generic (
	    IMG_DIM : Natural := 6;
        KERNEL_DIM : Natural := 3;
		POOL_DIM : Natural := 2;
		INT_WIDTH : Natural := 8;
		FRAC_WIDTH : Natural := 8
	);
	Port ( 
		clk : in std_logic;
        reset : in std_logic;
        convol_en : in std_logic;
        lyr_nmbr : in Natural;
        weight_in : in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
        wt_we : in std_logic;
		input_valid : in std_logic;
		data_in : in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
		data_out : out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
		output_valid : out std_logic;
		output_weight : out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH)
	);
end average_pooler;

architecture Behavioral of average_pooler is

	component sfixed_buffer is
		generic (
			INT_WIDTH 	: positive := INT_WIDTH;
			FRAC_WIDTH 	: positive := FRAC_WIDTH
		);
		Port ( 
			clk 		: in std_logic;
			reset		: in std_logic;
			we 		: in std_logic;
			data_in 	: in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			data_out : out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH)
		);
	end component;

    constant POOL_ARRAY_DIM_MAX : Natural := IMG_DIM/POOL_DIM;
	type states is (find_max, end_of_row,wait_for_new_row, finished);

	type sfixed_array is array(POOL_ARRAY_DIM_MAX-2 downto 0) of sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
	signal buffer_values : sfixed_array;
	signal reset_buffers : std_logic;
	signal write_buffers : std_logic;
    signal pool_sum	     : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    signal weight        : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    signal output_valid_buf : std_logic;
	signal pool_x : Natural range 0 to POOL_ARRAY_DIM_MAX-1 := 0;
    signal buf_reset : std_logic;

    signal averaged_sum : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    signal averaged_sum_valid : std_logic;

    signal POOL_ARRAY_DIM : Natural;
    
begin

    buf_reset <= reset and reset_buffers;

    set_array_dim : process(lyr_nmbr)
    begin
        --if lyr_nmbr = 0 then
            POOL_ARRAY_DIM <= POOL_ARRAY_DIM_MAX;
        --else
            --POOL_ARRAY_DIM <= ((IMG_DIM/2)-KERNEL_DIM+1)/POOL_DIM;
        --end if;
    end process;
    
	generate_buffers : for i in 0 to POOL_ARRAY_DIM_MAX-2 generate
	begin
		first_buffer : if i = 0 generate
		begin
			uf_buffer : sfixed_buffer port map (
				clk => clk,
				reset => buf_reset,
				we => write_buffers,
				data_in => pool_sum,
				data_out => buffer_values(i)
			);
		end generate;
		
		other_buffers : if i > 0 generate
		begin
			uf_buffer : sfixed_buffer port map (
				clk => clk,
				reset => buf_reset,
				we => write_buffers,
				data_in => buffer_values(i-1),
				data_out => buffer_values(i)
			);
		end generate;
	end generate;
	
    controller : process(clk)
        variable x : integer;
        variable y : integer;
    begin
        if rising_edge(clk) then
            if convol_en = '0' or reset = '0' then
                output_valid_buf <= '0';
                reset_buffers <= '1';
                write_buffers <= '0';
                x := 0;
                y := 0;
                pool_x <= 0;
            elsif input_valid = '1' then
                if x = POOL_DIM-1 and y = POOL_DIM-1 then
                    if pool_x = POOL_ARRAY_DIM-1 then
                        output_valid_buf <= '1';
                        reset_buffers <= '0';
                        write_buffers <= '0';
                        x := 0;
                        y := 0;
                        pool_x <= 0;
                    else
                        output_valid_buf <= '1';
                        reset_buffers <= '1';
                        write_buffers <= '1';
                        x := 0;
                        pool_x <= pool_x + 1; 
                    end if;
                elsif x = POOL_DIM-1 then
                    output_valid_buf <= '0';
                    x := 0;
                    write_buffers <= '1';
                    reset_buffers <= '1';
                    if pool_x = POOL_ARRAY_DIM-1 then 
                        y := y + 1;
                        pool_x <= 0;
                    else
                        pool_x <= pool_x + 1;
                    end if;
                else
                    x := x + 1;
                    output_valid_buf <= '0';
                    reset_buffers <= '1';
                    write_buffers <= '0';                        
                end if;
            else
                output_valid_buf <= '0';
                reset_buffers <= '1';
                write_buffers <= '0';
            end if;
	   end if;
	end process;
	
    update_sum : process(clk)
	begin
        if rising_edge(clk) then
            if convol_en = '0' or reset_buffers = '0' or reset = '0' then
                pool_sum <= (others => '0');
            elsif input_valid = '1' then
                if write_buffers = '1' then
                    pool_sum <= resize(data_in + buffer_values(POOL_ARRAY_DIM-2), INT_WIDTH-1, -FRAC_WIDTH);
                else
                    pool_sum <= resize(data_in + pool_sum, INT_WIDTH-1, -FRAC_WIDTH);
                end if;
            elsif write_buffers = '1' then
                pool_sum <= buffer_values(POOL_ARRAY_DIM-2);
            end if;
        end if; 
	end process;

    weight_reg : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '0' then
                weight <= (others => '0');
            elsif wt_we = '1' then
                weight <= weight_in;
            end if;
        end if;
    end process;

    average_reg : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '0' then
                averaged_sum <= (others => '0');
                averaged_sum_valid <= '0';
            else
                averaged_sum <= resize(weight*pool_sum, INT_WIDTH-1, -FRAC_WIDTH);
                averaged_sum_valid <= output_valid_buf;
            end if;
        end if;
    end process;

    output_reg : process(clk)
    begin
        if rising_edge(clk) then
            output_valid <= averaged_sum_valid;
            data_out <= averaged_sum;
        end if;
    end process;

    output_weight <= weight;
    
end Behavioral;
