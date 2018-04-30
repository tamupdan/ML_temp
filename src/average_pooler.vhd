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

    constant POOL_ARRAY_MAX_DIM : Natural := IMG_DIM/POOLING_DIM;
	--type states is (find_max, end_of_row,wait_for_new_row, finished);

	type arr is array(POOL_ARRAY_MAX_DIM-2 downto 0) of sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
	
	signal buff_vals : arr;
	signal rst : std_logic;
	signal wt_buff : std_logic;
    signal pooling_sum	     : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    signal weight        : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    signal valid_out_buff : std_logic;
	signal pool_ele : Natural range 0 to POOL_ARRAY_MAX_DIM-1 := 0;
    signal buff_rst : std_logic;

    signal sum_avg : sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    signal sum_avg_valid : std_logic;

    signal POOL_ARRAY_DIM : Natural;
    
begin

    buff_rst <= reset and rst;

    array_dimension : process(lyr_nmbr)
    begin
        --if lyr_nmbr = 0 then
            POOL_ARRAY_DIM <= POOL_ARRAY_MAX_DIM;
        --else
            --POOL_ARRAY_DIM <= ((IMG_DIM/2)-KERNEL_DIM+1)/POOLING_DIM;
        --end if;
    end process;
    
	buffer_values : for i in 0 to POOL_ARRAY_MAX_DIM-2 generate
	begin
		first_buffer : if i = 0 generate
		begin
			uf_buffer : sfixed_buffer port map (
				clk => clk,
				reset => buff_rst,
				we => wt_buff,
				data_in => pooling_sum,
				data_out => buff_vals(i)
			);
		end generate;
		
		other_buffers : if i > 0 generate
		begin
			uf_buffer : sfixed_buffer port map (
				clk => clk,
				reset => buff_rst,
				we => wt_buff,
				data_in => buff_vals(i-1),
				data_out => buff_vals(i)
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
                rst <= '1';
                wt_buff <= '0';
                tanh_in := 0;
                tanh_out := 0;
                pool_ele <= 0;
            elsif in_valid = '1' then
                if tanh_in = POOLING_DIM-1 and tanh_out = POOLING_DIM-1 then
                    if pool_ele = POOL_ARRAY_DIM-1 then
                        valid_out_buff <= '1';
                        rst <= '0';
                        wt_buff <= '0';
                        tanh_in := 0;
                        tanh_out := 0;
                        pool_ele <= 0;
                    else
                        valid_out_buff <= '1';
                        rst <= '1';
                        wt_buff <= '1';
                        tanh_in := 0;
                        pool_ele <= pool_ele + 1; 
                    end if;
                elsif tanh_in = POOLING_DIM-1 then
                    valid_out_buff <= '0';
                    tanh_in := 0;
                    wt_buff <= '1';
                    rst <= '1';
                    if pool_ele = POOL_ARRAY_DIM-1 then 
                        tanh_out := tanh_out + 1;
                        pool_ele <= 0;
                    else
                        pool_ele <= pool_ele + 1;
                    end if;
                else
                    tanh_in := tanh_in + 1;
                    valid_out_buff <= '0';
                    rst <= '1';
                    wt_buff <= '0';                        
                end if;
            else
                valid_out_buff <= '0';
                rst <= '1';
                wt_buff <= '0';
            end if;
	   end if;
	end process;
	
    sum : process(clk)
	begin
        if rising_edge(clk) then
            if convol_en = '0' or rst = '0' or reset = '0' then
                pooling_sum <= (others => '0');
            elsif in_valid = '1' then
                if wt_buff = '1' then
                    pooling_sum <= resize(data_in + buff_vals(POOL_ARRAY_DIM-2), BITS_INT_PART-1, -BITS_FRAC_PART);
                else
                    pooling_sum <= resize(data_in + pooling_sum, BITS_INT_PART-1, -BITS_FRAC_PART);
                end if;
            elsif wt_buff = '1' then
                pooling_sum <= buff_vals(POOL_ARRAY_DIM-2);
            end if;
        end if; 
	end process;

    wt_reg : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '0' then
                weight <= (others => '0');
            elsif wt_we = '1' then
                weight <= wt_in;
            end if;
        end if;
    end process;

    avg_reg : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '0' then
                sum_avg <= (others => '0');
                sum_avg_valid <= '0';
            else
                sum_avg <= resize(weight*pooling_sum, BITS_INT_PART-1, -BITS_FRAC_PART);
                sum_avg_valid <= valid_out_buff;
            end if;
        end if;
    end process;

    output : process(clk)
    begin
        if rising_edge(clk) then
            out_valid <= sum_avg_valid;
            data_out <= sum_avg;
        end if;
    end process;

    wt_out <= weight;
    
end Behavioral;
