module retro_tb;

    reg             clk;
    reg             rstb;

    localparam ADDRESS_WIDTH = 16;

    wire [ADDRESS_WIDTH-1:0]    address;
    reg  [7:0]                  data_in;
    wire [7:0]                  data;
    wire [7:0]                  data_out;
    wire                        wren;
    reg                         hold;

    retro #(
        .ADDRESS_WIDTH (ADDRESS_WIDTH)
    ) cpu (
        .nres       (        rstb),
        .clk        (         clk),
        .hold       (        hold),
        .address    (     address),
        .data_in    (     data_in),
        .data_out   (    data_out),
        .wren       (        wren)
    );

    rom #(
        .ADDRESS_WIDTH (8)
    ) prog (
        .addr   (address[7:0]),
        .data   (        data)
    );

initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, cpu);

    rstb  = 1'b0;
    hold  = 1'b0;
    // Wait 100 ns for global reset to finish
    #30;
    rstb = 1;
end

initial begin
        // Initialize Inputs
        clk = 0;
        repeat(400) begin
        #41.5;
        clk = 1;
        #41.5;
        clk = 0;
        end
        $finish;
end

always @(*)
    data_in <= data;


endmodule
