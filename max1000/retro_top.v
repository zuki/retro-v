module retro_top (
    input           clk,
    input           rstb,
    output          txd,   //serial tx data
    input           rxd    //serial rx data
);

    localparam ADDRESS_WIDTH = 16;

    wire [ADDRESS_WIDTH-1:0]    address;
    wire [7:0]                  data;
    wire [7:0]                  uart_tx_data;    // tx data 8bit
    wire                        wren;
    wire                        uart_start;      // tx data enable
    wire                        uart_tx_busy;    // tx busy
    reg                         hold;

    assign uart_start = wren && (address == 16'hFFFF);

    retro #(
        .ADDRESS_WIDTH (ADDRESS_WIDTH)
    ) cpu (
        .nres       (        rstb),
        .clk        (         clk),
        .hold       (        hold),
        .address    (     address),
        .data_in    (        data),
        .data_out   (uart_tx_data),
        .wren       (        wren)
    );

    rom #(
        .ADDRESS_WIDTH (8)
    ) prog (
        .addr   (address[7:0]),
        .data   (        data)
    );

    rs232c #(
        .p_bit_end_count (12'd103)
    ) rs232c (
        .RESETB     (        rstb),
        .CLK        (         clk),
        .TXD        (         txd),
        .RXD        (         rxd),
        .TX_DATA    (uart_tx_data),
        .TX_DATA_EN (  uart_start),
        .TX_BUSY    (uart_tx_busy),
        .RX_DATA    (            ),
        .RX_DATA_EN (            ),
        .RX_BUSY    (            )
    );

    always @(posedge clk)
        hold <= uart_tx_busy;

endmodule
