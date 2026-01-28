// WS2812B RGB LED matrix array driver
// 2026/01/14
// by Ryo Mukai

// WIDTHxHEIGHT is 6x10, 10x6, 12x10, 20x6

module ws2812_matrix
  #(
    parameter CLK_FRQ = 27_000_000,
    parameter BRIGHTNESS_R = 8'h02,
    parameter BRIGHTNESS_G = 8'h02,
    parameter BRIGHTNESS_B = 8'h02,
    parameter WIDTH = 6,
    parameter HEIGHT = 10,
    parameter LEDS = WIDTH * HEIGHT
    )
  (
   input	    clk,
   output	    sout,
   input [LEDS-1:0] r,
   input [LEDS-1:0] g,
   input [LEDS-1:0] b
   );
  
  // mapping from bitmap to 6x10 matrix is straightforward
  //MSB-> 0  1  2  3  4  5
  //      6  8  9 10 11 12
  //      ...
  //     54 55 56 57 58 59
  function [(60*8)-1:0] bmp2stream_6x10(input [59:0] x, [7:0] br);
     bmp2stream_6x10[(60*8)-1:0]
       = {
	  x[ 0] ? br: 8'h00,
	  x[ 1] ? br: 8'h00,
	  x[ 2] ? br: 8'h00,
	  x[ 3] ? br: 8'h00,
	  x[ 4] ? br: 8'h00,
	  x[ 5] ? br: 8'h00,
	  x[ 6] ? br: 8'h00,
	  x[ 7] ? br: 8'h00,
	  x[ 8] ? br: 8'h00,
	  x[ 9] ? br: 8'h00,
	  x[10] ? br: 8'h00,
	  x[11] ? br: 8'h00,
	  x[12] ? br: 8'h00,
	  x[13] ? br: 8'h00,
	  x[14] ? br: 8'h00,
	  x[15] ? br: 8'h00,
	  x[16] ? br: 8'h00,
	  x[17] ? br: 8'h00,
	  x[18] ? br: 8'h00,
	  x[19] ? br: 8'h00,
	  x[20] ? br: 8'h00,
	  x[21] ? br: 8'h00,
	  x[22] ? br: 8'h00,
	  x[23] ? br: 8'h00,
	  x[24] ? br: 8'h00,
	  x[25] ? br: 8'h00,
	  x[26] ? br: 8'h00,
	  x[27] ? br: 8'h00,
	  x[28] ? br: 8'h00,
	  x[29] ? br: 8'h00,
	  x[30] ? br: 8'h00,
	  x[31] ? br: 8'h00,
	  x[32] ? br: 8'h00,
	  x[33] ? br: 8'h00,
	  x[34] ? br: 8'h00,
	  x[35] ? br: 8'h00,
	  x[36] ? br: 8'h00,
	  x[37] ? br: 8'h00,
	  x[38] ? br: 8'h00,
	  x[39] ? br: 8'h00,
	  x[40] ? br: 8'h00,
	  x[41] ? br: 8'h00,
	  x[42] ? br: 8'h00,
	  x[43] ? br: 8'h00,
	  x[44] ? br: 8'h00,
	  x[45] ? br: 8'h00,
	  x[46] ? br: 8'h00,
	  x[47] ? br: 8'h00,
	  x[48] ? br: 8'h00,
	  x[49] ? br: 8'h00,
	  x[50] ? br: 8'h00,
	  x[51] ? br: 8'h00,
	  x[52] ? br: 8'h00,
	  x[53] ? br: 8'h00,
	  x[54] ? br: 8'h00,
	  x[55] ? br: 8'h00,
	  x[56] ? br: 8'h00,
	  x[57] ? br: 8'h00,
	  x[58] ? br: 8'h00,
	  x[59] ? br: 8'h00
};
  endfunction

  // mapping from bitmap to 10x6 matrix
  //         0  1 ...  9
  //        ..
  //        40 41 ... 49
  // MSB -> 50 51 ... 59
  //
  function [(60*8)-1:0] bmp2stream_10x6(input [59:0] x, [7:0] br);
     bmp2stream_10x6[(60*8)-1:0]
       = {
	  x[50] ? br: 8'h00,
	  x[40] ? br: 8'h00,
	  x[30] ? br: 8'h00,
	  x[20] ? br: 8'h00,
	  x[10] ? br: 8'h00,
	  x[ 0] ? br: 8'h00,
//
	  x[51] ? br: 8'h00,
	  x[41] ? br: 8'h00,
	  x[31] ? br: 8'h00,
	  x[21] ? br: 8'h00,
	  x[11] ? br: 8'h00,
	  x[ 1] ? br: 8'h00,
//
	  x[52] ? br: 8'h00,
	  x[42] ? br: 8'h00,
	  x[32] ? br: 8'h00,
	  x[22] ? br: 8'h00,
	  x[12] ? br: 8'h00,
	  x[ 2] ? br: 8'h00,
//
	  x[53] ? br: 8'h00,
	  x[43] ? br: 8'h00,
	  x[33] ? br: 8'h00,
	  x[23] ? br: 8'h00,
	  x[13] ? br: 8'h00,
	  x[ 3] ? br: 8'h00,
//
	  x[54] ? br: 8'h00,
	  x[44] ? br: 8'h00,
	  x[34] ? br: 8'h00,
	  x[24] ? br: 8'h00,
	  x[14] ? br: 8'h00,
	  x[ 4] ? br: 8'h00,
//
	  x[55] ? br: 8'h00,
	  x[45] ? br: 8'h00,
	  x[35] ? br: 8'h00,
	  x[25] ? br: 8'h00,
	  x[15] ? br: 8'h00,
	  x[ 5] ? br: 8'h00,
//
	  x[56] ? br: 8'h00,
	  x[46] ? br: 8'h00,
	  x[36] ? br: 8'h00,
	  x[26] ? br: 8'h00,
	  x[16] ? br: 8'h00,
	  x[ 6] ? br: 8'h00,
//
	  x[57] ? br: 8'h00,
	  x[47] ? br: 8'h00,
	  x[37] ? br: 8'h00,
	  x[27] ? br: 8'h00,
	  x[17] ? br: 8'h00,
	  x[ 7] ? br: 8'h00,
//
	  x[58] ? br: 8'h00,
	  x[48] ? br: 8'h00,
	  x[38] ? br: 8'h00,
	  x[28] ? br: 8'h00,
	  x[18] ? br: 8'h00,
	  x[ 8] ? br: 8'h00,
//
	  x[59] ? br: 8'h00,
	  x[49] ? br: 8'h00,
	  x[39] ? br: 8'h00,
	  x[29] ? br: 8'h00,
	  x[19] ? br: 8'h00,
	  x[ 9] ? br: 8'h00
};
  endfunction
     
  // mapping from bitmap to 20x6 matrix
  //         0   1 ...   9  10 ...  19
  //        20  21
  //        40  41
  //        60  61
  //        80  81      89  90 ...  99
  // MSB-> 100 101 ... 109 110 ... 119
  // 
  //   
  function [120*8-1:0] bmp2stream_20x6(input [119:0] x, [7:0] br);
     bmp2stream_20x6[120*8-1:0]
       = {
	  x[100] ? br: 8'h00,
	  x[ 80] ? br: 8'h00,
	  x[ 60] ? br: 8'h00,
	  x[ 40] ? br: 8'h00,
	  x[ 20] ? br: 8'h00,
	  x[  0] ? br: 8'h00,
//
	  x[101] ? br: 8'h00,
	  x[ 81] ? br: 8'h00,
	  x[ 61] ? br: 8'h00,
	  x[ 41] ? br: 8'h00,
	  x[ 21] ? br: 8'h00,
	  x[  1] ? br: 8'h00,
//
	  x[102] ? br: 8'h00,
	  x[ 82] ? br: 8'h00,
	  x[ 62] ? br: 8'h00,
	  x[ 42] ? br: 8'h00,
	  x[ 22] ? br: 8'h00,
	  x[  2] ? br: 8'h00,
//
	  x[103] ? br: 8'h00,
	  x[ 83] ? br: 8'h00,
	  x[ 63] ? br: 8'h00,
	  x[ 43] ? br: 8'h00,
	  x[ 23] ? br: 8'h00,
	  x[  3] ? br: 8'h00,
//
	  x[104] ? br: 8'h00,
	  x[ 84] ? br: 8'h00,
	  x[ 64] ? br: 8'h00,
	  x[ 44] ? br: 8'h00,
	  x[ 24] ? br: 8'h00,
	  x[  4] ? br: 8'h00,
//
	  x[105] ? br: 8'h00,
	  x[ 85] ? br: 8'h00,
	  x[ 65] ? br: 8'h00,
	  x[ 45] ? br: 8'h00,
	  x[ 25] ? br: 8'h00,
	  x[  5] ? br: 8'h00,
//
	  x[106] ? br: 8'h00,
	  x[ 86] ? br: 8'h00,
	  x[ 66] ? br: 8'h00,
	  x[ 46] ? br: 8'h00,
	  x[ 26] ? br: 8'h00,
	  x[  6] ? br: 8'h00,
//
	  x[107] ? br: 8'h00,
	  x[ 87] ? br: 8'h00,
	  x[ 67] ? br: 8'h00,
	  x[ 47] ? br: 8'h00,
	  x[ 27] ? br: 8'h00,
	  x[  7] ? br: 8'h00,
//
	  x[108] ? br: 8'h00,
	  x[ 88] ? br: 8'h00,
	  x[ 68] ? br: 8'h00,
	  x[ 48] ? br: 8'h00,
	  x[ 28] ? br: 8'h00,
	  x[  8] ? br: 8'h00,
//
	  x[109] ? br: 8'h00,
	  x[ 89] ? br: 8'h00,
	  x[ 69] ? br: 8'h00,
	  x[ 49] ? br: 8'h00,
	  x[ 29] ? br: 8'h00,
	  x[  9] ? br: 8'h00,
//
	  x[110] ? br: 8'h00,
	  x[ 90] ? br: 8'h00,
	  x[ 70] ? br: 8'h00,
	  x[ 50] ? br: 8'h00,
	  x[ 30] ? br: 8'h00,
	  x[ 10] ? br: 8'h00,
//
	  x[111] ? br: 8'h00,
	  x[ 91] ? br: 8'h00,
	  x[ 71] ? br: 8'h00,
	  x[ 51] ? br: 8'h00,
	  x[ 31] ? br: 8'h00,
	  x[ 11] ? br: 8'h00,
//
	  x[112] ? br: 8'h00,
	  x[ 92] ? br: 8'h00,
	  x[ 72] ? br: 8'h00,
	  x[ 52] ? br: 8'h00,
	  x[ 32] ? br: 8'h00,
	  x[ 12] ? br: 8'h00,
//
	  x[113] ? br: 8'h00,
	  x[ 93] ? br: 8'h00,
	  x[ 73] ? br: 8'h00,
	  x[ 53] ? br: 8'h00,
	  x[ 33] ? br: 8'h00,
	  x[ 13] ? br: 8'h00,
//
	  x[114] ? br: 8'h00,
	  x[ 94] ? br: 8'h00,
	  x[ 74] ? br: 8'h00,
	  x[ 54] ? br: 8'h00,
	  x[ 34] ? br: 8'h00,
	  x[ 14] ? br: 8'h00,
//
	  x[115] ? br: 8'h00,
	  x[ 95] ? br: 8'h00,
	  x[ 75] ? br: 8'h00,
	  x[ 55] ? br: 8'h00,
	  x[ 35] ? br: 8'h00,
	  x[ 15] ? br: 8'h00,
//
	  x[116] ? br: 8'h00,
	  x[ 96] ? br: 8'h00,
	  x[ 76] ? br: 8'h00,
	  x[ 56] ? br: 8'h00,
	  x[ 36] ? br: 8'h00,
	  x[ 16] ? br: 8'h00,
//
	  x[117] ? br: 8'h00,
	  x[ 97] ? br: 8'h00,
	  x[ 77] ? br: 8'h00,
	  x[ 57] ? br: 8'h00,
	  x[ 37] ? br: 8'h00,
	  x[ 17] ? br: 8'h00,
//
	  x[118] ? br: 8'h00,
	  x[ 98] ? br: 8'h00,
	  x[ 78] ? br: 8'h00,
	  x[ 58] ? br: 8'h00,
	  x[ 38] ? br: 8'h00,
	  x[ 18] ? br: 8'h00,
//
	  x[119] ? br: 8'h00,
	  x[ 99] ? br: 8'h00,
	  x[ 79] ? br: 8'h00,
	  x[ 59] ? br: 8'h00,
	  x[ 39] ? br: 8'h00,
	  x[ 19] ? br: 8'h00
};
  endfunction

  // mapping from bitmap to 6x10 matrix is straightforward
  //MSB->  0    1 ...   5 |   6   7 ...  11
  //      12   13 ...  17 |  18  19 ...  23
  //      ..
  //      108 109 ... 113 | 114 115 ... 119
  function [120*8-1:0] bmp2stream_12x10(input [119:0] x, [7:0] br);
     bmp2stream_12x10[120*8-1:0]
       = {
	  x[ 0] ? br: 8'h00,
	  x[ 1] ? br: 8'h00,
	  x[ 2] ? br: 8'h00,
	  x[ 3] ? br: 8'h00,
	  x[ 4] ? br: 8'h00,
	  x[ 5] ? br: 8'h00,
//
	  x[12] ? br: 8'h00,
	  x[13] ? br: 8'h00,
	  x[14] ? br: 8'h00,
	  x[15] ? br: 8'h00,
	  x[16] ? br: 8'h00,
	  x[17] ? br: 8'h00,
//
	  x[24] ? br: 8'h00,
	  x[25] ? br: 8'h00,
	  x[26] ? br: 8'h00,
	  x[27] ? br: 8'h00,
	  x[28] ? br: 8'h00,
	  x[29] ? br: 8'h00,

	  x[36] ? br: 8'h00,
	  x[37] ? br: 8'h00,
	  x[38] ? br: 8'h00,
	  x[39] ? br: 8'h00,
	  x[40] ? br: 8'h00,
	  x[41] ? br: 8'h00,
//
	  x[48] ? br: 8'h00,
	  x[49] ? br: 8'h00,
	  x[50] ? br: 8'h00,
	  x[51] ? br: 8'h00,
	  x[52] ? br: 8'h00,
	  x[53] ? br: 8'h00,
//
	  x[60] ? br: 8'h00,
	  x[61] ? br: 8'h00,
	  x[62] ? br: 8'h00,
	  x[63] ? br: 8'h00,
	  x[64] ? br: 8'h00,
	  x[65] ? br: 8'h00,
//
	  x[72] ? br: 8'h00,
	  x[73] ? br: 8'h00,
	  x[74] ? br: 8'h00,
	  x[75] ? br: 8'h00,
	  x[76] ? br: 8'h00,
	  x[77] ? br: 8'h00,
//
	  x[84] ? br: 8'h00,
	  x[85] ? br: 8'h00,
	  x[86] ? br: 8'h00,
	  x[87] ? br: 8'h00,
	  x[88] ? br: 8'h00,
	  x[89] ? br: 8'h00,

	  x[96] ? br: 8'h00,
	  x[97] ? br: 8'h00,
	  x[98] ? br: 8'h00,
	  x[99] ? br: 8'h00,
	  x[100] ? br: 8'h00,
	  x[101] ? br: 8'h00,
//
	  x[108] ? br: 8'h00,
	  x[109] ? br: 8'h00,
	  x[110] ? br: 8'h00,
	  x[111] ? br: 8'h00,
	  x[112] ? br: 8'h00,
	  x[113] ? br: 8'h00,
//
	  x[ 6] ? br: 8'h00,
	  x[ 7] ? br: 8'h00,
	  x[ 8] ? br: 8'h00,
	  x[ 9] ? br: 8'h00,
	  x[10] ? br: 8'h00,
	  x[11] ? br: 8'h00,
//
	  x[18] ? br: 8'h00,
	  x[19] ? br: 8'h00,
	  x[20] ? br: 8'h00,
	  x[21] ? br: 8'h00,
	  x[22] ? br: 8'h00,
	  x[23] ? br: 8'h00,
//
	  x[30] ? br: 8'h00,
	  x[31] ? br: 8'h00,
	  x[32] ? br: 8'h00,
	  x[33] ? br: 8'h00,
	  x[34] ? br: 8'h00,
	  x[35] ? br: 8'h00,
//
	  x[42] ? br: 8'h00,
	  x[43] ? br: 8'h00,
	  x[44] ? br: 8'h00,
	  x[45] ? br: 8'h00,
	  x[46] ? br: 8'h00,
	  x[47] ? br: 8'h00,
//
	  x[54] ? br: 8'h00,
	  x[55] ? br: 8'h00,
	  x[56] ? br: 8'h00,
	  x[57] ? br: 8'h00,
	  x[58] ? br: 8'h00,
	  x[59] ? br: 8'h00,
//
	  x[66] ? br: 8'h00,
	  x[67] ? br: 8'h00,
	  x[68] ? br: 8'h00,
	  x[69] ? br: 8'h00,
	  x[70] ? br: 8'h00,
	  x[71] ? br: 8'h00,
//
	  x[78] ? br: 8'h00,
	  x[79] ? br: 8'h00,
	  x[80] ? br: 8'h00,
	  x[81] ? br: 8'h00,
	  x[82] ? br: 8'h00,
	  x[83] ? br: 8'h00,
//
	  x[90] ? br: 8'h00,
	  x[91] ? br: 8'h00,
	  x[92] ? br: 8'h00,
	  x[93] ? br: 8'h00,
	  x[94] ? br: 8'h00,
	  x[95] ? br: 8'h00,
//
	  x[102] ? br: 8'h00,
	  x[103] ? br: 8'h00,
	  x[104] ? br: 8'h00,
	  x[105] ? br: 8'h00,
	  x[106] ? br: 8'h00,
	  x[107] ? br: 8'h00,
//
	  x[114] ? br: 8'h00,
	  x[115] ? br: 8'h00,
	  x[116] ? br: 8'h00,
	  x[117] ? br: 8'h00,
	  x[118] ? br: 8'h00,
	  x[119] ? br: 8'h00
};
  endfunction

  wire [LEDS*8-1:0] stream_r;
  wire [LEDS*8-1:0] stream_g;
  wire [LEDS*8-1:0] stream_b;

  if ( WIDTH == 6 && HEIGHT == 10) begin
     assign stream_r= bmp2stream_6x10(r, BRIGHTNESS_R);
     assign stream_g= bmp2stream_6x10(g, BRIGHTNESS_G);
     assign stream_b= bmp2stream_6x10(b, BRIGHTNESS_B);
  end
  else if ( WIDTH == 10 && HEIGHT == 6) begin
     assign stream_r= bmp2stream_10x6(r, BRIGHTNESS_R);
     assign stream_g= bmp2stream_10x6(g, BRIGHTNESS_G);
     assign stream_b= bmp2stream_10x6(b, BRIGHTNESS_B);
  end
  else if ( WIDTH == 12 && HEIGHT == 10) begin
     assign stream_r= bmp2stream_12x10(r, BRIGHTNESS_R);
     assign stream_g= bmp2stream_12x10(g, BRIGHTNESS_G);
     assign stream_b= bmp2stream_12x10(b, BRIGHTNESS_B);
  end
  else if ( WIDTH == 20 && HEIGHT == 6) begin
     assign stream_r= bmp2stream_20x6(r, BRIGHTNESS_R);
     assign stream_g= bmp2stream_20x6(g, BRIGHTNESS_G);
     assign stream_b= bmp2stream_20x6(b, BRIGHTNESS_B);
  end

  ws2812
    #(.CLK_FRQ(CLK_FRQ),
      .LEDS(LEDS)
      ) ws2812_inst
      (
       .clk(clk),
       .sout(sout),
       .r(stream_r),
       .g(stream_g),
       .b(stream_b)
       );
  
endmodule
