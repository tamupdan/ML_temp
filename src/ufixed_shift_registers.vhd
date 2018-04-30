library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

entity sfixed_shift_registers is
    generic (
        STORE_PXL_REG : Natural := 8;
        BITS_INT_PART : Natural := 8;
        BITS_FRAC_PART : Natural := 8
    );
    port (
        clk : in std_logic;
        reset : in std_logic;
        we : in std_logic;
        out_reg : in Natural;
        data_in : in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
        data_out : out sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART)
    );
    

end sfixed_shift_registers;

architecture Behavioral of sfixed_shift_registers is

    component sfixed_buffer
        generic (
            BITS_INT_PART : Natural := BITS_INT_PART;
            BITS_FRAC_PART : Natural := BITS_FRAC_PART
        );
        port (
            clk : in std_logic;
            reset : in std_logic;
            we : in std_logic;
            data_in : in sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
            data_out : out sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART)
        );
    end component;
    
    type arr is array (STORE_PXL_REG-1 downto 0) of sfixed(BITS_INT_PART-1 downto -BITS_FRAC_PART);
    
    signal reg_vals : arr; 

begin

    assign_output : process(out_reg, reg_vals)
    begin
        if out_reg >= 0 then
            data_out <= reg_vals(out_reg);
        elsif out_reg = 0 then
            data_out <= data_in;
        else
            data_out <= reg_vals(0);
        end if;
    end process;
    
    looping : for reg in 0 to STORE_PXL_REG-1 generate
    begin
    
        first_reg: if reg = 0 generate
        begin
            shift_reg : sfixed_buffer port map (
                clk => clk,
                reset => reset,
                we => we,
                data_in => data_in,
                data_out => reg_vals(reg)
            );
        end generate;
        
        other_reg: if reg > 0 generate
        begin
            shift_reg : sfixed_buffer port map (
                clk => clk,
                reset => reset,
                we => we,
                data_in => reg_vals(reg-1),
                data_out => reg_vals(reg)
            );
        end generate;
    
    end generate;

    
end Behavioral;

