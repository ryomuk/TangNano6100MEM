//---------------------------------------------------------------------------
// TangNano6100MEM
// Memory System and Peripherals for IM6100 using Tang Nano 20K
//
// version 20260128
//
// by Ryo Mukai
//
// 2026/01/28: - initial version for PCB rev.2.1
//             - implemented features are
//                 - 32KW extended main memory
//                 - 4KW Control Panel memory
//                 - TTY (UART)
//                 - interrupt (TTY, clock)
//                 - RK8E/RK05 disk emulator
//                 - functions for debug
//                   - HALT, CONT(RUN/HLT) switch
//                   - 6x10 matrix LED
//                   - debug log UART (disk access, etc.)
//                 - Universal Monitor on CP Memory
//---------------------------------------------------------------------------

`define USE_DBGLOG   // output debug information to DBG_TX

module top
  (
   input	sys_clk27, // 27MHz system clock (Tang Nano 20K)
   input	uart_rx,
   output	uart_tx,
   
   output	sd_clk,
   output	sd_mosi, 
   input	sd_miso,
   output	sd_cs_n,

   input	sw1,
   input	sw2,
   input	HALT_SW,
   input	CONT_SW,

   output	CLK,
   output reg	RESET_n,
   
   inout [11:0]	DX,
//   input	DMAGNT,
   input	INTGNT,

   input	IFETCH,
   input	DATAF,

   input	LXMAR,
   input	MEMSEL_n,
   input	DEVSEL_n,
   input	CPSEL_n,
   input	SWSEL_n,

   output	DMAREQ_n,
   output	RUN_HLT_n,
   output	INTREQ_n,

//   input	LINK,
   input	XTA,
   input	XTC,

   output	SKP_n,
   output	C0_n,
   output	C1_n,
//   output	C2_n,

   output	LED_RGB,
   output	DBG_TX
    );
  parameter H = 1'b1;
  parameter L = 1'b0;
  
  parameter SYS_CLK_FRQ  = 27_000_000; //Hz
  wire	    sys_clk = sys_clk27; // 27MHz system clock (Tang Nano 20K)
    
  // CPU_CLK_RATIO = SYS_CLK_FRQ / CPU_CLK_FRQ
//  parameter CPU_CLK_RATIO =  4;   // 6.75MHz (some IM6100A works @5V)
//  parameter CPU_CLK_RATIO =  5;   // 5.4 MHz (most IM6100A works @5V)
  parameter CPU_CLK_RATIO =  6;   // 4.5 MHz (IM6100A safe driving @5V)
//  parameter CPU_CLK_RATIO =  8;   // 3.375MHz
//  parameter CPU_CLK_RATIO =  9;   // 3.0MHz  (IM6100-1 @5V)
//  parameter CPU_CLK_RATIO = 10;   // 2.7 MHz
//  parameter CPU_CLK_RATIO = 11;   // 2.45MHz (IM6100 @5V)
//  parameter CPU_CLK_RATIO = 27;   // 1.0 MHz
//  parameter CPU_CLK_RATIO =270;   //  100KHz

  // for debug with full instruction trace log
//  parameter CPU_CLK_RATIO = 27000; // 1KHz
//  parameter CPU_CLK_RATIO =270000; // 100Hz

  parameter CPU_CLK_FRQ = SYS_CLK_FRQ / CPU_CLK_RATIO;

    parameter	 UART_BPS    =     115200; //Hz
//  parameter	 UART_BPS    =       9600; //Hz

  reg [11:0]	 mem[32767:0];   // 32KW Main Memory
  reg [11:0]	 mem_cp[4095:0]; //  4KW Control Panel Memory
  reg [11:0]	 address;
  reg [2:0]	 field;
  wire [14:0]    ext_address = {field, address};

// USB UART
  reg [7:0]	 tx_data;
  reg		 tx_send;
  wire		 tx_ready;
  wire [7:0]	 rx_data;
  wire		 rx_data_ready;
  reg		 rx_clear;
  
//---------------------------------------------------------------------------
// OP codes
//---------------------------------------------------------------------------
  parameter	 OP_AND = 3'o0;
  parameter	 OP_TAD = 3'o1;
  parameter	 OP_ISZ = 3'o2;
  parameter	 OP_DCA = 3'o3;
  parameter	 OP_JMS = 3'o4;
  parameter	 OP_JMP = 3'o5;
  parameter	 OP_IOT = 3'o6;

//---------------------------------------------------------------------------
// IOT Device Instructions/Addresses
//---------------------------------------------------------------------------
  // Processor
  parameter IOT_SKON  = 12'o6000; // Skip on interrupt on, Interrupt disabled
  parameter IOT_ION   = 12'o6001; // Interrupt enabled
  parameter IOT_IOF   = 12'o6002; // Interrupt disabled
  parameter IOT_CAF   = 12'o6007; // Clear all flags, Interrupt disabled
  
  // TTY input (Keyboard, KB)
  parameter IOT_KSF   = 12'o6031; // Skip on KB Flag
  parameter IOT_KCC   = 12'o6032; // Clear KB Flag and AC, Advance reader
  parameter IOT_KRS   = 12'o6034; // Read KB buffer static
  parameter IOT_KIE   = 12'o6035; // Set/Clear IE (not implemented yet)
  parameter IOT_KRB   = 12'o6036; // Read KB, Clear flag

  // TTY output (Teleprinter, TP)
  parameter IOT_TFL   = 12'o6040; // Set TP flag
  parameter IOT_TSF   = 12'o6041; // Skip on TP flag
  parameter IOT_TCF   = 12'o6042; // Clear TP flag
  parameter IOT_TPC   = 12'o6044; // Load TP and Print
  parameter IOT_TLS   = 12'o6046; // Load TP sequence

  // Extended Memory
  parameter IOT_GTF   = 12'o6004;
  parameter IOT_RTF   = 12'o6005;
  parameter IOT_N_CDF =  9'o62_1; // 62N1
  parameter IOT_N_CIF =  9'o62_2; // 62N2
  parameter IOT_N_CDI =  9'o62_3; // 62N3
  parameter IOT_RDF   = 12'o6214;
  parameter IOT_RIF   = 12'o6224;
  parameter IOT_RIB   = 12'o6234;
  parameter IOT_RMF   = 12'o6244;
  parameter IOT_LIF   = 12'o6254;
    
  // RK disk 67X[1-6] (X=4)
  parameter IOT_DSKP  = 12'o6741;
  parameter IOT_DCLR  = 12'o6742;
  parameter IOT_DLAG  = 12'o6743;
  parameter IOT_DLCA  = 12'o6744;
  parameter IOT_DRST  = 12'o6745;
  parameter IOT_DLDC  = 12'o6746;

//---------------------------------------------------------------------------
// Initial Memory Data
//---------------------------------------------------------------------------
`include "mem.v"
`include "mem_cp.v"

//---------------------------------------------------------------------------
// clock for CPU
//
// sys_clk ~_~_~_~_~_~_~_~_~_~_
// counter 00112233440011223344
//CLK_div  ~~~~~~____~~~~~~____
//delayed  _~~~~~~____~~~~~~___
//      &  _~~~~~_____~~~~~____
//---------------------------------------------------------------------------
//  if(CPU_CLK_RATIO % 2 == 0)
    assign CLK = CLK_div;
//  else
//    assign CLK = CLK_div & CLK_div_delayed;

  reg [23:0] clk_cnt = 0; // wide counter for very slow clock
  reg	     CLK_div = 0;
  always @(posedge sys_clk)
    if(clk_cnt == CPU_CLK_RATIO - 1)
      clk_cnt <= 0;
    else
      clk_cnt <= clk_cnt + 1'b1;

  always @(posedge sys_clk)
    if(clk_cnt == CPU_CLK_RATIO / 2) // duty H/L > 0.5 when the ratio is odd.
      CLK_div <= H;
    else if (clk_cnt == CPU_CLK_RATIO - 1)
      CLK_div <= L;

  reg CLK_div_delayed;  // delayed half sys_clk
  always @(negedge sys_clk)
      CLK_div_delayed <= CLK_div;

//---------------------------------------------------------------------------
// make logical switches from sw1
//---------------------------------------------------------------------------
  wire       sw1_deb;
  wire       sw1_hold;
  wire [2:0] sw1_count;
  switch
    #(.CLK_FRQ(SYS_CLK_FRQ)
      )   sw1_inst
      (
       .clk(sys_clk),
       .sw_phy     (sw1),
       .sw_deb     (sw1_deb),
       .sw_hold    (sw1_hold),
       .sw_count   (sw1_count),
       .reset_count(sw1_hold),
       .sw_double(),.sw_repeat(),.sw_toggle(),.sw_posedge(),.sw_negedge()
       );

//---------------------------------------------------------------------------
// make logical switches from sw2
//---------------------------------------------------------------------------
  wire       sw2_deb;
  wire       sw2_hold;
  wire       sw2_double;
  wire       sw2_toggle;
  wire [2:0] sw2_count;
  switch
    #(.CLK_FRQ(SYS_CLK_FRQ)
      )   sw2_inst
      (
       .clk(sys_clk),
       .sw_phy     (sw2),
       .sw_deb     (sw2_deb),
       .sw_hold    (sw2_hold),
       .sw_double  (sw2_double),
       .sw_toggle  (sw2_toggle),
       .sw_count   (sw2_count),
       .reset_count(sw2_hold),
       .sw_repeat(),.sw_posedge(),.sw_negedge()
       );

//---------------------------------------------------------------------------
// make logical switches from CONT_SW
//---------------------------------------------------------------------------
  parameter AUTO_CONT_MS = 33;
  wire CONT_SW_deb;
  wire CONT_SW_hold;
  wire CONT_SW_repeat;
  switch
    #(.CLK_FRQ(SYS_CLK_FRQ),
      .REPEAT(AUTO_CONT_MS)
      )   CONT_SW_inst
      (
       .clk(sys_clk),
       .sw_phy     (CONT_SW),
       .sw_deb     (CONT_SW_deb),
       .sw_hold    (CONT_SW_hold),
       .sw_repeat  (CONT_SW_repeat),
       .reset_count(1'b0),
       .sw_toggle(),.sw_double(),.sw_count(),.sw_posedge(),.sw_negedge()
       );

//---------------------------------------------------------------------------
// reset button and power on reset
//---------------------------------------------------------------------------
  // reset for CPU and device
  
  wire reset_sw = (sw1 & sw2) | ((~HALT_SW) & CONT_SW_hold);

  reg [27:0]	 reset_cnt = 0;
  parameter	 RESET_WIDTH = (SYS_CLK_FRQ / 1000) * 250; // 250ms
  always @(posedge sys_clk)
    if( reset_sw )
      {RESET_n, reset_cnt} <= 0;
    else if (reset_cnt != RESET_WIDTH) begin
       RESET_n <= 0;
       reset_cnt <= reset_cnt + 1'd1;
    end
    else
      RESET_n <= 1;

//---------------------------------------------------------------------------
// RUN/HLT
//---------------------------------------------------------------------------
  assign RUN_HLT_n = ~( HALT_SW ?
			// HALT_SW is on (down)
			IFETCH
			| (CONT_SW_hold ? CONT_SW_repeat : CONT_SW_deb) :
			// HALT_SW is off (up)
			( CONT_SW_deb | dbg_hlt)
			);

//---------------------------------------------------------------------------
// make edge signals
//---------------------------------------------------------------------------
  reg [1:0] LXMARs;
  wire	    posedge_LXMAR = LXMARs[0] & ~LXMARs[1];
  wire	    negedge_LXMAR = LXMARs[1] & ~LXMARs[0];
  always @(negedge sys_clk)
    LXMARs <= {LXMARs[0], LXMAR};

  reg [1:0] MEMSEL_ns;
  wire	    posedge_MEMSEL_n = MEMSEL_ns[0] & ~MEMSEL_ns[1];
  wire	    negedge_MEMSEL_n = MEMSEL_ns[1] & ~MEMSEL_ns[0];
  always @(negedge sys_clk)
    MEMSEL_ns <= {MEMSEL_ns[0], MEMSEL_n};

  reg [1:0] DEVSEL_ns;
  wire	    posedge_DEVSEL_n = DEVSEL_ns[0] & ~DEVSEL_ns[1];
  wire	    negedge_DEVSEL_n = DEVSEL_ns[1] & ~DEVSEL_ns[0];
  always @(negedge sys_clk)
    DEVSEL_ns <= {DEVSEL_ns[0], DEVSEL_n};

  reg [1:0] CPSEL_ns;
  wire	    posedge_CPSEL_n = CPSEL_ns[0] & ~CPSEL_ns[1];
  wire	    negedge_CPSEL_n = CPSEL_ns[1] & ~CPSEL_ns[0];
  always @(negedge sys_clk)
    CPSEL_ns <= {CPSEL_ns[0], CPSEL_n};
      
  reg [1:0] IFETCHs;
  wire	    posedge_IFETCH = IFETCHs[0] & ~IFETCHs[1];
  wire	    negedge_IFETCH = IFETCHs[1] & ~IFETCHs[0];
  always @(negedge sys_clk)
    IFETCHs <= {IFETCHs[0], IFETCH};

  reg [1:0] RUN_HLT_ns;
  wire	    posedge_RUN_HLT_n = RUN_HLT_ns[0] & ~RUN_HLT_ns[1];
  wire	    negedge_RUN_HLT_n = RUN_HLT_ns[1] & ~RUN_HLT_ns[0];
  always @(negedge sys_clk)
    RUN_HLT_ns <= {RUN_HLT_ns[0], RUN_HLT_n};

  reg [1:0] CLKs;
  wire	    posedge_CLK = CLKs[0] & ~CLKs[1];
  always @(negedge sys_clk)
    CLKs <= {CLKs[0], CLK};

//---------------------------------------------------------------------------
// aliases of bus control signals
//---------------------------------------------------------------------------
  wire inst_read    = posedge_MEMSEL_n &  XTC & IFETCH;
  wire mem_read     = posedge_MEMSEL_n &  XTC;
  wire mem_write    = posedge_MEMSEL_n & ~XTC;
  wire dev_start    = negedge_DEVSEL_n &  XTC;
  wire dev_read     = posedge_DEVSEL_n &  XTC;
  wire dev_write    = posedge_DEVSEL_n & ~XTC;

  wire inst_cp_read = posedge_CPSEL_n & XTC & IFETCH;
  wire mem_cp_read  = posedge_CPSEL_n & XTC;
  wire mem_cp_write = posedge_CPSEL_n & ~XTC;
  wire bus_read     = mem_read  | dev_read  | mem_cp_read;
  wire bus_write    = mem_write | dev_write | mem_cp_write;

//---------------------------------------------------------------------------
// last instruction log
//---------------------------------------------------------------------------
  reg [14:0]	 last_inst_addr;
  reg [11:0]	 last_inst;
  wire [2:0]	 last_op = last_inst[11:9]; // used for memory extention

  reg [14:0]	 last_read_addr;
  reg [11:0]	 last_read_data;

  reg [14:0]	 last_write_addr;
  reg [11:0]	 last_write_data;

  always @(posedge sys_clk)
    if( inst_read ) begin
       {last_inst_addr, last_inst} <= {ext_address, d_mem_to_cpu};
       {last_read_addr, last_read_data} <= 0;
       {last_write_addr, last_write_data} <= 0;
    end
    else if( mem_read )
      {last_read_addr, last_read_data} <= {ext_address, d_mem_to_cpu};
    else if( mem_write )
      {last_write_addr, last_write_data} <= {ext_address, DXin};
    else if( dev_read )
      {last_read_addr, last_read_data} <= {3'b000, address, dev_data};
    else if( dev_write )
      {last_write_addr, last_write_data} <= {3'b000, address, DXin};
    else if( inst_cp_read ) begin
       {last_inst_addr, last_inst} <= {ext_address, mem_cp[address]};
       {last_read_addr, last_read_data} <= 0;
       {last_write_addr, last_write_data} <= 0;
    end
    else if( mem_cp_read )
      {last_read_addr, last_read_data} <= {ext_address, mem_cp[address]};
    else if( mem_cp_write )
      {last_write_addr, last_write_data} <= {ext_address, DXin};

//---------------------------------------------------------------------------
// address latch
// used for instruction/data/device address
//---------------------------------------------------------------------------
  always @(posedge sys_clk)
    if( negedge_LXMAR ) // latched at negedge
      address <= DXin;
  
//---------------------------------------------------------------------------
// reverse bit order
//
// DX:    0123456789AB
// DXin:  BA9876543210
// DXout: BA9876543210
//---------------------------------------------------------------------------
  wire [11:0] DXin;
  wire [11:0] DXout;

  assign DXin[11:0] = {<<1{DX[11:0]}};
  assign DX[11:0]   = {<<1{DXout[11:0]}};

//---------------------------------------------------------------------------
// Memory and IO output
//---------------------------------------------------------------------------
  assign DXout = (~XTA)      ? 12'bzzzz_zzzz_zzzz :
		 (~MEMSEL_n) ? d_mem_to_cpu :
		 (~DEVSEL_n) ? dev_data :
		 (~CPSEL_n)  ? mem_cp[address] :
		 (~SWSEL_n)  ? reg_switch :
		 12'bzzzz_zzzz_zzzz; // HiZ if nothing is selected

  //  reg [11:0] reg_switch = 12'o000; // not implemented
  parameter reg_switch = 12'o000;
  
//---------------------------------------------------------------------------
// Memory Extension
//---------------------------------------------------------------------------
  reg [2:0]  REG_IF; // Instruction Field
  reg [2:0]  REG_DF; // Data Field
  reg [2:0]  REG_IB; // Instruction Buffer
  reg [5:0]  REG_SF; // Save Field
  reg	     REG_IIFF; // Interrupt Inhibit Flip-Flop
  
  always @(posedge sys_clk) 
    field <= DATAF ? REG_DF: REG_IF;

  wire [8:0] address_N = {address[11:6], address[2:0]};
  wire [2:0] IOT_N     = address[5:3];
  always @(posedge sys_clk or negedge RESET_n)
    if(~RESET_n)
      {REG_IF, REG_DF, REG_IB, REG_IIFF} <= 0;
    else if(dev_write) begin
       case( address )
	 IOT_RTF: {REG_IB, REG_DF, REG_IIFF} <= {DXin[5:0],   1'b1};
	 IOT_RMF: {REG_IB, REG_DF, REG_IIFF} <= {REG_SF[5:0], 1'b1};
	 IOT_LIF: {REG_IF,         REG_IIFF} <= {REG_IB,      1'b0};
	 default:;
       endcase
       case( address_N )
	 IOT_N_CDF:  REG_DF                    <=  IOT_N;
	 IOT_N_CIF: {REG_IB, REG_IIFF}         <= {IOT_N, 1'b1};
	 IOT_N_CDI: {REG_DF, REG_IB, REG_IIFF} <= {IOT_N, IOT_N, 1'b1};
	 default:;
       endcase
    end
    else if( (last_op == OP_JMP) & posedge_IFETCH)
      {REG_IF, REG_IIFF} <= {REG_IB, 1'b0};
    else if( last_op == OP_JMS) begin
       if( negedge_MEMSEL_n & ~XTC) // IF<=IB before write return address
	 {REG_IF, REG_IIFF} <= {REG_IB, 1'b0};
       // JMS autoindex does not work ???
    end
//    else if(posedge_IFETCH)
//    else if(negedge_IFETCH)
//      if ((last_op == OP_JMS) | (last_op == OP_JMP))
//	{REG_IF, REG_IIFF} <= {REG_IB, 1'b0};
  
  always @(posedge sys_clk)
    if(posedge_INTGNT)
      REG_SF <= {REG_IF, REG_DF};
		  
//---------------------------------------------------------------------------
// DMA
//---------------------------------------------------------------------------
  // DMA activated during disk is busy but disabled while reset
  wire DMA_enabled = RESET_n & (disk_busy & (sd_error == 0));

  // This is a dirty workaround for not using DMAGANT
  wire DMA_granted = DMA_enabled & MEMSEL_n;
       
//---------------------------------------------------------------------------
// Main memory write (by CPU and DMA devices)
//---------------------------------------------------------------------------
  wire [15:0] dma_address; // dma bus of SD module is 8bit
                           // address[14:0] = dma_addrss[15:1]
                           // byte to word data order is little endian
  
  wire [11:0] d_mem_to_cpu = mem[wa]; // to infer BSRAM

  // divide 12bit word into two 8bit byte litte endian
  wire [7:0]  d_mem_to_dma =
	      dma_address[0] ? {4'b0000, mem[wa][11:8]} : mem[wa][7:0];
  // we by cpu       
  reg [11:0]  d_cpu_to_mem;
  reg	      we_mem;
  always @(posedge sys_clk)
    if( mem_write ) begin // write to memory
       d_cpu_to_mem <= DXin;
       we_mem <= 1'b1;
    end
    else
      we_mem <= 0;

  // we by DMA devices
  wire	     we_dma_hi = DMA_granted & dma_write &   dma_address[0];
  wire	     we_dma_lo = DMA_granted & dma_write & (~dma_address[0]);

  // address or data of memory should be latched to infer BSRAM
  reg [14:0] wa;  // word address for RAM
  always @(negedge sys_clk) // negedge
    wa <= DMA_granted ? dma_address[15:1] : ext_address;
  
  reg [7:0]  d_dma_lo;
  always @(posedge sys_clk)
    if(we_mem)
      mem[wa] <= d_cpu_to_mem;
    else if( we_dma_hi)
      mem[wa] <= {d_dma_to_mem[3:0], d_dma_lo};
    else if( we_dma_lo)
      d_dma_lo <= d_dma_to_mem[7:0];
  
//---------------------------------------------------------------------------
// CP Memory write (by CPU)
//---------------------------------------------------------------------------
  always @(posedge sys_clk)
    if( mem_cp_write )
      mem_cp[address] <= DXin[11:0];

//---------------------------------------------------------------------------
// I/O
//---------------------------------------------------------------------------
  // UART SEND
  reg TP_flag;      // Teleprinter flag
  reg TP_flag_lock;
  always @(posedge sys_clk or negedge RESET_n)
    if( ~RESET_n)
      {TP_flag, TP_flag_lock, tx_send} <= 0;
    else if( dev_write )
      case ( address )
	IOT_TFL: {TP_flag, TP_flag_lock} <= 2'b11;
	IOT_TCF: {TP_flag, TP_flag_lock} <= 2'b01;
	IOT_TPC: begin
	   {tx_data[7:0], tx_send} <= {(DXin[7:0] & 8'h7f), 1'b1};
	   TP_flag_lock <= 0;
	end
	IOT_TLS: begin
	   {tx_data[7:0], tx_send} <= {(DXin[7:0] & 8'h7f), 1'b1};
	   {TP_flag, TP_flag_lock} <= 0;
	end
	default:;
      endcase
    else begin
       tx_send <= 1'b0;
       if(~TP_flag_lock)
	 TP_flag <= tx_ready;
    end
  
  // UART READ
  reg [7:0] kbd_data;
  wire KB_flag = rx_data_ready;
  always @(posedge sys_clk)
    if( dev_start &
       ((address == IOT_KRB) |
	(address == IOT_KRS) |
	(address == IOT_KCC))
       )
      {kbd_data[7:0], rx_clear} <= {(8'h80 | rx_data[7:0]), 1'b1};
    else if(rx_data_ready == 1'b0)
      rx_clear <= 1'b0;  // disable rx_clear after rx_data_ready is cleared
  
//---------------------------------------------------------------------------
// C0_n, C1_n, and SKP_n.
// C2_n is always 'H'
// C0_n, C1_n :
//    H,    H : DEV = AC
//    L,    H : DEV = AC; AC=0
//    H,    L : AC  = AC | DEV
//    L,    L : AC  = DEV
//--------------------------------------------------------------------------
  assign {C0_n, C1_n, SKP_n} = c01s_n;
  reg [2:0] c01s_n;
  always @(posedge sys_clk)
    if( dev_start )
      case (address)
	// TTY input
	IOT_KSF:  c01s_n <= {H, H, ~KB_flag};
	IOT_KCC:  c01s_n <= {L, H, H};
	IOT_KRS:  c01s_n <= {H, L, H};
	IOT_KRB:  c01s_n <= {L, L, H};
	// TTY output
	IOT_TSF:  c01s_n <= {H, H, ~TP_flag};
	// extended memory
	IOT_GTF:  c01s_n <= {L, L, H};
	IOT_RDF:  c01s_n <= {H, L, H};
	IOT_RIF:  c01s_n <= {H, L, H};
	IOT_RIB:  c01s_n <= {H, L, H};
	// RK disk
	IOT_DSKP: c01s_n <= {H, H, RK_BUSY}; // = ~RK_DONE
	IOT_DCLR: c01s_n <= {L, H, H};
	IOT_DLCA: c01s_n <= {L, H, H};
	IOT_DRST: c01s_n <= {L, L, H};
	IOT_DLDC: c01s_n <= {L, H, H};
	default: 
	  c01s_n <= {H, H, H};
      endcase
    else if( posedge_DEVSEL_n )
      c01s_n <= {H, H, H};

//---------------------------------------------------------------------------
// UART instances
//---------------------------------------------------------------------------
  uart_rx#
    (
     .CLK_FRQ(SYS_CLK_FRQ),
     .BAUD_RATE(UART_BPS)
     ) uart_rx_inst
      (
       .clk           (sys_clk      ),
       .reset_n       (RESET_n      ),
       .rx_data       (rx_data      ),
       .rx_data_ready (rx_data_ready),
       .rx_clear      (rx_clear),
       .rx_in         (uart_rx      )
       );

  uart_tx#
    (
     .CLK_FRQ(SYS_CLK_FRQ),
     .BAUD_RATE(UART_BPS)
     ) uart_tx_inst
      (
       .clk           (sys_clk),
       .reset_n       (RESET_n),
       .tx_data       (tx_data),
       .tx_send       (tx_send),
       .tx_ready      (tx_ready),
       .tx_out        (uart_tx)
       );

//---------------------------------------------------------------------------
// RK Disk
// 256 word x 16 sector x 203 cyl(track) x 2 surface
// 6496 * 256word(512byte) block
//
// 1 block = 256word = 512B = 01000B
// SD memory block
// each RK05 disk image uses first 6496 block in 8192 block.
// (DRIVE_BLOCK_SIZE = 8192 (= 16 * 2 * 256))
//        0-  8191: RK0 (00000000)
//     8192- 16383: RK1 (00020000)
//    16384- 24575: RK2 (00040000)
//    24576- 32767: RK3 (00060000)
//
// # sample for making a sd image from multiple disk images
// dd if=rk0 of=sd.dsk
// dd if=rk1 of=sd.dsk seek=8192  conv=notrunc
// dd if=rk2 of=sd.dsk seek=16384 conv=notrunc
// dd if=rk3 of=sd.dsk seek=24576 conv=notrunc
//
//---------------------------------------------------------------------------
  reg [11:0]  RK_REG_CMD;
  wire	      RK_cyl_MSB     = RK_REG_CMD[0];
  wire [1:0]  RK_drivesel    = RK_REG_CMD[2:1];
  wire [2:0]  RK_ext_address = RK_REG_CMD[5:3];
  wire [8:0]  RK_blocklength = RK_REG_CMD[6] ? 9'd128 : 9'd256;
  wire	      RK_SDOSD       = RK_REG_CMD[7];  // set done on seek done
  wire	      RK_IOD         = RK_REG_CMD[8];  // interrupt on done
  wire [2:0]  RK_command     = RK_REG_CMD[11:9];

  wire [2:0]  USER_drivesel = sw1_count;

  parameter   DRIVE_BLOCK_SIZE = 16 * 2 * 256;
  wire [19:0] RK_block_address =  DRIVE_BLOCK_SIZE * RK_drivesel
	      + {RK_cyl_MSB, RK_REG_cyl, RK_REG_sur, RK_REG_sect}
	      + DRIVE_BLOCK_SIZE * USER_drivesel; // for debug etc.
  
  reg [11:0]  RK_current_address;
  reg [15:0]  RK_dma_start_address; // byte address
  reg [15:0]  RK_dma_wordcount;
  reg	      RK_go;	      
  reg	      RK_go_clear;

  reg [6:0]   RK_REG_cyl;
  reg	      RK_REG_sur;
  reg [3:0]   RK_REG_sect;

  parameter   RK_CMD_READ     = 3'b000;
  parameter   RK_CMD_READALL  = 3'b001; // same as READ?
  parameter   RK_CMD_WPROTECT = 3'b010; // not implemented yet
  parameter   RK_CMD_SEEKONLY = 3'b011; // implemented as NOP
  parameter   RK_CMD_WRITE    = 3'b100;
  parameter   RK_CMD_WRITEALL = 3'b101; // same as WRITE?

//--------------------------------------------------------------------------
// DMA request
//--------------------------------------------------------------------------
  reg	      REG_DMAREQ;
  assign DMAREQ_n = ~REG_DMAREQ;
  wire	      RK_BUSY = REG_DMAREQ;

  always @(posedge sys_clk or negedge RESET_n)
    if( ~RESET_n )
      REG_DMAREQ <= 0;
    else if( ~REG_DMAREQ ) begin    // REG_DMAREQ is delayed until
       if(posedge_IFETCH)           // posedge_IFETCH 
	 REG_DMAREQ <= DMA_enabled; // This is a dirty workaround
    end                             // to avoid CPU halts
    else
      REG_DMAREQ <= DMA_enabled;
  
  reg [1:0] disk_readys;
  wire posedge_disk_ready = disk_readys[0] & ~disk_readys[1];
  always @(posedge sys_clk )
    disk_readys[1:0] <= {disk_readys[0], disk_ready};

//--------------------------------------------------------------------------
// setup addresses on RK_go for sd
//--------------------------------------------------------------------------
  always @(posedge sys_clk or negedge RESET_n)
    if( ~RESET_n )
      {disk_read, disk_write, disk_nop, RK_go_clear} <= 0;
    else if( disk_busy )
      {disk_read, disk_write, disk_nop, RK_go_clear} <= 0;
    else if( RK_go ) begin
       RK_go_clear <= 1'b1;
       // dma address is in byte, so shifted left 1 bit
       dma_start_address  <= RK_dma_start_address;
       disk_block_address <= {4'b0000, RK_block_address};
       dma_wordcount      <= ((~RK_dma_wordcount) + 1'b1) & 16'o177777;
       case(RK_command)
	 RK_CMD_READ:        disk_read  <= 1'b1;
	 RK_CMD_READALL:     disk_read  <= 1'b1;
	 RK_CMD_WRITE:       disk_write <= 1'b1;
	 RK_CMD_WRITEALL:    disk_write <= 1'b1;
	 RK_CMD_SEEKONLY:    disk_nop   <= 1'b1;
	 default:            disk_nop   <= 1'b1;
       endcase
    end

//---------------------------------------------------------------------------
// RK8E disk controller
//---------------------------------------------------------------------------
  always @(posedge sys_clk or negedge RESET_n)
    if( ~RESET_n ) begin
       RK_current_address  <= 0;
       RK_dma_wordcount    <= 0;
       RK_go               <= 0;
    end
    else if( RK_go_clear )
      RK_go <= 0;
    else if( dev_write )
      case (address)
	IOT_DCLR: begin
	   if((DXin[1:0] == 2'b01) | (DXin[1:0] == 2'b10)) begin
	      RK_REG_CMD <= 0;
	      {RK_REG_cyl, RK_REG_sur, RK_REG_sect} <= 0;
	      RK_current_address <= 0;
	   end
	end
	IOT_DLAG: begin
	   RK_go                <= 1'b1;
	   RK_REG_cyl           <= DXin[11:5];
	   RK_REG_sur           <= DXin[4];
	   RK_REG_sect          <= DXin[3:0];
	   RK_dma_wordcount     <= RK_blocklength;
	   RK_dma_start_address <= {RK_ext_address, RK_current_address, 1'b0};
	   RK_current_address   <= RK_current_address + RK_blocklength;
	end
	IOT_DLCA: RK_current_address <= DXin[11:0];
	IOT_DLDC: RK_REG_CMD <= DXin[11:0];
	default:;
      endcase

//---------------------------------------------------------------------------
// DMA bus for HDD
//---------------------------------------------------------------------------
  reg [23:0]  disk_block_address;
  reg [15:0]  dma_start_address; // byte address
  reg [15:0]  dma_wordcount;

  wire [7:0]  d_dma_to_mem;

  wire	      dma_write;

//---------------------------------------------------------------------------
// SD memory Hard disk emulator
//---------------------------------------------------------------------------
  reg	      disk_read;
  reg	      disk_write;
  reg	      disk_nop;
  wire	      disk_ready;
  wire	      disk_busy  = ~disk_ready;
  wire [4:0]  sd_state;
  wire [3:0]  sd_error;

  // clock for sdhd and sdtape
  parameter	 SD_SYS_FRQ   = SYS_CLK_FRQ;
  parameter	 SD_MEM_FRQ   =1000_000;
//  parameter	 SD_MEM_FRQ   = 800_000;
//  parameter	 SD_MEM_FRQ   = 400_000;
  wire		 sd_sys_clk   = sys_clk;
  wire		 SD_RESET_n   = RESET_n;		 
  sdhd #( .SYS_FRQ(SD_SYS_FRQ),
	  .MEM_FRQ(SD_MEM_FRQ),
	  .DMA_MSB(15)          // for 15bit byte (=14 bit word) address bus
	  ) sdhd_inst
  (.i_clk                (sd_sys_clk),
   .i_reset_n            (SD_RESET_n),
   .i_sd_det_n           (1'b0),  // Tang Console's sd_det_n seems not working
                                  // Tang Nano doesn't have det_n
   //   .i_sd_det_n           (sd_det_n),
   .i_sd_miso            (sd_miso),
   .o_sd_mosi            (sd_mosi),
   .o_sd_cs_n            (sd_cs_n),
   .o_sd_clk             (sd_clk),
   .o_disk_ready         (disk_ready),
   .i_disk_read          (disk_read),
   .i_disk_write         (disk_write),
   .i_disk_nop           (disk_nop),
   .i_disk_block_address (disk_block_address),
   .o_dma_address        (dma_address),
   .i_dma_start_address  (dma_start_address),
   .i_dma_wordcount      (dma_wordcount),
   .i_dma_data           (d_mem_to_dma),
   .o_dma_data           (d_dma_to_mem),
   .o_dma_write          (dma_write),
   .o_sd_state           (sd_state),
   .o_sd_error           (sd_error)
   );

//---------------------------------------------------------------------------
// data from device to CPU
//---------------------------------------------------------------------------
  wire [11:0] dev_data;
  assign dev_data
    =
     // TTY input
     (address == IOT_KRS)  ? {4'b0000, kbd_data} :
     (address == IOT_KRB)  ? {4'b0000, kbd_data} :
     // extended memory
     (address == IOT_GTF)  ? {3'b000, REG_IIFF, 2'b00, REG_SF[5:0]} :
     (address == IOT_RDF)  ? {6'b000_000, REG_DF, 3'b000} :
     (address == IOT_RIF)  ? {6'b000_000, REG_IF, 3'b000} :
     (address == IOT_RIB)  ? {6'b000_000, REG_SF[5:0]} :
     // RK disk
     (address == IOT_DRST) ? {RK_BUSY, 11'b00_000_000_000}:
     0;
  
//---------------------------------------------------------------------------
// Clock timer
//---------------------------------------------------------------------------
  parameter TIMER_FRQ = 30; // Hz

  reg	     clk_timer = 0;
  reg [23:0] cnt_timer;
  reg	     posedge_clk_timer;
  always @(posedge sys_clk)
    if(cnt_timer == SYS_CLK_FRQ / TIMER_FRQ / 2) begin
       cnt_timer         <= 0;
       clk_timer         <= ~clk_timer;
       posedge_clk_timer <= ~clk_timer; // detect rising edge
    end
    else begin
       cnt_timer <= cnt_timer + 1'b1;
       posedge_clk_timer <= 0;
    end

//---------------------------------------------------------------------------
// Interrupt
//---------------------------------------------------------------------------
// LED2 of TangNano 20 (INTREQ_n) always lits
// if CPU's interrupt system is disabled.
// This is a dirty workaround for disable tty interrupt
// until first IOT_ION instruction.

  reg TTY_INT_enable;
  always @(negedge sys_clk or negedge RESET_n)
    if( ~RESET_n )
      TTY_INT_enable <= 0;
    else if (last_inst == IOT_ION )
      TTY_INT_enable <= 1'b1;

//  assign INTREQ_n = 1'b1;
  assign INTREQ_n = ~((IRQ_ttyi | IRQ_ttyo) & TTY_INT_enable)
                     | REG_IIFF;


  reg [1:0] INTGNTs;
  wire	    posedge_INTGNT = INTGNTs[0] & ~INTGNTs[1];
  always @(negedge sys_clk)
    INTGNTs[1:0] <= {INTGNTs[0], INTGNT};

  reg [1:0] TP_flags;
  wire	    posedge_TP_flag = TP_flags[0] & ~TP_flags[1];
  always @(negedge sys_clk)
    TP_flags[1:0] <= {TP_flags[0], TP_flag};

  reg [1:0] KB_flags;
  wire	    posedge_KB_flag = KB_flags[0] & ~KB_flags[1];
  always @(negedge sys_clk)
    KB_flags[1:0] <= {KB_flags[0], KB_flag};

  reg IRQ_disk;
  reg IRQ_ttyi;
  reg IRQ_ttyo;
  reg IRQ_timer;
  always @(posedge sys_clk or negedge RESET_n)
    if( ~RESET_n)
      {IRQ_disk, IRQ_ttyi, IRQ_ttyo, IRQ_timer} = 0;
    else begin
       if(posedge_INTGNT) begin
          if( IRQ_disk)
	    IRQ_disk <= 0;
	  else if( IRQ_ttyi )
	    IRQ_ttyi <= 0;
	  else if( IRQ_ttyo )
	    IRQ_ttyo <= 0;
	  else if( IRQ_timer )
	    IRQ_timer <= 0;
       end
       if( posedge_disk_ready & RK_IOD)
	 IRQ_disk <= 1'b1;
       if( posedge_KB_flag )
	 IRQ_ttyi <= 1'b1;
       if( posedge_TP_flag )
	 IRQ_ttyo <= 1'b1;
       if( posedge_clk_timer )
	 IRQ_timer <= 1'b1;
    end
  
//---------------------------------------------------------------------------
// LED array for debug
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
// some clock signals to display on LED array
// to monitor sys_clk, CLK and IFETCH
//---------------------------------------------------------------------------
  reg [25:0]		cnt_500ms;
  reg			clk_1Hz;
  always @(posedge sys_clk)
    if(cnt_500ms == SYS_CLK_FRQ/2) begin
       cnt_500ms <= 0;
       clk_1Hz <= ~clk_1Hz;
    end else 
      cnt_500ms <= cnt_500ms + 1'b1;

  parameter CLK_monitor_base = 4_500_000;
  reg [24:0] CLK_count = 0;
  reg CLK_monitor;
  always @(posedge sys_clk)
    if( posedge_CLK )
      if(CLK_count == CLK_monitor_base/2) begin // 1Hz @ CPU clock = 4.5MHz
	 CLK_count <= 0;
	 CLK_monitor <= ~CLK_monitor;
      end
      else
	CLK_count <= CLK_count + 1'd1;
  
  reg [24:0] IFETCH_count = 0;
  reg IFETCH_monitor;
  always @(posedge sys_clk)
    if(posedge_IFETCH)
      if(IFETCH_count == CPU_CLK_FRQ / 50) begin
	 IFETCH_count <= 0;
	 IFETCH_monitor <= ~IFETCH_monitor;
      end
      else
	IFETCH_count <= IFETCH_count + 1'd1;

//---------------------------------------------------------------------------
// LED array
//---------------------------------------------------------------------------
  parameter LED_WIDTH  = 6;
  parameter LED_HEIGHT = 10;
  parameter LEDS       = LED_WIDTH * LED_HEIGHT;
  reg [LED_WIDTH-1:0] led_r[LED_HEIGHT-1:0], 
		      led_g[LED_HEIGHT-1:0],
		      led_b[LED_HEIGHT-1:0];
  
  wire [LEDS-1:0]     bmp_r, bmp_g, bmp_b;

  // for 6x10 or 12x10 matrix
  assign bmp_r = {led_r[0], led_r[1], led_r[2], led_r[3], led_r[4],
		  led_r[5], led_r[6], led_r[7], led_r[8], led_r[9]};
  assign bmp_g = {led_g[0], led_g[1], led_g[2], led_g[3], led_g[4],
		  led_g[5], led_g[6], led_g[7], led_g[8], led_g[9]};
  assign bmp_b = {led_b[0], led_b[1], led_b[2], led_b[3], led_b[4],
		  led_b[5], led_b[6], led_b[7], led_b[8], led_b[9]};
  
// for 10x6 or 20x6 matrix
// assign bmp_r = {led_r[0], led_r[1], led_r[2], led_r[3], led_r[4], led_r[5]};
// assign bmp_g = {led_g[0], led_g[1], led_g[2], led_g[3], led_g[4], led_g[5]};
// assign bmp_b = {led_b[0], led_b[1], led_b[2], led_b[3], led_b[4], led_b[5]};

  // clock for ws2812 RGB LED
  parameter      WS2812_CLK_FRQ = SYS_CLK_FRQ; // 27MHz
  wire		 ws2812_clk     = sys_clk;
  ws2812_matrix
    #(.CLK_FRQ(WS2812_CLK_FRQ),
      .WIDTH(LED_WIDTH),
      .HEIGHT(LED_HEIGHT)
      )   ws2812_matrix_inst
      (
       .clk(ws2812_clk),
       .sout(LED_RGB),
       .r(bmp_r),
       .g(bmp_g),
       .b(bmp_b)
       );

// for 6x10 RGB LED matrix
  wire SD_ERR = (sd_error != 0);
  always @(posedge sys_clk) begin
     led_r[0] <= {3'b000, ~RESET_n, ~INTREQ_n, ~DMAREQ_n};
     led_g[0] <= 0;
     led_b[0] <= { clk_1Hz, CLK_monitor, IFETCH_monitor, 3'b000 };

     led_r[1] <= {HALT_SW, ~RUN_HLT_n, dbg_hlt, 3'b000};
     led_g[1] <= {2'b00, ~SWSEL_n, ~CPSEL_n, ~DEVSEL_n, ~MEMSEL_n};
     led_b[1] <= 0;

     led_r[2] <= {rx_data_ready, ~sd_mosi, 3'b000, SD_ERR};
     led_g[2] <= 0;
     led_b[2] <= {tx_send,       ~sd_miso, 4'b0000};

     {led_r[3], led_r[4]} <= last_inst_addr[11:0];
     {led_g[3], led_g[4]} <= {last_inst_addr[14:12], 9'b000000000};
     {led_b[3], led_b[4]} <= 0;

     {led_r[5], led_r[6]} <= 0;
     {led_g[5], led_g[6]} <= 0;
     {led_b[5], led_b[6]} <= last_inst;

     if( sw2_count[0] == 1'b0 ) begin // memory extention registers
	  led_r[7] <= 0;
	  led_g[7] <= {REG_IF, 3'b000};
	  led_b[7] <= {3'b000, REG_DF};
	  led_r[8] <= {REG_IIFF, 5'b00000};
	  led_g[8] <= {REG_IB, 3'b000};
	  led_b[8] <= REG_SF;
     end
     else begin // sd memory error/status code
	  led_r[7] <= sd_error;
	  led_g[7] <= 0;
	  led_b[7] <= 0;
	  led_r[8] <= 0;
	  led_g[8] <= 0;
	  led_b[8] <= sd_state;
     end

//     led_r[9] <= {sw2, sw2_deb, sw2_hold, sw2_double, sw2_toggle, 1'b0};
     led_r[9] <= 0;
     led_g[9] <= {sw2_count, sw1_count};
     led_b[9] <= 0;
  end

//---------------------------------------------------------------------
// Halt signal for debug
//---------------------------------------------------------------------
  reg dbg_hlt;
  always @(posedge sys_clk or negedge RESET_n)
    if( ~RESET_n )
      dbg_hlt = 0;
//    else if((last_inst_addr == 15'o07671)
//	    & ((dma_start_address>>1) == 15'o06600)
//	    & (disk_block_address == 'o20)
//	    ) // DIR RKA0:
//      dbg_hlt <= 1'b1;
//    else if((last_inst_addr == 15'o07671)
//	    & ((dma_start_address >>1) == 15'o07000) // OS/8 PFOCAL
//      dbg_hlt <= 1'b1;
//    else if(last_inst_addr == 15'o07671 ) // RK
//      dbg_hlt <= 1'b1;
//    else if(last_inst_addr == 15'o01207 ) // DB
//      dbg_hlt <= 1'b1;
    else
      dbg_hlt <= 0;
  
//---------------------------------------------------------------------
// debug log to DBG_TX
//---------------------------------------------------------------------
`ifdef USE_DBGLOG
  parameter	 UART_BPS_DBG = 115_200;

  reg [39:0] dbg_regw;
  reg [31:0] dbg_reg0, dbg_reg1, dbg_reg2, dbg_reg3, dbg_reg4, dbg_reg5;
  reg	     dbg_print;

  dbglog
    #(.CLK_FRQ(SYS_CLK_FRQ),
      .BAUD_RATE(UART_BPS_DBG)
      )   dbglog_inst
      (
       .clk(sys_clk),
       .reset_n(RESET_n),
       .regw (dbg_regw),
       .reg0 (dbg_reg0),
       .reg1 (dbg_reg1),
       .reg2 (dbg_reg2),
       .reg3 (dbg_reg3),
       .reg4 (dbg_reg4),
       .reg5 (dbg_reg5),
       .we   (dbg_print),
       .tx_out  (DBG_TX)
       );

  function [7:0] otoc(input [2:0] oct);
     case (oct)
       3'o0: otoc="0";
       3'o1: otoc="1";
       3'o2: otoc="2";
       3'o3: otoc="3";
       3'o4: otoc="4";
       3'o5: otoc="5";
       3'o6: otoc="6";
       3'o7: otoc="7";
     endcase
  endfunction
  
  function [15:0] MPIA(input [1:0] ia_mp);
     case (ia_mp)
       2'b00: MPIA="0 ";
       2'b01: MPIA="  ";
       2'b10: MPIA="0I";
       2'b11: MPIA=" I";
     endcase
  endfunction

  function [39:0] opname(input [11:0] opcode);
     case (opcode[11:9])
       OP_AND: opname={"AND", MPIA(opcode[8:7])};
       OP_TAD: opname={"TAD", MPIA(opcode[8:7])};
       OP_ISZ: opname={"ISZ", MPIA(opcode[8:7])};
       OP_DCA: opname={"DCA", MPIA(opcode[8:7])};
       OP_JMS: opname={"JMS", MPIA(opcode[8:7])};
       OP_JMP: opname={"JMP", MPIA(opcode[8:7])};
       OP_IOT: 
	 case (opcode[11:0])
	   IOT_SKON: opname = "SKON ";
	   IOT_ION:  opname = "ION  ";
	   IOT_IOF:  opname = "IOF  ";
	   IOT_CAF:  opname = "CAF  ";
	   IOT_KSF:  opname = "KSF  ";
	   IOT_KCC:  opname = "KCC  ";
	   IOT_KRS:  opname = "KRS  ";
	   IOT_KIE:  opname = "KIE  ";
	   IOT_KRB:  opname = "KRB  ";
	   IOT_TFL:  opname = "TFL  ";
	   IOT_TSF:  opname = "TSF  ";
	   IOT_TCF:  opname = "TCF  ";
	   IOT_TPC:  opname = "TPC  ";
	   IOT_TLS:  opname = "TLS  ";
	   IOT_GTF:  opname = "GTF  ";
	   IOT_RTF:  opname = "RTF  ";
	   IOT_RDF:  opname = "RDF  ";
	   IOT_RIF:  opname = "RIF  ";
	   IOT_RIB:  opname = "RIB  ";
	   IOT_RMF:  opname = "RMF  ";
	   IOT_LIF:  opname = "LIF  ";
	   IOT_DSKP: opname = "DSKP ";
	   IOT_DCLR: opname = "DCLR ";
	   IOT_DLAG: opname = "DLAG ";
	   IOT_DLCA: opname = "DLCA ";
	   IOT_DRST: opname = "DRST ";
	   IOT_DLDC: opname = "DLDC ";
	   default:
	     case({opcode[11:6],opcode[2:0]})
	       IOT_N_CDF: opname = {"CDF ", otoc(opcode[5:3])};
	       IOT_N_CIF: opname = {"CIF ", otoc(opcode[5:3])};
	       IOT_N_CDI: opname = {"CDI ", otoc(opcode[5:3])};
	       default: opname = "IOT  ";
	     endcase
	 endcase // IOT
       default: // 7xxx
	 case(opcode[11:0])
	   12'o7000: opname = "NOP  ";
	   12'o7001: opname = "IAC  ";
	   12'o7004: opname = "RAL  ";
	   12'o7006: opname = "RTL  ";
	   12'o7010: opname = "RAR  ";
	   12'o7012: opname = "RTR  ";
	   12'o7020: opname = "CML  ";
	   12'o7040: opname = "CMA  ";
	   12'o7041: opname = "CIA  ";
	   12'o7064: opname = "CMALL";
	   12'o7070: opname = "CMALR";
	   12'o7100: opname = "CLL  ";
	   12'o7104: opname = "CLRAL";
	   12'o7106: opname = "CLRTL";
	   12'o7110: opname = "CLRAR";
	   12'o7112: opname = "CLRTR";
	   12'o7130: opname = "SLRAR";
	   12'o7200: opname = "CLA  ";
	   12'o7240: opname = "STA  ";
	   12'o7300: opname = "CLAL ";
	   12'o7301: opname = "CLIAC";
	   12'o7332: opname = "A1024";
	   12'o7346: opname = "AC=-3";
	   12'o7400: opname = "NOP  ";
	   12'o7402: opname = "HLT  ";
	   12'o7404: opname = "OSR  ";
	   12'o7410: opname = "SKP  ";
	   12'o7440: opname = "SZA  ";
	   12'o7450: opname = "SNA  ";
	   12'o7500: opname = "SMA  ";
	   12'o7550: opname = "SPASN";
	   12'o7510: opname = "SPA  ";
	   12'o7530: opname = "SPAZL";
	   12'o7600: opname = "CLA  ";
	   12'o7640: opname = "SZACL";
	   12'o7650: opname = "SNACL";
	   12'o7700: opname = "SMACL";
	   12'o7710: opname = "SPACL";
	   12'o7720: opname = "SMANL";
	   12'o7401: opname = "NOP  ";
	   12'o7421: opname = "MQL  ";
	   12'o7501: opname = "MQA  ";
	   12'o7521: opname = "SWP  ";
	   12'o7601: opname = "CLA  ";
	   12'o7621: opname = "CAM  ";
	   12'o7701: opname = "ACL  ";
	   12'o7721: opname = "CLSWP";
	   default:
	     if(opcode[8] == 1'b0) // Group 1
	       opname = "GRP1 ";
	     else if(opcode[0])  // Group 2
		if(opcode[1])
		  opname = "G2HLT";
		else
		  opname = "GRP2 ";
	     else // Group 3
	       opname = "GRP3 ";
	 endcase
     endcase
  endfunction
  
  wire trg_log_inst = posedge_RUN_HLT_n 
       | (inst_read & (CPU_CLK_FRQ <= 1000));
//       | (inst_cp_read & (CPU_CLK_FRQ <= 1000));  // for debug CP monitor
  wire trg_log_disk = disk_read | disk_write;
  always @(posedge sys_clk or negedge RESET_n)
    if( ~RESET_n ) begin
       dbg_regw <= "     ";
       {dbg_reg0, dbg_reg1, dbg_reg2, dbg_reg3, dbg_reg4, dbg_reg5} <= 0;
       dbg_print <= 0;
    end
    else if (dbg_print)
      dbg_print <= 0;
    else if( trg_log_inst ) begin
       dbg_regw <= opname(last_inst);
       dbg_reg0 <= last_inst_addr;
       dbg_reg1 <= last_inst;
       dbg_reg2 <= last_read_addr;
       dbg_reg3 <= last_read_data;
       dbg_reg4 <= last_write_addr;
       dbg_reg5 <= last_write_data;
       dbg_print<= 1'b1;
    end
    else if ( trg_log_disk ) begin
       if(disk_read)
	 dbg_regw <= "RK rd";
       else if(disk_write)
	 dbg_regw <= "RK wr";
       else
	 dbg_regw <= "????"; // cannot come here
       dbg_reg0 <= last_inst_addr;
       dbg_reg1 <= RK_REG_CMD;
       dbg_reg2 <= RK_dma_wordcount;
       dbg_reg3 <= RK_dma_start_address >> 1;
       dbg_reg4 <= disk_block_address[12:0];
       dbg_reg5 <= disk_block_address[15:13];
       dbg_print<= 1'b1;
    end

`else
  assign DBG_TX = 1'b1;
`endif

endmodule
