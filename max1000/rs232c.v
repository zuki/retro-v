// シリアル通信サンプル回路
// ※回路を試す場合は、自己責任でお願いします。
// http://www.hmwr-lsi.co.jp
// fpga@hmwr-lsi.co.jp
//
//  シリアル通信の設定：115,200 bps, 8 bit, パリティなし
//
// History
// -.-- 2010/8/27
// -.-- 2015/4/16 文字コード変更 JIS->SJIS
// -.-- 2020/1/9  文字コード変更 SJIS->UTF-8
//******************************************************************************
module rs232c #(
    parameter p_bit_end_count = 12'd103    // 115.2Kbps clk=12.0MHz
    //parameter p_bit_end_count = 12'd346    // 115.2Kbps clk=40.0MHz
) (
    input RESETB,               // power on reset
    input CLK,                  // main clk
    output reg TXD,             // serial tx data
    input RXD,                  // serial rx data
    input [7:0] TX_DATA,        // tx data 8bit
    input TX_DATA_EN,           // tx commond
    output TX_BUSY,             // tx busy
    output reg [7:0] RX_DATA,   // rx data 8bit
    output reg RX_DATA_EN,      // rx data enable
    output reg RX_BUSY          // rx busy
);

    reg TX_BUSY_REG;

    reg  [11:0]   tx_time_cnt;  //1bit clks counter
    reg  [11:0]   rx_time_cnt;  //1bit clks counter
    //
    reg           rxd_d1;
    reg           rxd_d2;
    reg           rxd_d3;
    reg           rxd_chg;
    reg [3:0]     rx_data_cnt;
    reg [16:0]    tx_data_cnt;
    reg [9:0]     txd_tmp;
    reg [7:0]     rx_data_tmp;

//
//  送信処理
//
//  1bit長カウント
always @(posedge CLK or negedge RESETB) begin
    if (RESETB == 1'b0)
        tx_time_cnt <= 12'd0;
    else
        if (TX_DATA_EN == 1'b1)
            tx_time_cnt <= 12'd0;
        else if (tx_time_cnt == p_bit_end_count )
            tx_time_cnt <= 12'd0;
        else
            tx_time_cnt <=  tx_time_cnt + 12'd1;
end
//
//
//  送信bit数カウント
always @(posedge CLK or negedge RESETB) begin
    if (RESETB == 1'b0)
        tx_data_cnt <= 17'd0 ;
    else
        if (tx_data_cnt == 17'd0)
            if (TX_DATA_EN == 1'b1)
                tx_data_cnt <= 17'd1 ;
            else
                tx_data_cnt <= 17'd0 ;
        else if (tx_time_cnt == p_bit_end_count )
            if (tx_data_cnt == 17'd10 )
                tx_data_cnt <= 17'd0 ;
            else
                tx_data_cnt <= tx_data_cnt + 17'd1;
        else
            tx_data_cnt <= tx_data_cnt ;
end
//
// 送信データセット
//
always @(posedge CLK or negedge RESETB) begin
    if (RESETB == 1'b0)
        txd_tmp <= 10'h3ff;
    else
        if (TX_DATA_EN == 1'b1)
            txd_tmp <= {1'b1, TX_DATA, 1'b0};
        else if (tx_time_cnt == p_bit_end_count)
            txd_tmp <= {1'b1, txd_tmp[9:1]};
        else
            txd_tmp <= txd_tmp ;
end

//
// データ送信
//
always @(posedge CLK or negedge RESETB) begin
    if (RESETB==1'b0)
        TXD <= 1'b1 ;
    else
        TXD <= txd_tmp[0];
end

//
// 送信ビジー判定
//
always @(posedge CLK or negedge RESETB) begin
    if (RESETB == 1'b0)
        TX_BUSY_REG <= 1'b0 ;
    else
        if (((tx_data_cnt == 4'd0) && (TX_DATA_EN==1'b1)) || (tx_data_cnt != 4'd0))
            TX_BUSY_REG <= 1'b1 ;
        else
            TX_BUSY_REG <= 1'b0 ;
end

assign TX_BUSY = ((TX_DATA_EN == 1'b1) || (TX_BUSY_REG == 1'b1)) ? 1'b1 : 1'b0;

//
//受信処理
//

//　1bit長カウント
always @(posedge CLK or negedge RESETB) begin
    if (RESETB  ==  1'b0)
        rx_time_cnt <= 12'd0;
    else
        if ((rx_data_cnt == 4'd0) && (rxd_chg==1'b1))
            rx_time_cnt <= 12'd0;
        else if (rx_time_cnt == p_bit_end_count )
            rx_time_cnt <= 12'd0;
        else
            rx_time_cnt <=  rx_time_cnt + 12'd1;
end

//
//  受信bit数カウント
always @(posedge CLK or negedge RESETB) begin
    if (RESETB == 1'b0)
        rx_data_cnt <= 4'd0 ;
    else
        if (rx_data_cnt == 4'd0)
            if (rxd_chg == 1'b1)
                rx_data_cnt <= 4'd1 ;
            else
                rx_data_cnt <= 4'd0 ;
        else if (rx_time_cnt == p_bit_end_count )
            if (rx_data_cnt == 4'd9)
                rx_data_cnt <= 4'd0 ;
            else
                rx_data_cnt <= rx_data_cnt + 4'd1;
        else
            rx_data_cnt <= rx_data_cnt ;
end

//受信変化検出
always @(posedge CLK or negedge RESETB) begin
    if (RESETB==1'b0)
        begin
            rxd_d1 <= 1'b1 ;
            rxd_d2 <= 1'b1 ;
            rxd_d3 <= 1'b1 ;
            rxd_chg <= 1'b0 ;
        end
    else
        begin
            rxd_d1 <= RXD ;
            rxd_d2 <= rxd_d1 ;
            rxd_d3 <= rxd_d2 ;
            if ((rxd_d2 == 1'b0) && (rxd_d3 == 1'b1))
                rxd_chg <= 1'b1 ;
            else
                rxd_chg <= 1'b0;
        end
end

//　受信データ保持
always @(posedge CLK or negedge RESETB) begin
    if (RESETB == 1'b0)
        rx_data_tmp <= 8'd0 ;
    else
        if (rx_time_cnt == {1'b0, p_bit_end_count[11:1]})
            rx_data_tmp <= {rxd_d2, rx_data_tmp[7:1]};
        else
            rx_data_tmp <= rx_data_tmp;
end

//  受信データ転送
always @(posedge CLK or negedge RESETB) begin
    if (RESETB == 1'b0)
        begin
            RX_DATA <= 8'd0 ;
            RX_DATA_EN <= 1'b0;
        end
    else
        if ((rx_data_cnt == 17'd9) && (rx_time_cnt == {1'b0, p_bit_end_count [11:1]} + 12'd1))
            begin
                RX_DATA <= rx_data_tmp ;
                RX_DATA_EN <= 1'b1 ;
            end
        else
            begin
                RX_DATA <= RX_DATA ;
                RX_DATA_EN <= 1'b0 ;
            end
end

//
// 受信ビジー判定
//
always @(posedge CLK or negedge RESETB) begin
    if (RESETB == 1'b0)
        RX_BUSY <= 1'b0 ;
    else
        if (rx_data_cnt != 4'd0)
            RX_BUSY <= 1'b1 ;
        else
            RX_BUSY <= 1'b0 ;
end

endmodule
