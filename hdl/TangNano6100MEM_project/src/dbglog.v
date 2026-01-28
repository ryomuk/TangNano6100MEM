// log print module for dbg_tx UART
//  - print regw:reg0,reg1,reg2,reg3,reg4,reg5
//
// 2026/01/18
// by Ryo Mukai

module dbglog
  #(
    parameter CLK_FRQ = 27_000_000, // CLK (37.04ns)
    parameter BAUD_RATE = 115_200
    )
  (
   input	clk,
   input	reset_n,
   output	tx_out,
   input [39:0]	regw,
   input [31:0]	reg0,
   input [31:0]	reg1,
   input [31:0]	reg2,
   input [31:0]	reg3,
   input [31:0]	reg4,
   input [31:0]	reg5,
   input	we
);

// uart tx module for log
  reg [7:0]	 tx_data;
  reg		 tx_send;
  wire		 tx_ready;
  uart_tx#
    (
     .CLK_FRQ(CLK_FRQ),
     .BAUD_RATE(BAUD_RATE)
     ) uart_tx_inst_dbg
      (
       .clk           (clk),
       .reset_n       (reset_n),
       .tx_data       (tx_data),
       .tx_send       (tx_send),
       .tx_ready      (tx_ready),
       .tx_out        (tx_out)
       );

//---------------------------------------------------------------------------
// debug_print
// print regw:reg0,reg1,reg2,reg3,reg4
//---------------------------------------------------------------------------
  function [7:0] itoh(input [3:0] x);
     case (x)
       4'h0: itoh="0"; 4'h1: itoh="1"; 4'h2: itoh="2"; 4'h3: itoh="3";
       4'h4: itoh="4"; 4'h5: itoh="5"; 4'h6: itoh="6"; 4'h7: itoh="7";
       4'h8: itoh="8"; 4'h9: itoh="9"; 4'ha: itoh="a"; 4'hb: itoh="b";
       4'hc: itoh="c"; 4'hd: itoh="d"; 4'he: itoh="e"; 4'hf: itoh="f";
     endcase
  endfunction
  function [7:0] itoh0(input [15:0] x); itoh0 = itoh(x[3:0]);   endfunction
  function [7:0] itoh1(input [15:0] x); itoh1 = itoh(x[7:4]);   endfunction
  function [7:0] itoh2(input [15:0] x); itoh2 = itoh(x[11:8]);  endfunction
  function [7:0] itoh3(input [15:0] x); itoh3 = itoh(x[15:12]); endfunction

  function [7:0] itoo(input [2:0] x);
     case (x)
       4'h0: itoo="0"; 4'h1: itoo="1"; 4'h2: itoo="2"; 4'h3: itoo="3";
       4'h4: itoo="4"; 4'h5: itoo="5"; 4'h6: itoo="6"; 4'h7: itoo="7";
     endcase
  endfunction
  function [7:0] itoo0(input [17:0] x); itoo0 = itoo(x[2:0]);  endfunction
  function [7:0] itoo1(input [17:0] x); itoo1 = itoo(x[5:3]);  endfunction
  function [7:0] itoo2(input [17:0] x); itoo2 = itoo(x[8:6]);  endfunction
  function [7:0] itoo3(input [17:0] x); itoo3 = itoo(x[11:9]); endfunction
  function [7:0] itoo4(input [17:0] x); itoo4 = itoo(x[14:12]);endfunction
  function [7:0] itoo5(input [17:0] x); itoo5 = itoo(x[17:15]);endfunction

  reg [7:0]  dbg_pstate;
  reg [7:0]  dbg_pbuf[255:0];
  reg [7:0]  dbg_pcnt;
  localparam  DBG_PSTATE_IDLE  = 8'd255;
  localparam  DBG_PSTATE_PRINT = 8'd254;
  localparam  DBG_PSTATE_WAIT  = 8'd253;
  localparam  DBG_PSTATE_CLEAR = 8'd252;
  reg	     dbg_clear; // for hand shake
  always @(posedge clk or negedge reset_n)
    if( ~reset_n ) begin
       dbg_pstate <= DBG_PSTATE_IDLE;
       dbg_clear <= 0;
    end
    else
      case (dbg_pstate)
	DBG_PSTATE_IDLE:
	  if( we ) begin
	     dbg_pstate <= 8'd0;
	     dbg_pcnt   <= 8'd0;
	  end
	  else
	    dbg_pstate <= DBG_PSTATE_IDLE;
	8'd0 : {dbg_pbuf[0 ], dbg_pstate} <= {itoh3(regt), 8'd1 };
	8'd1 : {dbg_pbuf[1 ], dbg_pstate} <= {itoh2(regt), 8'd2 };
	8'd2 : {dbg_pbuf[2 ], dbg_pstate} <= {itoh1(regt), 8'd3 };
	8'd3 : {dbg_pbuf[3 ], dbg_pstate} <= {itoh0(regt), 8'd4 };
	8'd4 : {dbg_pbuf[4 ], dbg_pstate} <= {":",         8'd5 };
	8'd5 : {dbg_pbuf[5 ], dbg_pstate} <= {regw[39:32], 8'd6 };
	8'd6 : {dbg_pbuf[6 ], dbg_pstate} <= {regw[31:24], 8'd7 };
	8'd7 : {dbg_pbuf[7 ], dbg_pstate} <= {regw[23:16], 8'd8 };
	8'd8 : {dbg_pbuf[8 ], dbg_pstate} <= {regw[15:8],  8'd9 };
	8'd9 : {dbg_pbuf[9 ], dbg_pstate} <= {regw[7:0],   8'd10};
	8'd10: {dbg_pbuf[10], dbg_pstate} <= {",",         8'd11};
	8'd11: {dbg_pbuf[11], dbg_pstate} <= {itoo5(reg0), 8'd12};
	8'd12: {dbg_pbuf[12], dbg_pstate} <= {itoo4(reg0), 8'd13};
	8'd13: {dbg_pbuf[13], dbg_pstate} <= {itoo3(reg0), 8'd14};
	8'd14: {dbg_pbuf[14], dbg_pstate} <= {itoo2(reg0), 8'd15};
	8'd15: {dbg_pbuf[15], dbg_pstate} <= {itoo1(reg0), 8'd16};
	8'd16: {dbg_pbuf[16], dbg_pstate} <= {itoo0(reg0), 8'd17};
	8'd17: {dbg_pbuf[17], dbg_pstate} <= {",",         8'd18};
	8'd18: {dbg_pbuf[18], dbg_pstate} <= {itoo5(reg1), 8'd19};
	8'd19: {dbg_pbuf[19], dbg_pstate} <= {itoo4(reg1), 8'd20};
	8'd20: {dbg_pbuf[20], dbg_pstate} <= {itoo3(reg1), 8'd21};
	8'd21: {dbg_pbuf[21], dbg_pstate} <= {itoo2(reg1), 8'd22};
	8'd22: {dbg_pbuf[22], dbg_pstate} <= {itoo1(reg1), 8'd23};
	8'd23: {dbg_pbuf[23], dbg_pstate} <= {itoo0(reg1), 8'd24};
	8'd24: {dbg_pbuf[24], dbg_pstate} <= {",",         8'd25};
	8'd25: {dbg_pbuf[25], dbg_pstate} <= {itoo5(reg2), 8'd26};
	8'd26: {dbg_pbuf[26], dbg_pstate} <= {itoo4(reg2), 8'd27};
	8'd27: {dbg_pbuf[27], dbg_pstate} <= {itoo3(reg2), 8'd28};
	8'd28: {dbg_pbuf[28], dbg_pstate} <= {itoo2(reg2), 8'd29};
	8'd29: {dbg_pbuf[29], dbg_pstate} <= {itoo1(reg2), 8'd30};
	8'd30: {dbg_pbuf[30], dbg_pstate} <= {itoo0(reg2), 8'd31};
	8'd31: {dbg_pbuf[31], dbg_pstate} <= {",",         8'd32};
	8'd32: {dbg_pbuf[32], dbg_pstate} <= {itoo5(reg3), 8'd33};
	8'd33: {dbg_pbuf[33], dbg_pstate} <= {itoo4(reg3), 8'd34};
	8'd34: {dbg_pbuf[34], dbg_pstate} <= {itoo3(reg3), 8'd35};
	8'd35: {dbg_pbuf[35], dbg_pstate} <= {itoo2(reg3), 8'd36};
	8'd36: {dbg_pbuf[36], dbg_pstate} <= {itoo1(reg3), 8'd37};
	8'd37: {dbg_pbuf[37], dbg_pstate} <= {itoo0(reg3), 8'd38};
	8'd38: {dbg_pbuf[38], dbg_pstate} <= {",",         8'd39};
	8'd39: {dbg_pbuf[39], dbg_pstate} <= {itoo5(reg4), 8'd40};
	8'd40: {dbg_pbuf[40], dbg_pstate} <= {itoo4(reg4), 8'd41};
	8'd41: {dbg_pbuf[41], dbg_pstate} <= {itoo3(reg4), 8'd42};
	8'd42: {dbg_pbuf[42], dbg_pstate} <= {itoo2(reg4), 8'd43};
	8'd43: {dbg_pbuf[43], dbg_pstate} <= {itoo1(reg4), 8'd44};
	8'd44: {dbg_pbuf[44], dbg_pstate} <= {itoo0(reg4), 8'd45};
	8'd45: {dbg_pbuf[45], dbg_pstate} <= {",",         8'd46};
	8'd46: {dbg_pbuf[46], dbg_pstate} <= {itoo5(reg5), 8'd47};
	8'd47: {dbg_pbuf[47], dbg_pstate} <= {itoo4(reg5), 8'd48};
	8'd48: {dbg_pbuf[48], dbg_pstate} <= {itoo3(reg5), 8'd49};
	8'd49: {dbg_pbuf[49], dbg_pstate} <= {itoo2(reg5), 8'd50};
	8'd50: {dbg_pbuf[50], dbg_pstate} <= {itoo1(reg5), 8'd51};
	8'd51: {dbg_pbuf[51], dbg_pstate} <= {itoo0(reg5), 8'd52};
	8'd52: {dbg_pbuf[52], dbg_pstate} <= {8'h0d,       8'd53}; // \r
	8'd53: {dbg_pbuf[53], dbg_pstate} <= {8'h0a,       8'd54}; // \n
	8'd54: {dbg_pbuf[54], dbg_pstate} <= {8'b0, DBG_PSTATE_CLEAR};
	DBG_PSTATE_CLEAR:
	  if( we )
	    dbg_clear <= 1'b1;
	  else if( ~we ) begin
	     dbg_clear <= 0;
	     dbg_pstate <= DBG_PSTATE_PRINT;
	  end
	DBG_PSTATE_PRINT:
	  if( dbg_pbuf[dbg_pcnt] == 8'b0)
	    dbg_pstate <= DBG_PSTATE_IDLE;
	  else if( tx_ready ) begin
	     tx_data <= dbg_pbuf[dbg_pcnt];
	     tx_send <= 1;
	     dbg_pcnt <= dbg_pcnt + 1'd1;
	     dbg_pstate <= DBG_PSTATE_WAIT;
	  end
	DBG_PSTATE_WAIT:
	  if( ~tx_ready ) begin
	     tx_send <= 0;
	     dbg_pstate <= DBG_PSTATE_PRINT;
	  end

	// dummy to avoid warning
	default: dbg_pbuf[dbg_pstate] <= 0;
      endcase
  
  // 6 digits bcd counter for timer
  wire [15:0] regt = dbg_time[23:8]; // msec counter to print
  reg [19:0] cnt_10us;
  reg [23:0] dbg_time;
  always @(posedge clk or negedge reset_n)
    if( ~reset_n )
      {cnt_10us, dbg_time} <= 0;
    else if(cnt_10us == (CLK_FRQ / 1000 / 100) -1) begin // 10us
       cnt_10us <= 0;
       if(     dbg_time[23:0] == 'h999999)
	 dbg_time <= 0;
       else if(dbg_time[19:0] == 'h99999)
	 dbg_time <= {dbg_time[23:20] + 1'b1, 20'h0};
       else if(dbg_time[15:0] == 'h9999)
	 dbg_time <= {dbg_time[23:16] + 1'b1, 16'h0};
       else if( dbg_time[11:0] == 'h999)
	 dbg_time <= {dbg_time[23:12] + 1'b1, 12'h0};
       else if( dbg_time[7:0] == 'h99)
	 dbg_time <= {dbg_time[23:8]  + 1'b1, 8'h0};
       else if( dbg_time[3:0] == 'h9)
	 dbg_time <= {dbg_time[23:4]  + 1'b1, 4'h0};
       else
	 dbg_time <= dbg_time + 1'd1;
    end
    else
      cnt_10us <= cnt_10us + 1'd1;


endmodule
