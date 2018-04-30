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
            STORE_PXL_REG : Natural := IMG_DIM-KERNEL_DIM;
            BITS_INT_PART : Natural := BITS_INT_PART;
            BITS_FRAC_PART : Natural := BITS_FRAC_PART
        );
        port (
            clk : in std_logic;
            reset : in std_logic;
            we : in std_logic;
            out_reg : in Natural;
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
            wt_in : in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
            mul_val : in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
            acc_val : in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
            mac_wt_out : out sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
            result : out sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART)
        );
    end component;

    
    type arr is array (KERNEL_DIM-1 downto 0) of sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    type arr_of_arr is array (KERNEL_DIM-1 downto 0) of arr;
    signal weight_values : arr_of_arr;
    signal acc_values : arr_of_arr;
    type arr_reg is array (KERNEL_DIM-2 downto 0) of sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    signal shift_reg_output : arr_reg;
    
    signal out_reg_nmbr : Natural;
    

begin

    pxl_out <= acc_values(KERNEL_DIM-1)(KERNEL_DIM-1);
    
    controller : conv_controller port map (
        clk => clk,
        convol_en => convol_en,
        lyr_nmbr => lyr_nmbr,
        out_valid => out_valid
    );

    mac_row: for row in 0 to KERNEL_DIM-1 generate
        mac_col: for col in 0 to KERNEL_DIM-1 generate
            begin
            
                mac_top_left : if row = 0 and col = 0 generate
                begin
                    mac1 : mac port map (
                        clk => clk,
                        reset => reset,
                        wt_we => wt_we,
                        wt_in => wt_data,
                        mul_val => pxl_in,
                        acc_val => (others => '0'),
                        mac_wt_out => weight_values(row)(col),
                        result => acc_values(row)(col)
                    );
                end generate;
                
                mac_left_down : if row > 0 and col = 0 generate
                begin
                    mac1 : mac port map (
                        clk => clk,
                        reset => reset,
                        wt_we => wt_we,
                        wt_in => weight_values(row-1)(KERNEL_DIM-1),
                        mul_val => pxl_in,
                        acc_val => shift_reg_output(row-1),
                        mac_wt_out => weight_values(row)(col),
                        result => acc_values(row)(col)
                    );
                end generate;
                
                mac_other : if (col > 0 and col < KERNEL_DIM-1) generate
                begin
                    mac3 : mac port map (
                        clk => clk,
                        reset => reset,
                        wt_we => wt_we,
                        wt_in => weight_values(row)(col-1),
                        mul_val => pxl_in,
                        acc_val => acc_values(row)(col-1),
                        mac_wt_out => weight_values(row)(col),
                        result => acc_values(row)(col)
                    );
                end generate;
                
                mac_last : if col = KERNEL_DIM-1  generate
                begin
                    mac4 : mac port map (
                        clk => clk,
                        reset => reset,
                        wt_we => wt_we,
                        wt_in => weight_values(row)(col-1),
                        mul_val => pxl_in,
                        acc_val => acc_values(row)(col-1),
                        mac_wt_out => weight_values(row)(col),
                        result => acc_values(row)(col)
                    );
                end generate;
                
                shift_regs : if row < KERNEL_DIM-1 and col = KERNEL_DIM-1 generate
                begin
                    sr : sfixed_shift_registers port map (
                        clk => clk,
                        reset => reset,
                        we => convol_en,
                        out_reg => out_reg_nmbr,
                        data_in => acc_values(row)(col),
                        data_out => shift_reg_output(row)
                    );
                end generate;
                
        end generate;
    end generate;
    
    reg_number : process(lyr_nmbr)
    begin
        --if lyr_nmbr = 0 then
            out_reg_nmbr <= IMG_DIM-KERNEL_DIM-1;
        --elsif lyr_nmbr = 1 then
        --    out_reg_nmbr <= ((IMG_DIM-KERNEL_DIM+1)/2)-KERNEL_DIM-1;
        --else
        --    out_reg_nmbr <= 0;
        --end if; 
    end process;
    
    bias_reg_val : process(clk, reset)
    begin
        if rising_edge(clk) then
            if reset = '0' then
                bias <= (others => '0');
            elsif wt_we = '1' then
                bias <= weight_values(KERNEL_DIM-1)(KERNEL_DIM-1);
            end if; 
        end if;
    end process;
    
    convol_enable : process(clk) 
    begin
        if rising_edge(clk) then
            conv_en_out <= convol_en;
        end if;
    end process;
    
    
end Behavioral;
