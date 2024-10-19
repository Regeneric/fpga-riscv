module Clockworks (
    input CLK,
    input RESET,
    inout    clk,
    input reset
);

parameter SLOW = 1; // `parameter` can be modified at compile time
reg [SLOW:0] slow_CLK = 0;

always @(posedge CLK) begin
    slow_CLK <= slow_CLK + 1;
end
assign clk = slow_CLK[SLOW];  // asign the oldest bit to the `clk` so it'll take longer for the clock cycle to complete and drive the simulation

endmodule