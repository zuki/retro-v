module top(dataout,addrout,wren,REDn,BLUn,GRNn);

output [7:0] dataout;
output [15:0] addrout;
output wire wren;
output  wire        REDn,       // Red
output  wire        BLUn,       // Blue
output  wire        GRNn,       // Green

reg [27:0]  frequency_counter_i;

wire [15:0] address;
wire [7:0] data;
wire clk;

//----------------------------------------------------------------------------
//                                                                          --
//                       Internal Oscillator                                --
//                                                                          --
//----------------------------------------------------------------------------
    SB_HFOSC  u_SB_HFOSC(.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(int_osc));


//----------------------------------------------------------------------------
//                                                                          --
//                       Counter                                            --
//                                                                          --
//----------------------------------------------------------------------------
    always @(posedge int_osc) begin
	    frequency_counter_i <= frequency_counter_i + 1'b1;
    end

assign clk = frequency_counter_i[23];

retro cpu (
.nres(1'b1),
.clk(clk),
.hold(1'b0),
.address(address),
.data_in(data),
.data_out(dataout),
.wren(wren)
);

assign addrout = address;

// rom #(10) prog (address[9:0],data);

rom prog (address[7:0],data);

//----------------------------------------------------------------------------
//                                                                          --
//                       Instantiate RGB primitive                          --
//                                                                          --
//----------------------------------------------------------------------------
    SB_RGBA_DRV RGB_DRIVER ( 
      .RGBLEDEN (1'b1),
      .RGB0PWM  (1'b0),//(frequency_counter_i[25]),//(frequency_counter_i[25]&frequency_counter_i[24]),//GREEN
      .RGB1PWM  (clk),//(frequency_counter_i[26]),//(frequency_counter_i[25]&~frequency_counter_i[24]),//BLUE
      .RGB2PWM  (wren),//(frequency_counter_i[27]),//(~frequency_counter_i[25]&frequency_counter_i[24]),//RED
      .CURREN   (1'b1), 
      .RGB0     (GRNn), //Actual Hardware connection - black,green,blue,cyan,red,yellow,magenta,white
      .RGB1     (BLUn),
      .RGB2     (REDn)
    );
    defparam RGB_DRIVER.RGB0_CURRENT = "0b000001";
    defparam RGB_DRIVER.RGB1_CURRENT = "0b000001";
    defparam RGB_DRIVER.RGB2_CURRENT = "0b000001";

endmodule
