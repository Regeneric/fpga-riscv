module test_bench();
    reg CLK;        // `reg` types are primarily used in procedural blocks
    wire RESET;     // `wire` is used to represent connections and must be driven by a continuous source
    wire TXD;
    reg RXD;
    wire [4:0] LEDS;

    // `uut` - unit under testing
    // It's a simple port mapping: connects `test_bench` signals to `SOC` signals
    SOC uut(
        .CLK(CLK),
        .RESET(RESET),
        .TXD(TXD),
        .RXD(RXD),
        .LEDS(LEDS)
    );

    reg [4:0] prev_LEDS = 0;
    initial begin
        CLK = 0;
        forever begin
            #1 CLK = ~CLK;  // #1 CLK = ~CLK; means that CLK will change every 1 time unit of simulation
            if(LEDS != prev_LEDS) begin
                $display("\nLEDS = %b", LEDS);
            end
            prev_LEDS <= LEDS;
        end
    end

endmodule