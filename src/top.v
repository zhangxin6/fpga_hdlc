`timescale 1ns / 1ps
`define DEBUG

module top(
	input           clk_in1_p           ,
	input           clk_in1_n           ,
	input           sys_rst_n           ,
	output          dsp_led_0           ,
	input   [23:0]  DSP_EMIFA           ,
	input           DSP_EMIFBE0_N       ,
	input           DSP_EMIFBE1_N       ,
	input           DSP_EMIFCE0_N       ,
	inout   [15:0]  DSP_EMIFD           ,
	input           DSP_EMIFOE_N        ,
	output          DSP_EMIFWAIT0       ,
	output          DSP_EMIFWAIT1       ,
	input           DSP_EMIFWE_N        ,
	//-------------- dsp reset ------------------------------
	//dsp reset
	output          rst_c6678_soft_n    ,
	output          rst_c6678_local_n   ,
	output          rst_c6678_por_n     ,
	output          rst_c6678_full_n    ,
	output	        dsp0_timi0			,
	output	        dsp0_timi1			,
	//Reserved     
	output          dsp0_coresel0       ,
	output          dsp0_coresel1       ,
	output          dsp0_coresel2       ,
	output          dsp0_coresel3       ,
	output          dsp0_lresetnmien_n  ,

	inout    tri    endian_dsp0         ,  // GPIO[0]
	output          boot_strap0_1       ,  // GPIO[1]
	output          boot_strap0_2       ,  // GPIO[2]
	output          boot_strap0_3       ,  // GPIO[3]
	output          boot_strap0_4       ,  // GPIO[4]
	inout    tri    boot_strap0_5       ,  // GPIO[5]
	output          boot_strap0_6       ,  // GPIO[6]
	output          boot_strap0_7       ,  // GPIO[7]
	output          boot_strap0_8       ,  // GPIO[8]
	output          boot_strap0_9       ,  // GPIO[9]
	output          boot_strap0_10      ,  // GPIO[10]
	output          boot_strap0_11      ,  // GPIO[11]
	output          boot_strap0_12      ,  // GPIO[12]
	output          boot_strap0_13      ,  // GPIO[13]
	output          boot_strap0_14      ,  // GPIO[14]
	output          boot_strap0_15      ,  // GPIO[15]
	/*******************RS485****************************/
	output          RS485_1_CLK_DE_18   ,
	output          RS485_1_CLK_D_18    ,
	output          RS485_1_CLK_PV_18   ,
	output          RS485_1_CLK_RE_18   ,
                    
	output          RS485_1_DE_18       ,
	output          RS485_1_D_18        ,
	output          RS485_1_PV_18       ,
	output          RS485_1_RE_18       ,
                    
	output          RS485_3_CLK_DE_18   ,
	output          RS485_3_CLK_PV_18   ,
	output          RS485_3_CLK_RE_18   ,
	input           RS485_3_CLK_R_18    ,
                    
	output          RS485_3_DE_18       ,
	output          RS485_3_PV_18       ,
	output          RS485_3_RE_18       ,
	input           RS485_3_R_18
	);

    wire clk_100m, clk_25m, rst_n; wire sys_rst = ~sys_rst_n;

	clk_pn_100_25(clk_100m, clk_25m,sys_rst,rst_n,clk_in1_p,clk_in1_n);

	reg [5:0] cnt_50;
    always @(posedge clk_100m or negedge rst_n)
	begin
		if(rst_n==0) cnt_50 <= 6'd0; else if (cnt_50 < 6'd49)	cnt_50 <= cnt_50 + 1; else cnt_50 <= 6'd0;
	end

    reg  clk_2m;
	always @(posedge clk_100m or negedge rst_n)
	begin 
		if(rst_n ==0) clk_2m <= 0; else if(cnt_50 >= 6'd25) clk_2m <= 1; else clk_2m <= 0;
	end

	wire  emif_dpram_wen,emif_dpram_ren;reg dsp_data_zz_en; wire  [15:00]  emif_dpram_wdata,emif_dpram_rdata; wire  [23:00] emif_dpram_addr;

	emif_intf_z u_emif_intf_z(
		.clk_100m         (clk_100m                      ),
		.rst_n            (rst_n                         ),
		.emif_data_i      (DSP_EMIFD                     ),
		.emif_addr_i      (DSP_EMIFA                     ),
		.emif_byten_i     ({DSP_EMIFBE1_N,DSP_EMIFBE0_N} ),
		.emif_cen_i       (DSP_EMIFCE0_N                 ),
		.emif_wen_i       (DSP_EMIFWE_N                  ),
		.emif_oen_i       (DSP_EMIFOE_N                  ),

		.emif_dpram_wen   (emif_dpram_wen                ),
		.emif_dpram_ren   (emif_dpram_ren                ),
		.emif_dpram_addr  (emif_dpram_addr               ),
		.emif_dpram_wdata (emif_dpram_wdata              )
		);
		
	always @(posedge clk_100m)
	begin	
		dsp_data_zz_en <= emif_dpram_ren;
	end		
		
	assign DSP_EMIFD = (dsp_data_zz_en==1'b1)? emif_dpram_rdata : 16'hzzzz ;	
		
		
	wire   trastart_flag; wire [9:0] db; wire [7:0] ramd_tx;

	dsp_hdlc_ctrl  u_dsp_hdlc_ctrl(
		.clk_100m        ( clk_100m          ),
		.clk             ( clk_2m            ),
		.rst_n           ( rst_n             ),
		.emif_dpram_wen  ( emif_dpram_wen    ),
		.emif_dpram_addr ( emif_dpram_addr   ),
		.emif_data       ( emif_dpram_wdata  ),

		.trastart_flag   ( trastart_flag     ),
	    .db              ( db                ),
	    .ramd            ( ramd_tx           )
	);

	wire datat, inr_tx;
	hdlctra  u_hdlctra(
		.clk           ( clk_2m        ),
		.rst_n         ( rst_n         ),
		.trastart_flag ( trastart_flag ),
		.db            ( db            ),
		.ramd          ( ramd_tx       ),

		.datat         ( datat         ),
	    .inr           ( inr_tx        )
	);

	cpld_top u_cpld_top(
		.hard_rst_n        (rst_n         ),
		.clk_25m_in        (clk_25m       ),
		.rst_c6678_soft_n  (rst_c6678_soft_n  ),
		.rst_c6678_local_n (rst_c6678_local_n ),
		.rst_c6678_por_n   (rst_c6678_por_n   ),
		.rst_c6678_full_n  (rst_c6678_full_n  ),
		.dsp0_rstn_state   (1  ),
		.dsp0_coresel0     (dsp0_coresel0     ),
		.dsp0_coresel1     (dsp0_coresel1     ),
		.dsp0_coresel2     (dsp0_coresel2     ),
		.dsp0_coresel3     (dsp0_coresel3     ),
		.dsp0_lresetnmien_n(dsp0_lresetnmien_n),
		.dsp0_timi0        (dsp0_timi0        ),
		.dsp0_timi1        (dsp0_timi1        ),
		.endian_dsp0       (endian_dsp0       ),
		.boot_strap0_1     (boot_strap0_1     ),
		.boot_strap0_2     (boot_strap0_2     ),
		.boot_strap0_3     (boot_strap0_3     ),
		.boot_strap0_4     (boot_strap0_4     ),
		.boot_strap0_5     (boot_strap0_5     ),
		.boot_strap0_6     (boot_strap0_6     ),
		.boot_strap0_7     (boot_strap0_7     ),
		.boot_strap0_8     (boot_strap0_8     ),
		.boot_strap0_9     (boot_strap0_9     ),
		.boot_strap0_10    (boot_strap0_10    ),
		.boot_strap0_11    (boot_strap0_11    ),
		.boot_strap0_12    (boot_strap0_12    ),
		.boot_strap0_13    (boot_strap0_13    ),
		.dsp_led_0         (dsp_led_0         )
		);

	//wire int14;  gpio_intr_gen u_gpio_intr_gen( rst_n, clk_25m, int14);

	wire [7: 0] ramd_rx;  wire [8:0] rama; wire hwr, inr_rx;

	
	wire RS485_3_CLK_R_18_BUF; BUFG u_rs485_bufg (.O(RS485_3_CLK_R_18_BUF),.I(RS485_3_CLK_R_18));
	
	hdlcrev u_hdlcrev(
		.rst_n       ( rst_n                 ),
		.clk_100m    ( clk_100m              ),
		.clkr        ( RS485_3_CLK_R_18_BUF  ),
		.datar       ( RS485_3_R_18          ),
		.flagr       ( 1'b1                  ),
		.ramd        ( ramd_rx               ),
		.rama        ( rama                  ),
		.hwr         ( hwr                   ),
		.interrupt   ( inr_rx                )
	);

	hdlc_rx_ram u_hdlc_rx_ram (
	  .clka  ( RS485_3_CLK_R_18_BUF    ),
	  .ena   ( hwr                     ),
	  .wea   ( 1'b1                    ),
	  .addra ( rama                    ),
	  .dina  ( ramd_rx                 ),

	  .clkb  ( clk_100m                ),
	  .enb   ( emif_dpram_ren          ),
	  .addrb ( emif_dpram_addr[7:0]    ),
	  .doutb ( emif_dpram_rdata        )
	);

	`ifdef DEBUG1
		ila_8_16384_1120  t_ila_8_16384_1120 (
			.clk    ( clk_100m         ), 
			.probe0 (datat             ),
			.probe1 ( inr_tx           ),
			.probe2 ( emif_dpram_wen   ),
			.probe3 ( trastart_flag    ),
			.probe4 ( db[9:2]          ),
			.probe5 ( ramd_tx          ),
			.probe6 ( emif_dpram_wdata ),
			.probe7 (emif_dpram_addr   )
		);
	`endif	
	
	`ifdef DEBUG
		ila_8_16384_1120  r_ila_8_16384_1120 (
			.clk    ( clk_100m                      ), 
			.probe0 ( {RS485_3_CLK_R_18_BUF,inr_rx} ),      
			.probe1 ( {RS485_3_R_18,hwr}            ),      
			.probe2 ( emif_dpram_ren                ),       
			.probe3 ( emif_dpram_addr[3:0]          ),       
			.probe4 ( emif_dpram_addr[7:4]          ),       
			.probe5 ( ramd_rx                       ),        
			.probe6 ( rama                          ),        
			.probe7 ( emif_dpram_rdata              )
		);
	`endif
	
	assign RS485_1_CLK_RE_18=1;assign RS485_3_CLK_RE_18=0;assign RS485_1_CLK_DE_18=1;assign RS485_3_CLK_DE_18=0;
	assign RS485_1_RE_18    =1;assign RS485_3_RE_18    =0;assign RS485_1_DE_18    =1;assign RS485_3_DE_18    =0;
	assign RS485_1_CLK_PV_18=1;assign RS485_3_CLK_PV_18=1;assign RS485_1_PV_18    =1;assign RS485_3_PV_18    =1;
	
	assign boot_strap0_14   = 0;      assign boot_strap0_15 = inr_rx;
	assign RS485_1_CLK_D_18 = clk_2m; assign RS485_1_D_18   = datat;
	
	assign DSP_EMIFWAIT0 = 0; assign DSP_EMIFWAIT1 = 0; 

	
endmodule
