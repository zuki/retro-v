//******************************************************************************
// File Name            : ram.v
//------------------------------------------------------------------------------
// Function             : ram
//
//------------------------------------------------------------------------------
// Designer             : yokomizo
//------------------------------------------------------------------------------
// History
// -.-- 2010/5/31
//******************************************************************************
module ram #(
    parameter data_width = 8,
    parameter adr_width = 8,
    parameter mem_size = (1 << adr_width) - 1
) (
    input                       CLK,
    input                       WEN,
    input [adr_width-1:0]       WADR,
    input [data_width-1:0]      WDAT,
    input [adr_width-1:0]       RADR,
    output reg [data_width-1:0] RDAT
);

    reg [data_width-1:0] mem [0:mem_size];

    always @ (posedge CLK) begin
        if (WEN==1'b1)
            mem[WADR] <= WDAT;
    end

    always @ (posedge CLK) begin
        RDAT <= mem[RADR];
    end

endmodule
