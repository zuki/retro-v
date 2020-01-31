//******************************************************************************
// File Name            : fifo.v
//------------------------------------------------------------------------------
// Function             : fifo
//
//------------------------------------------------------------------------------
// Designer             : yokomizo
//------------------------------------------------------------------------------
// History
// -.-- 2010/5/31
//******************************************************************************
module fifo #(
    parameter data_width = 8,
    parameter adr_width = 8,
    parameter mem_size = (1 << adr_width) - 1
) (
    input CLK,
    input RESET_N,
    input WEN,
    input [data_width-1:0] WDAT,
    input REN,
    output [data_width-1:0] RDAT,
    output reg RDAT_EN,
    output reg FULL,
    output reg N_FULL,
    output reg EMPTY
);

    reg     [adr_width-1:0]     WADR;
    wire    [adr_width-1:0]     NEXT_WADR;
    reg     [adr_width-1:0]     RADR;
    wire    [adr_width-1:0]     NEXT_RADR;
    wire    [adr_width-1:0]     BF_RADR;
    wire                        RAM_WEN;
    wire                        RAM_REN;
    //reg                         BF_RAM_REN;

    assign  RAM_WEN = ((WEN==1'b1) && (FULL == 1'b0)) ? 1'b1 : 1'b0;
    assign  RAM_REN = ((REN==1'b1) && (EMPTY == 1'b0)) ? 1'b1 : 1'b0;
    assign  NEXT_WADR = WADR + 1;
    assign  NEXT_RADR = RADR + 1;
    assign  BF_RADR = RADR - 1;
/*
    always @ (posedge CLK or negedge RESET_N)
        if (RESET_N == 1'b0)
            BF_RAM_REN <= 1'b0;
        else
            BF_RAM_REN <= RAM_REN;
*/
    // WADRの設定
    always @ (posedge CLK or negedge RESET_N) begin
        if (RESET_N == 1'b0)
            WADR <= 0;
        else
            if (RAM_WEN == 1'b1)
                WADR <= WADR + 1;
            else
                WADR <= WADR;
    end

    // RADRの設定
    always @ (posedge CLK or negedge RESET_N) begin
        if (RESET_N == 1'b0)
            RADR <= 0;
        else
            //if ((BF_RAM_REN == 1'b1) && (RAM_REN == 1'b0))
            if (RAM_REN == 1'b1)
                RADR <= RADR + 1;
            else
                RADR <= RADR;
    end

    // EMPTY設定
    always @ ( posedge CLK or negedge RESET_N) begin
        if (RESET_N == 1'b0)
            EMPTY <= 1'b1;
        else
            if (EMPTY == 1'b1)
                if (WEN == 1'b1)
                    EMPTY <= 1'b0;
                else
                    EMPTY <= 1'b1;
            else
                if ((WADR == NEXT_RADR) && (REN == 1'b1) && (WEN == 1'b0))
                    EMPTY <= 1'b1;
                else
                    EMPTY <= 1'b0;
      end

    // FULLの設定
    always @ (posedge CLK or negedge RESET_N) begin
        if (RESET_N == 1'b0)
            FULL <= 1'b0;
        else
            if (FULL == 1'b0)
                if ((RADR == NEXT_WADR) && (WEN == 1'b1) && (REN==1'b0))
                    FULL <= 1'b1;
                else
                    FULL <= 1'b0;
            else
                if (REN == 1'b1)
                    FULL <= 1'b0;
                else
                    FULL <= 1'b1;
     end

    // N_FULLの設定
    always @ (posedge CLK or negedge RESET_N) begin
        if (RESET_N == 1'b0)
            N_FULL <= 1'b0;
        else
            if (N_FULL == 1'b0)
                if ((BF_RADR == NEXT_WADR) && (WEN==1'b1) && (REN==1'b0))
                    N_FULL <= 1'b1;
                else
                    N_FULL <= 1'b0;
            else
                if ((WEN == 1'b0) && (REN == 1'b1))
                    N_FULL <= 1'b0;
                else
                    N_FULL <= 1'b1;
    end

    //
    always @ (posedge CLK or negedge RESET_N) begin
        if (RESET_N == 1'b0)
            RDAT_EN <= 1'b0;
        else
            RDAT_EN <= RAM_REN;
    end

    ram #(
        .data_width (data_width),
        .adr_width  ( adr_width)
    ) ram (
        .CLK    (CLK),
        .WEN    (RAM_WEN),
        .WADR   (WADR),
        .WDAT   (WDAT),
        .RADR   (RADR),
        .RDAT   (RDAT)
    );

endmodule
