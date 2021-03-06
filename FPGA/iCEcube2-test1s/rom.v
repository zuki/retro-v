module rom(addr,data);
parameter ADDRESS_WIDTH=8;
input [ADDRESS_WIDTH-1:0] addr;
output reg [7:0] data;
always @(addr) begin
 case (addr)
   0 : data = 8'hB7;
   1 : data = 8'h07;
   2 : data = 8'h01;
   3 : data = 8'h00;
   4 : data = 8'h93;
   5 : data = 8'h87;
   6 : data = 8'h87;
   7 : data = 8'h07;
   8 : data = 8'h13;
   9 : data = 8'h07;
  10 : data = 8'h80;
  11 : data = 8'h04;
  12 : data = 8'hB7;
  13 : data = 8'h26;
  14 : data = 8'h00;
  15 : data = 8'h40;
  16 : data = 8'h23;
  17 : data = 8'h80;
  18 : data = 8'hE6;
  19 : data = 8'h00;
  20 : data = 8'h93;
  21 : data = 8'h87;
  22 : data = 8'h17;
  23 : data = 8'h00;
  24 : data = 8'h03;
  25 : data = 8'hC7;
  26 : data = 8'h07;
  27 : data = 8'h00;
  28 : data = 8'hE3;
  29 : data = 8'h1A;
  30 : data = 8'h07;
  31 : data = 8'hFE;
  32 : data = 8'h67;
  33 : data = 8'h80;
  34 : data = 8'h00;
  35 : data = 8'h00;
  36 : data = 8'h48;
  37 : data = 8'h65;
  38 : data = 8'h6C;
  39 : data = 8'h6C;
  40 : data = 8'h6F;
  41 : data = 8'h20;
  42 : data = 8'h52;
  43 : data = 8'h49;
  44 : data = 8'h53;
  45 : data = 8'h43;
  46 : data = 8'h2D;
  47 : data = 8'h56;
  48 : data = 8'h21;
  49 : data = 8'h0A;
  50 : data = 8'h00;
  51 : data = 8'h00;
  52 : data = 8'h00;
  53 : data = 8'h00;
  54 : data = 8'h00;
  55 : data = 8'h00;
  56 : data = 8'h00;
  57 : data = 8'h00;
  58 : data = 8'h00;
  59 : data = 8'h00;
  60 : data = 8'h00;
  61 : data = 8'h00;
  62 : data = 8'h00;
  63 : data = 8'h00;
  64 : data = 8'h00;
  65 : data = 8'h00;
  66 : data = 8'h00;
  67 : data = 8'h00;
  68 : data = 8'h00;
  69 : data = 8'h00;
  70 : data = 8'h00;
  71 : data = 8'h00;
  72 : data = 8'h00;
  73 : data = 8'h00;
  74 : data = 8'h00;
  75 : data = 8'h00;
  76 : data = 8'h00;
  77 : data = 8'h00;
  78 : data = 8'h00;
  79 : data = 8'h00;
  80 : data = 8'h00;
  81 : data = 8'h00;
  82 : data = 8'h00;
  83 : data = 8'h00;
  84 : data = 8'hB7;
  85 : data = 8'h07;
  86 : data = 8'h01;
  87 : data = 8'h00;
  88 : data = 8'h93;
  89 : data = 8'h87;
  90 : data = 8'h87;
  91 : data = 8'h07;
  92 : data = 8'h13;
  93 : data = 8'h07;
  94 : data = 8'h80;
  95 : data = 8'h04;
  96 : data = 8'hB7;
  97 : data = 8'h26;
  98 : data = 8'h00;
  99 : data = 8'h40;
 100 : data = 8'h23;
 101 : data = 8'h80;
 102 : data = 8'hE6;
 103 : data = 8'h00;
 104 : data = 8'h93;
 105 : data = 8'h87;
 106 : data = 8'h17;
 107 : data = 8'h00;
 108 : data = 8'h03;
 109 : data = 8'hC7;
 110 : data = 8'h07;
 111 : data = 8'h00;
 112 : data = 8'hE3;
 113 : data = 8'h1A;
 114 : data = 8'h07;
 115 : data = 8'hFE;
 116 : data = 8'h67;
 117 : data = 8'h80;
 118 : data = 8'h00;
 119 : data = 8'h00;
 120 : data = 8'h48;
 121 : data = 8'h65;
 122 : data = 8'h6C;
 123 : data = 8'h6C;
 124 : data = 8'h6F;
 125 : data = 8'h20;
 126 : data = 8'h52;
 127 : data = 8'h49;
 128 : data = 8'h53;
 129 : data = 8'h43;
 130 : data = 8'h2D;
 131 : data = 8'h56;
 132 : data = 8'h21;
 133 : data = 8'h0A;
 134 : data = 8'h00;
 135 : data = 8'h00;
 default : data = 8'h01;
 endcase
end
endmodule
