module retro_top (
    input           clk,
    input           rstb,
    output          txd,   //serial tx data
    input           rxd    //serial rx data
);

    localparam ADDRESS_WIDTH = 16;

    wire [ADDRESS_WIDTH-1:0]    address;
    wire [7:0]                  data_in;
    wire [7:0]                  data_out;    // tx data 8bit
    wire                        wren;
    wire                        uart_start;      // tx data enable
    wire                        uart_tx_busy;    // tx busy
    //reg                         hold;
    wire  [7:0]                 tx_fifo_data;    // tx fifo data 8bit
    wire                        tx_fifo_data_en; // tx fifo data enable
    wire                        tx_fifo_ren;     // tx fifo read enable
    wire                        tx_fifo_empty;   // tx fifo empty
    wire                        tx_fifo_full ;   // tx fifo full
    wire                        tx_fifo_n_full ; // tx fifo not full


    assign uart_start = wren && (address == 16'hFFFF);

    retro #(
        .ADDRESS_WIDTH (ADDRESS_WIDTH)
    ) cpu (
        .nres       (          rstb),
        .clk        (           clk),
        .hold       (tx_fifo_n_full),
        .address    (       address),
        .data_in    (       data_in),
        .data_out   (      data_out),
        .wren       (          wren)
    );

    rom #(
        .ADDRESS_WIDTH (8)
    ) prog (
        .addr   (address[7:0]),
        .data   (     data_in)
    );

    assign tx_fifo_ren = ((uart_tx_busy == 1'b0) && (uart_start == 1'b0)) ? 1'b1 : 1'b0;

    fifo #(
        .data_width ( 8),
        .adr_width  ( 4)    // 16 bytes
    ) tx_fifo (
        .CLK     (           clk),
        .RESET_N (          rstb),
        .WEN     (    uart_start),
        .WDAT    (      data_out),
        .REN     (   tx_fifo_ren),
        .RDAT    (  tx_fifo_data),
        .RDAT_EN (tx_fifo_data_en),
        .EMPTY   (  tx_fifo_empty),
        .FULL    (   tx_fifo_full),
        .N_FULL  ( tx_fifo_n_full)
    );

    rs232c #(
        .p_bit_end_count (12'd103)
    ) rs232c (
        .RESETB     (           rstb),
        .CLK        (            clk),
        .TXD        (            txd),
        .RXD        (            rxd),
        .TX_DATA    (   tx_fifo_data),
        .TX_DATA_EN (tx_fifo_data_en),
        .TX_BUSY    (   uart_tx_busy),
        .RX_DATA    (               ),
        .RX_DATA_EN (               ),
        .RX_BUSY    (               )
    );

/*
    always @(posedge clk)
        hold <= uart_tx_busy;
*/

endmodule
