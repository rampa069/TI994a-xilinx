--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:24:49 04/02/2017
-- Design Name:   
-- Module Name:   C:/Users/Erik Piehl/Dropbox/Omat/trunk/EP994A/fpga/src/tb_tms9900.vhd
-- Project Name:  ep994a
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: tms9900
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;

USE STD.TEXTIO.ALL;
USE IEEE.STD_LOGIC_TEXTIO.ALL;
 
ENTITY tb_tms9900 IS
END tb_tms9900;
 
ARCHITECTURE behavior OF tb_tms9900 IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT tms9900
    PORT(
         clk : IN  std_logic;
         reset : IN  std_logic;
         addr_out : OUT  std_logic_vector(15 downto 0);
         data_in : IN  std_logic_vector(15 downto 0);
         data_out : OUT  std_logic_vector(15 downto 0);
         rd : OUT  std_logic;
         wr : OUT  std_logic;
         ready : IN  std_logic;
         iaq : OUT  std_logic;
         as : OUT  std_logic;
			cpu_debug_out : out STD_LOGIC_VECTOR (95 downto 0);
--			test_out : OUT  std_logic_vector(15 downto 0);
--			alu_debug_out : OUT  std_logic_vector(15 downto 0);
--			alu_debug_oper : out STD_LOGIC_VECTOR(3 downto 0);
			alu_debug_arg1 : OUT  std_logic_vector(15 downto 0);
			alu_debug_arg2 : OUT  std_logic_vector(15 downto 0);
			mult_debug_out : out STD_LOGIC_VECTOR (35 downto 0);	
			int_req	: in STD_LOGIC;		-- interrupt request, active high
			ic03     : in STD_LOGIC_VECTOR(3 downto 0);	-- interrupt priority for the request, 0001 is the highest (0000 is reset)
			int_ack	: out STD_LOGIC;
			cruin		: in STD_LOGIC;
			cruout   : out STD_LOGIC;
			cruclk   : out STD_LOGIC;
			hold     : in STD_LOGIC;		-- DMA request, active high
			holda    : out STD_LOGIC;     -- DMA ack, active high
			waits    : in STD_LOGIC_VECTOR(5 downto 0);
			scratch_en : in STD_LOGIC;		-- when 1 in-core scratchpad RAM is enabled
         stuck : OUT  std_logic
        );
    END COMPONENT;
	 
	 COMPONENT TESTROM
	 PORT (
		clk : IN  std_logic;
      addr : in  STD_LOGIC_VECTOR (11 downto 0);
      data_out : out  STD_LOGIC_VECTOR (15 downto 0));
	 END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal data_in : std_logic_vector(15 downto 0) := (others => '0');
   signal ready : std_logic := '0';
	signal cruin : std_logic := '0';
	signal int_req	: STD_LOGIC := '0';		-- interrupt request, active high
	signal ic03    : STD_LOGIC_VECTOR(3 downto 0) := "0001";	-- interrupt priority for the request, 0001 is the highest (0000 is reset)
	signal int_ack : STD_LOGIC;

 	--Outputs
   signal addr : std_logic_vector(15 downto 0);
   signal data_out : std_logic_vector(15 downto 0);
   signal rd : std_logic;
   signal wr : std_logic;
   signal iaq : std_logic;
   signal as : std_logic;
	signal cpu_debug_out : STD_LOGIC_VECTOR (95 downto 0);
--	signal test_out : STD_LOGIC_VECTOR (15 downto 0);
--	signal alu_debug_out : STD_LOGIC_VECTOR (15 downto 0);
--	signal alu_debug_oper : STD_LOGIC_VECTOR (3 downto 0);
	signal alu_debug_arg1 : STD_LOGIC_VECTOR (15 downto 0);
	signal alu_debug_arg2 : STD_LOGIC_VECTOR (15 downto 0);
	signal mult_debug_out : STD_LOGIC_VECTOR (35 downto 0);
	signal cruout : std_logic;
	signal cruclk : std_logic;
   signal stuck : std_logic;
	signal hold : std_logic := '0';
	signal holda : std_logic;
	
	signal cpu_st : std_logic_vector(15 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;

	signal rom_data : STD_LOGIC_VECTOR (15 downto 0);
	
	-- RAM block to 8300
	type ramArray is array (0 to 127) of STD_LOGIC_VECTOR (15 downto 0);
	signal scratchpad : ramArray;
	signal ramIndex : integer range 0 to 15 := 0;
	signal write_detect : std_logic_vector(1 downto 0);
	
	signal prev_cruclk : std_logic;
	
--	constant cru_test_data : std_logic_vector(15 downto 0) := x"A379";
	signal cru_test_data : std_logic_vector(15 downto 0) := x"A379";
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: tms9900 PORT MAP (
          clk => clk,
          reset => reset,
          addr_out => addr,
          data_in => data_in,
          data_out => data_out,
          rd => rd,
          wr => wr,
          ready => ready,
          iaq => iaq,
          as => as,
--			 test_out => test_out,
--			 alu_debug_out => alu_debug_out,
--			 alu_debug_oper => alu_debug_oper,
			 alu_debug_arg1 => alu_debug_arg1,
			 alu_debug_arg2 => alu_debug_arg2,
			 mult_debug_out => mult_debug_out,
			 cpu_debug_out => cpu_debug_out,
			 int_req => int_req,
			 ic03 => ic03,
			 int_ack => int_ack,
			 cruin => cruin,
			 cruout => cruout,
			 cruclk => cruclk,
			 hold => hold,
			 holda => holda,
			 waits => "000000", -- "111111", -- "000000",
 		 	 scratch_en => '1',
          stuck => stuck
        );
		  
	ROM: TESTROM PORT MAP(
		clk => clk,
		addr => addr(12 downto 1),
		data_out => rom_data
		);

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
	
   -- Stimulus process
   stim_proc: process
	variable addr_int : integer range 0 to 32767 := 0;
	variable my_line : line;	-- from textio
	variable myindex : natural range 0 to 15;	
   begin		
      -- hold reset state for 100 ns.
		reset <= '1';
      wait for 100 ns;	
		reset <= '0';
      -- wait for clk_period*20;
      -- insert stimulus here 
		
		for i in 0 to 29999 loop
			wait for clk_period/2;
			
			-- Test hold logic
			if i = 2000 then 
				hold <= '1';
			elsif i = 2200 then
				hold <= '0';
			end if;
			
			-- test interrupt behaviour
			if i = 2400 then
				int_req <= '1';
			elsif i = 2500 then
				int_req <= '0';
			end if;
			
			-- read CPU status
			cpu_st <= cpu_debug_out(63 downto 48);
			
			if rd='1' then
				addr_int := to_integer( unsigned( addr(15 downto 1) ));	-- word address
				if addr_int >= 0 and addr_int <= 4095 then
					data_in <= rom_data;
				elsif addr_int >= 16768 and addr_int < 16896 then	-- scratch pad memory range in words
					-- we're in the scratchpad
					data_in <= scratchpad( addr_int - 16768 );
				else
					data_in <= x"DEAD";
				end if;
			else
				data_in <= (others => 'Z');
			end if;
			
			write_detect <= write_detect(0) & wr;
			if wr = '1' then
				addr_int := to_integer( unsigned( addr(15 downto 1) ));	-- word address
				if addr_int >= 16768 and addr_int < 16896 then	-- scratch pad memory range in words
					-- we're in the scratchpad
					scratchpad( addr_int - 16768 ) <= data_out;
				end if;
				if write_detect = "01" then 
					write(my_line, STRING'("write to "));
					hwrite(my_line, addr);
					-- If in 8300..831F assume it is a register, print its name
					if addr_int >= 16768 and addr_int < 16784 then
						write(my_line, STRING'(" R"));
						write(my_line, addr_int - 16768);
						write(my_line, STRING'(" "));
					else
						write(my_line, STRING'("    "));
					end if;
					write(my_line, STRING'(" data "));
					hwrite(my_line, data_out);
					write(my_line, STRING'("               "));
					write(my_line, data_out);
					writeline(OUTPUT, my_line);
				end if;
			end if;
			
			-- Support CRU interface somehow
			myindex := to_integer(unsigned(addr(4 downto 1)));
			cruin <= cru_test_data(myindex);
			
			prev_cruclk <= cruclk;
			if prev_cruclk='0' and cruclk='1' then 
				-- rising edge
				cru_test_data(myindex) <= cruout;
			end if;
			
			if stuck='1' then
				write(my_line, STRING'("CPU GOT STUCK"));
				writeline(OUTPUT, my_line);
				exit;
			end if;
			
		end loop;
		

      wait;
   end process;

END;
