`default_nettype none
`include "clockworks.v"
`include "processor.v"

module SOC (
    input       CLK,
    input       RESET,
    input       TXD,
    input       RXD,
    input [4:0] LEDS
);

    wire clk;
    wire reset;

    Clockworks #(
        .SLOW(17)
    ) CW (
        .CLK(CLK),
        .RESET(RESET),
        .clk(clk),
        .reset(reset)
    );


    wire        mem_access;
    wire [31:0] mem_addr;
    wire [31:0] mem_rdata;
    wire [31:0] debug;  

    Memory RAM(
        .clk(clk),
        .mem_addr(mem_addr),
        .mem_rdata(mem_rdata),
        .mem_access(mem_access)
    );

    Processor CPU(
        .clk(clk),
        .reset(reset),
        .mem_addr(mem_addr),
        .mem_rdata(mem_rdata),
        .mem_access(mem_access),
        .debug(debug)
    );
    assign LEDS = debug[4:0];

endmodule