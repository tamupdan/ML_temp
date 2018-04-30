library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity convolution_contrl is
	generic (	
		IMAGE_DIM 	: Natural := 3;
		KERNEL_DIM 	: Natural := 2
	);
	port (
		clk 				: in  std_logic;
		convol_en 			: in  std_logic;
        lyr_nmbr            : in Natural;
		out_valid 	    : out std_logic
	);
end convolution_contrl;

architecture Behavioral of convolution_contrl is

	signal row 				: Natural range 0 to IMAGE_DIM := 0;
	signal col 			: Natural range 0 to IMAGE_DIM := 0;
	signal row_end 	: std_logic;
	
	signal buffer_convol_en	: std_logic;
	
	--signal valid_out_buff			: std_logic;

    signal current_dim : natural; 

begin

    setting_img_dim : process(lyr_nmbr)
    begin
        if lyr_nmbr = 0 then
            current_dim <= IMAGE_DIM;
        elsif lyr_nmbr = 1 then
            current_dim <= (IMAGE_DIM-KERNEL_DIM+1)/2;
        else
            current_dim <= (((IMAGE_DIM-KERNEL_DIM+1)/2)-KERNEL_DIM+1)/2;
        end if;
    end process;

	count_pixels : process (clk)
	begin
		if rising_edge(clk) then
			buffer_convol_en <= convol_en;
			if convol_en = '1' then
				if (col = current_dim and row = current_dim) then
					row <= 1;
					col <= 1;
					row_end <= '0';
				
				else
					if (col = current_dim) then
						col <= 1;
						row <= row + 1;
					else
						col <= col + 1;
					end if;
					
					if (row = KERNEL_DIM) then
						row_end <= '1';
					end if;
				end if;
			else
				row <= 1;
				col <= 0;
				row_end <= '0';
			end if;
		end if;
	end process;
	
	is_out_valid : process(clk)
	begin
		if rising_edge(clk) then
			if buffer_convol_en = '1' and row_end = '1' and (col >= KERNEL_DIM-1 and col < current_dim) then
				out_valid <= '1';
			else 
				out_valid <= '0';
			end if;
		end if;
	end process;

end Behavioral;

