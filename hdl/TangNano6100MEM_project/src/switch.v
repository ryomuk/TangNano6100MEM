// switch.v
// physical switch to logical switch converter
// 
// by Ryo Mukai
// 2026/01/22

module switch
  #(
    parameter CLK_FRQ    = 27_000_000, // CLK (Hz)
    parameter DEBOUNCE   = 10,	       // wait time for debounce (ms)
    parameter DOUBLE     = 500,	       // time for double click  (ms)
    parameter HOLD       = 1000,       // wait time for hold     (ms)
    parameter REPEAT     = 33,         // repeat cycle           (ms)
    parameter WIDTH      = 3	       // bit width of sw_count
    )
  (
   input		    clk,
   input		    sw_phy,	// physical switch
   output reg		    sw_deb,	// debounced switch
   output		    sw_hold,	// hold switch
   output		    sw_double,	// double click
   output		    sw_repeat,	// repeat (enabled after hold)
   output		    sw_toggle,	// toggle switch = sw_count[0]
   output		    sw_posedge,	// positive edge
   output		    sw_negedge,	// negative edge
   output reg [(WIDTH-1):0] sw_count,	// counter switch
   input		    reset_count

);

  localparam DEBOUNCE_CLK = (CLK_FRQ / 1000) * DEBOUNCE;
  localparam DOUBLE_CLK   = (CLK_FRQ / 1000) * DOUBLE;
  localparam HOLD_CLK     = (CLK_FRQ / 1000) * HOLD;
  localparam REPEAT_CLK   = (CLK_FRQ / 1000) * REPEAT;

//------------------------------------------------------------------------
// Debounce
//------------------------------------------------------------------------
  wire sw = sw_phy; // just an alias
  reg  last_sw;
  always @( posedge clk )
    last_sw <= sw;

  reg [27:0] cnt_deb = 0;
  always @( posedge clk )
    if(cnt_deb == DEBOUNCE_CLK) begin
       if(sw_deb != sw) begin
	  sw_deb <= sw;
	  cnt_deb <= 0;
       end
    end
    else  if(last_sw != sw)      // reset counter while bouncing
      cnt_deb <= 0;
    else
      cnt_deb <= cnt_deb + 1'b1; // counts up to DEBOUNCE_CLK

//------------------------------------------------------------------------
//edges of sw_deb
//------------------------------------------------------------------------
  assign sw_posedge  = sw_debs[0] & ~sw_debs[1];
  assign sw_negedge  = sw_debs[1] & ~sw_debs[0];
  reg [1:0] sw_debs;
  always @( posedge clk )
    sw_debs <= {sw_debs[0], sw_deb};
  
//------------------------------------------------------------------------
// Toggle
//------------------------------------------------------------------------
  assign sw_toggle = sw_count[0];

//------------------------------------------------------------------------
// Count
//------------------------------------------------------------------------
  always @(posedge clk )
    if( reset_count )
      sw_count <= 0;
    else if( sw_posedge )
      sw_count <= sw_count + 1'b1;

//------------------------------------------------------------------------
// Hold
//------------------------------------------------------------------------
  assign sw_hold = sw_deb & hold_enable;
  
  reg	     hold_enable;
  reg [27:0] cnt_hold = 0;
  always @(posedge clk)
    if( ~sw_deb )
      cnt_hold <= 0;                    // reset counter if sw_deb is off
    else if(cnt_hold != HOLD_CLK) begin // cnt_hold < HOLD_CLK
       cnt_hold <= cnt_hold + 1'b1;     // counts up to HOLD_CLK
       hold_enable <= 0;
    end
    else
      hold_enable <= 1'b1;
  
//------------------------------------------------------------------------
// Double Click
//------------------------------------------------------------------------
  assign sw_double = sw_deb & double_enable;
  
  reg	     double_enable;
  reg [27:0] cnt_double = 0;
  always @(posedge clk)
    if( cnt_double == DOUBLE_CLK) begin
       if( ~sw_deb ) begin
	  double_enable <= 0;
	  cnt_double <= DOUBLE_CLK;  // reset and wait for first click
       end
       else if( sw_posedge )
	 cnt_double <= 0;            // reet counter and wait for second click
    end
    else if( sw_posedge ) begin      // posedge in time
       double_enable <= 1'b1;        // double clicked
       cnt_double <= DOUBLE_CLK;     // to cancel triple click
    end
    else
      cnt_double <= cnt_double + 1'b1; // count up to DOUBLE_CLK

//------------------------------------------------------------------------
// Repeated Click
//------------------------------------------------------------------------
  assign sw_repeat = reg_repeat;
  reg [25:0]		cnt_repeat;
  reg			reg_repeat;
  always @(posedge clk)
    if( ~sw_hold ) begin
       cnt_repeat <= 0;
       reg_repeat <= 0;
    end
    else if(cnt_repeat == REPEAT_CLK / 2) begin
       cnt_repeat <= 0;
       reg_repeat <= ~reg_repeat;
    end
    else 
      cnt_repeat <= cnt_repeat + 1'b1;

endmodule
