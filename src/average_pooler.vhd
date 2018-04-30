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
		POOLING_DIM : Natural := 2;
		BITS_INT_PART : Natural := 8;
		BITS_FRAC_PART : Natural := 8
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
		out_valid : out std_logic;
		wt_out : out sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART)
	);
end average_pooler;

architecture Behavioral of average_pooler is

	component sfixed_buffer is
		generic (
			BITS_INT_PART 	: positive := BITS_INT_PART;
			BITS_FRAC_PART 	: positive := BITS_FRAC_PART
		);
		Port ( 
			clk 		: in std_logic;
			reset		: in std_logic;
			we 		: in std_logic;
			data_in 	: in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
			data_out : out sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART)
		);
	end component;

    constant POOL_ARRAY_DIM_MAX : Natural := IMG_DIM/POOLING_DIM;
	type states is (find_max, end_of_row,wait_for_new_row, finished);

	type arr is array(POOL_ARRAY_DIM_MAX-2 downto 0) of sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
	
	signal buffer_values : arr;
	signal reset_buffers : std_logic;
	signal write_buffers : std_logic;
    signal pool_sum	     : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    signal weight        : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    signal valid_out_buff : std_logic;
	signal pool_x : Natural range 0 to POOL_ARRAY_DIM_MAX-1 := 0;
    signal buf_reset : std_logic;

    signal averaged_sum : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    signal averaged_sum_valid : std_logic;

    signal POOL_ARRAY_DIM : Natural;
    
begin

    buf_reset <= reset and reset_buffers;

    set_array_dim : process(lyr_nmbr)
    begin
        --if lyr_nmbr = 0 then
            POOL_ARRAY_DIM <= POOL_ARRAY_DIM_MAX;
        --else
            --POOL_ARRAY_DIM <= ((IMG_DIM/2)-KERNEL_DIM+1)/POOLING_DIM;
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
        variable tanh_in : integer;
        variable tanh_out : integer;
    begin
        if rising_edge(clk) then
            if convol_en = '0' or reset = '0' then
                valid_out_buff <= '0';
                reset_buffers <= '1';
                write_buffers <= '0';
                tanh_in := 0;
                tanh_out := 0;
                pool_x <= 0;
            elsif in_valid = '1' then
                if tanh_in = POOLING_DIM-1 and tanh_out = POOLING_DIM-1 then
                    if pool_x = POOL_ARRAY_DIM-1 then
                        valid_out_buff <= '1';
                        reset_buffers <= '0';
                        write_buffers <= '0';
                        tanh_in := 0;
                        tanh_out := 0;
                        pool_x <= 0;
                    else
                        valid_out_buff <= '1';
                        reset_buffers <= '1';
                        write_buffers <= '1';
                        tanh_in := 0;
                        pool_x <= pool_x + 1; 
                    end if;
                elsif tanh_in = POOLING_DIM-1 then
                    valid_out_buff <= '0';
                    tanh_in := 0;
                    write_buffers <= '1';
                    reset_buffers <= '1';
                    if pool_x = POOL_ARRAY_DIM-1 then 
                        tanh_out := tanh_out + 1;
                        pool_x <= 0;
                    else
                        pool_x <= pool_x + 1;
                    end if;
                else
                    tanh_in := tanh_in + 1;
                    valid_out_buff <= '0';
                    reset_buffers <= '1';
                    write_buffers <= '0';                        
                end if;
            else
                valid_out_buff <= '0';
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
            elsif in_valid = '1' then
                if write_buffers = '1' then
                    pool_sum <= resize(data_in + buffer_values(POOL_ARRAY_DIM-2), BITS_INT_PART-1, -BITS_FRAC_PART);
                else
                    pool_sum <= resize(data_in + pool_sum, BITS_INT_PART-1, -BITS_FRAC_PART);
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
                weight <= wt_in;
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
                averaged_sum <= resize(weight*pool_sum, BITS_INT_PART-1, -BITS_FRAC_PART);
                averaged_sum_valid <= valid_out_buff;
            end if;
        end if;
    end process;

    output_reg : process(clk)
    begin
        if rising_edge(clk) then
            out_valid <= averaged_sum_valid;
            data_out <= averaged_sum;
        end if;
    end process;

    wt_out <= weight;
    
end Behavioral;
