library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

entity convolution is
    generic 	(
		IMG_DIM : Natural := 8;
		KERNEL_DIM : Natural := 3;
		BITS_INT_PART : Natural := 8;
		BITS_FRAC_PART : Natural := 8
	);
	port ( 
		clk : in std_logic;
		reset : in std_logic;
		convol_en : in std_logic;
		lyr_nmbr : in Natural;
		wt_we : in std_logic;
		wt_data : in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
		pxl_in : in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
	    
	    conv_en_out : out std_logic;
	    out_valid : out std_logic;
		pxl_out : out sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
		bias : out sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART)
	);
end convolution;

architecture Behavioral of convolution is

    component conv_controller
        generic (
            IMAGE_DIM       : Natural := IMG_DIM;
            KERNEL_DIM      : Natural := KERNEL_DIM
        );
        port (
            clk : in  std_logic;
            convol_en : in  std_logic;
            lyr_nmbr : in Natural;
            out_valid : out  std_logic
        );
        end component;

    component sfixed_shift_registers 
        generic (
            NOF_REGS : Natural := IMG_DIM-KERNEL_DIM;
            BITS_INT_PART : Natural := BITS_INT_PART;
            BITS_FRAC_PART : Natural := BITS_FRAC_PART
        );
        port (
            clk : in std_logic;
            reset : in std_logic;
            we : in std_logic;
            output_reg : in Natural;
            data_in : in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
            data_out : out sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART)
        );
    end component;
       
    
    component mac
        generic (
            BITS_INT_PART : Natural := BITS_INT_PART;
            BITS_FRAC_PART : Natural := BITS_FRAC_PART
        );
        port (
            clk : in std_logic;
            reset : in std_logic;
            wt_we : in std_logic;
            weight_in : in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
            multi_value : in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
            acc_value : in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
            weight_out : out sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
            result : out sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART)
        );
    end component;

    
    type sfixed_array is array (KERNEL_DIM-1 downto 0) of sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    type sfixed_array_of_arrays is array (KERNEL_DIM-1 downto 0) of sfixed_array;
    type sfixed_array_shift_reg is array (KERNEL_DIM-2 downto 0) of sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    
    signal weight_values : sfixed_array_of_arrays;
    signal acc_values : sfixed_array_of_arrays;
    signal shift_reg_output : sfixed_array_shift_reg;
    
    signal output_shift_reg_nr : Natural;
    

begin

    pxl_out <= acc_values(KERNEL_DIM-1)(KERNEL_DIM-1);
    
    controller : conv_controller port map (
        clk => clk,
        convol_en => convol_en,
        lyr_nmbr => lyr_nmbr,
        out_valid => out_valid
    );

    gen_mac_rows: for row in 0 to KERNEL_DIM-1 generate
        gen_mac_columns: for col in 0 to KERNEL_DIM-1 generate
            begin
            
                mac_first_leftmost : if row = 0 and col = 0 generate
                begin
                    mac1 : mac port map (
                        clk => clk,
                        reset => reset,
                        wt_we => wt_we,
                        weight_in => wt_data,
                        multi_value => pxl_in,
                        acc_value => (others => '0'),
                        weight_out => weight_values(row)(col),
                        result => acc_values(row)(col)
                    );
                end generate;
                
                mac_other_leftmost : if row > 0 and col = 0 generate
                begin
                    mac1 : mac port map (
                        clk => clk,
                        reset => reset,
                        wt_we => wt_we,
                        weight_in => weight_values(row-1)(KERNEL_DIM-1),
                        multi_value => pxl_in,
                        acc_value => shift_reg_output(row-1),
                        weight_out => weight_values(row)(col),
                        result => acc_values(row)(col)
                    );
                end generate;
                
                mac_others : if (col > 0 and col < KERNEL_DIM-1) generate
                begin
                    mac3 : mac port map (
                        clk => clk,
                        reset => reset,
                        wt_we => wt_we,
                        weight_in => weight_values(row)(col-1),
                        multi_value => pxl_in,
                        acc_value => acc_values(row)(col-1),
                        weight_out => weight_values(row)(col),
                        result => acc_values(row)(col)
                    );
                end generate;
                
                mac_rightmost : if col = KERNEL_DIM-1  generate
                begin
                    mac4 : mac port map (
                        clk => clk,
                        reset => reset,
                        wt_we => wt_we,
                        weight_in => weight_values(row)(col-1),
                        multi_value => pxl_in,
                        acc_value => acc_values(row)(col-1),
                        weight_out => weight_values(row)(col),
                        result => acc_values(row)(col)
                    );
                end generate;
                
                shift_regs : if row < KERNEL_DIM-1 and col = KERNEL_DIM-1 generate
                begin
                    sr : sfixed_shift_registers port map (
                        clk => clk,
                        reset => reset,
                        we => convol_en,
                        output_reg => output_shift_reg_nr,
                        data_in => acc_values(row)(col),
                        data_out => shift_reg_output(row)
                    );
                end generate;
                
        end generate;
    end generate;
    
    shift_reg_config : process(lyr_nmbr)
    begin
        --if lyr_nmbr = 0 then
            output_shift_reg_nr <= IMG_DIM-KERNEL_DIM-1;
        --elsif lyr_nmbr = 1 then
        --    output_shift_reg_nr <= ((IMG_DIM-KERNEL_DIM+1)/2)-KERNEL_DIM-1;
        --else
        --    output_shift_reg_nr <= 0;
        --end if; 
    end process;
    
    bias_register : process(clk, reset)
    begin
        if rising_edge(clk) then
            if reset = '0' then
                bias <= (others => '0');
            elsif wt_we = '1' then
                bias <= weight_values(KERNEL_DIM-1)(KERNEL_DIM-1);
            end if; 
        end if;
    end process;
    
    conv_reg : process(clk) 
    begin
        if rising_edge(clk) then
            conv_en_out <= convol_en;
        end if;
    end process;
    
    
end Behavioral;
