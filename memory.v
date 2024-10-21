module Memory (
    input             clk,
    input      [31:0] mem_addr,     // Address to be read
    output reg [31:0] mem_rdata,    // Data read from memory
    input             mem_access    // Goes high when CPU wants to read
);

    reg [31:0] MEM [0:255];
    `include "riscv_assembly.v"

    // `include "programs/instructions_test.v"
    // `include "programs/inf_loop.v"
    // `include "programs/for_loop.v"
    `include "programs/kitt.v"

    always @(posedge clk) begin
        if(mem_access) begin
            mem_rdata <= MEM[mem_addr[31:2]];
        end
    end
endmodule