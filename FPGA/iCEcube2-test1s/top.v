module top(ext_osc,uart_tx,REDn,BLUn,GRNn);
input wire ext_osc; // 12 MHz
output wire uart_tx;

output  wire        REDn;       // Red
output  wire        BLUn;       // Blue
output  wire        GRNn;       // Green

reg [27:0]  frequency_counter_i;

wire [15:0] address;
wire [7:0] data,dataout;
wire clk,wren,hold,res;

always @(posedge ext_osc) begin
    frequency_counter_i <= frequency_counter_i + 1'b1;
end

assign clk = ext_osc;//frequency_counter_i[22];

retro cpu (
.nres(1'b1),
.clk(clk),
.hold(hold),
.address(address),
.data_in(data),
.data_out(dataout),
.wren(wren)
);

//assign addrout = address;

assign res = (address==16'h0)?1'b1:1'b0;

// RS232 sender by Frank Buss:
// entity rs232_sender is
//    generic (
//	system_speed, -- clk_i speed, in hz
//	baudrate : integer); -- baudrate, in bps
//    port (
//	clk_i : in std_logic;
//	dat_i : in unsigned(7 downto 0);
//	rst_i : in std_logic;
//	stb_i : in std_logic;
//	tx    : out std_logic;
//	busy  : out std_logic);
//end entity rs232_sender;

rs232_sender #(12000000,115200) TX (
.clk_i (ext_osc),
.dat_i (dataout),
.rst_i (res),
.stb_i (wren),
.tx (uart_tx),
.busy (hold)
);

//rom #(10) prog (clk,address[9:0],data);

rom prog (address[7:0],data);

SB_RGBA_DRV RGB_DRIVER (
      .RGBLEDEN (1'b1),
      .RGB0PWM  (hold),//GREEN
      .RGB1PWM  (clk),//BLUE
      .RGB2PWM  (wren),//RED
      .CURREN   (1'b1), 
      .RGB0     (GRNn),
      .RGB1     (BLUn),
      .RGB2     (REDn)
);
defparam RGB_DRIVER.RGB0_CURRENT = "0b000001";
defparam RGB_DRIVER.RGB1_CURRENT = "0b000001";
defparam RGB_DRIVER.RGB2_CURRENT = "0b000001";

endmodule
