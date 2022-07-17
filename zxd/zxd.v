//-------------------------------------------------------------------------------------------------
module zxd
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock50,

	output wire        VGA_VS,
   output wire        VGA_HS,
	output wire[ 5:0]  VGA_R,
  	output wire[ 5:0]  VGA_G,
	output wire[ 5:0]  VGA_B,

	inout  wire       ps2kCk,
	inout  wire       ps2kDQ,
	inout  wire       ps2mCk,
	inout  wire       ps2mDQ,

	output wire       sdcCs,
	output wire       sdcCk,
	output wire       sdcMosi,
	input  wire       sdcMiso,
	
   output wire       joyS,
	output wire       joyCk,
	output wire       joyLd,
	input  wire       joyD,

	output wire       sramWe,
	output wire       sramOe,
	output wire       sramUb,
	output wire       sramLb,

   output wire[12:0] SDRAM_A,
   inout  wire[15:0] SDRAM_DQ,
   output wire   SDRAM_DQML,
   output wire   SDRAM_DQMH,
   output wire   SDRAM_nWE,
   output wire   SDRAM_nCAS,
   output wire   SDRAM_nRAS,
   output wire   SDRAM_nCS,
   output wire[1:0] SDRAM_BA,
   output wire   SDRAM_CLK,
   output wire   SDRAM_CKE,
	
	inout  wire[15:8] sramDQ,
	output wire[20:0] sramA,
	
	input  wire       tape,
   output wire       AUDIO_L,
	output wire       AUDIO_R,
	output wire       led
);

//-------------------------------------------------------------------------------------------------

//IBUFG ibufMcu   (.I(clock50), .O(clk_50_g));
//IBUFG ibufgGuest(.I(clock50), .O(clk_50_m));

wire clk_50,clk_sys,clk_ram,clk_100,clk_25,locked;

clock clock
( .CLK_IN1 (clock50),
  .RESET   (1'b0),
  .CLK_OUT1(clk_50),
  .CLK_OUT2(clk_sys),
  .CLK_OUT3(clk_ram),
  .CLK_OUT4(clk_100),
  .CLK_OUT5(clk_25),
  .LOCKED  (locked)
);

ODDR2 oddr_ram
(
	.Q       (SDRAM_CLK), // 1-bit DDR output data
	.C0      ( clk_ram ), // 1-bit clock input
	.C1      (~clk_ram ), // 1-bit clock input
	.CE      (1'b1   ), // 1-bit clock enable input
	.D0      (1'b1   ), // 1-bit data input (associated with C0)
	.D1      (1'b0   ), // 1-bit data input (associated with C1)
	.R       (1'b0   ), // 1-bit reset input
	.S       (1'b0   )  // 1-bit set input
);


//------------------------------------------------------------------------------------------------

wire [7:0] joy_0, joy_1;
assign joyS=VGA_HS;


joystick Joystick
(
   .clock (clk_50),
	.ce    (1'b1),
	.joy1  (joy_0),
	.joy2  (joy_1),
	.joyS  (),
	.joyCk (joyCk),
	.joyLd (joyLd),
	.joyD  (joyD)
	
);

//-------------------------------------------------------------------------------------------------

wire SPI_SCK = sdcCk;
wire SPI_SS2;
wire SPI_SS3;
wire SPI_SS4;
wire CONF_DATA0;
wire SPI_DO;
wire SPI_DI;

wire kbiCk = ps2kCk;
wire kbiDQ = ps2kDQ;
wire moiCk = ps2mCk;
wire moiDQ = ps2mDQ;
wire kboCk; assign ps2kCk = kboCk ? 1'bZ : kboCk;
wire kboDQ; assign ps2kDQ = kboDQ ? 1'bZ : kboDQ;
wire mooCk; assign ps2mCk = mooCk ? 1'bZ : mooCk;
wire mooDQ; assign ps2mDQ = mooDQ ? 1'bZ : mooDQ;

wire spi_fromguest;
wire spi_toguest;

substitute_mcu #(.sysclk_frequency(500)) controller
(
	.clk          (clk_50),
	.reset_in     (1'b1   ),
	.reset_out    (       ),
	.spi_cs       (sdcCs  ),
	.spi_clk      (sdcCk  ),
	.spi_mosi     (sdcMosi),
	.spi_miso     (sdcMiso),
	.spi_req      (       ),
	.spi_ack      (1'b1   ),
	.spi_ss2      (SPI_SS2 ),
	.spi_ss3      (SPI_SS3 ),
	.spi_ss4      (SPI_SS4 ),
	.conf_data0   (CONF_DATA0),
	.spi_toguest  (spi_toguest),
	.spi_fromguest(spi_fromguest),
	.ps2k_clk_in  (kbiCk  ),
	.ps2k_dat_in  (kbiDQ  ),
	.ps2k_clk_out (kboCk  ),
	.ps2k_dat_out (kboDQ  ),
	.ps2m_clk_in  (moiCk  ),
	.ps2m_dat_in  (moiDQ   ),
	.ps2m_clk_out (mooCk   ),
	.ps2m_dat_out (mooDQ   ),
	.joy1         (~joy_0 ),
	.joy2         (~joy_1 ),
	.joy3         (8'hFF  ),
	.joy4         (8'hFF  ),
	.buttons      (8'hFF  ),
	.rxd          (1'b0   ),
	.txd          (       ),
	.intercept    (       ),
	.c64_keys     (64'hFFFFFFFF)
);

guest_mist guest_mist
(
		.CLOCK_27  (),
		.CLK_SYS_S (clk_sys),
		.CLK_MEM_S (clk_ram),
		.CLK_100   (clk_100),
		.CLK_25    (clk_25),
		.PLL_LOCKED(locked),
		.SDRAM_DQ (SDRAM_DQ),
		.SDRAM_A    (SDRAM_A),
		.SDRAM_DQML (SDRAM_DQML),
		.SDRAM_DQMH (SDRAM_DQMH),
		.SDRAM_nWE (SDRAM_nWE),
		.SDRAM_nCAS (SDRAM_nCAS),
		.SDRAM_nRAS (SDRAM_nRAS),
		.SDRAM_nCS (SDRAM_nCS),
		.SDRAM_BA (SDRAM_BA),
		.SDRAM_CLK (),
		.SDRAM_CKE (SDRAM_CKE),
		
		.SPI_DO (spi_fromguest),
		.SPI_DI (spi_toguest),
		.SPI_SCK (SPI_SCK),
		.SPI_SS2	(SPI_SS2),
		.SPI_SS3 (SPI_SS3),
//		.SPI_SS4 (SPI_SS4),
		.CONF_DATA0 (CONF_DATA0),
 
      .LED    (led),
		
		.UART_RX (tape),
  
		.VGA_HS (VGA_HS),
		.VGA_VS (VGA_VS),
		.VGA_R  (VGA_R),
		.VGA_G  (VGA_G),
		.VGA_B  (VGA_B),
		.AUDIO_L  (AUDIO_L),
		.AUDIO_R  (AUDIO_R)
);

//-------------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
