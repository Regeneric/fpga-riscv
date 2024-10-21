`default_nettype none
`include "clockworks.v"

module SOC (
    input CLK,
    input RESET,
    input TXD,
    input RXD,
    input [4:0] LEDS
);

wire clk;
wire reset;

reg [4:0] leds;
assign LEDS = leds;

Clockworks #(
    .SLOW(17)
) CW (
    .CLK(CLK),
    .RESET(RESET),
    .clk(clk),
    .reset(reset)
);

reg [31:0] MEM [0:255];     // 1 KiB of memory
reg [31:0] PC = 0;          // Program Counter
reg [31:0] instr;           // Current instruction

`include "riscv_assembly.v"

// `include "programs/instructions_test.v"
// `include "programs/inf_loop.v"
// `include "programs/for_loop.v"
`include "programs/kitt.v"



// R-Type  ;  Register Type         ;  register-to-register operations  ;  rd, rs1 and rs2  ;  ADD, SUB    etc.
// I-Type  ;  Immediate Type        ;  register and value               ;  rs1, rs2, imm    ;  LW, ADDI    etc.
// S-Type  ;  Store Type            ;  register-to-memory               ;  mem, rs1, rs2    ;  SW, SB      etc.
// B-Type  ;  Branch Type           ;  conditional branches             ;  pc, rs1, rs2     ;  BEQ, BNE    etc.
// U-Type  ;  Upper Immediate Type  ;  20 bit value to upper bits       ;  rd, imm          ;  LUI, AUIPC  etc.
// J-Type  ;  Jump Type             ;  unconditional jump               ;  pc, imm          ;  JAL, JALR   etc.

/*
 Instruction decoder gets the following information from the instruction word:
  - Signals isXXX that recognizes among the 11 possible RISC-V instructions
  - Source and destination registers rs1, rs2 and rd
  - Function codes funct3 and funct7
  - The five formats for immediate values (with sign expansion for Iimm, Simm, Bimm and Jimm).
*/

// 10 RISC-V instructions
wire isALUreg = (instr[6:0] == 7'b0110011);     // R-Type ; rd <- rs1 OP rs2
wire isALUimm = (instr[6:0] == 7'b0010011);     // I-Type ; rd <- rs1 OP Iimm
wire isBranch = (instr[6:0] == 7'b1100011);     // B-Type ; if(rs1 OP rs2) PC <- PC+Bimm
wire isJALR   = (instr[6:0] == 7'b1100111);     // J-Type ; rd <- PC+4; PC <- rs1+Iimm
wire isJAL    = (instr[6:0] == 7'b1101111);     // J-Type ; rd <- PC+4; PC <- PC+Jimm
wire isAUIPC  = (instr[6:0] == 7'b0010111);     // U-Type ; rd <- PC+Uimm
wire isLUI    = (instr[6:0] == 7'b0110111);     // U-Type ; rd <- Uimm
wire isLoad   = (instr[6:0] == 7'b0000011);     // I-Type ; rd <- mem[rs1+Iimm]
wire isStore  = (instr[6:0] == 7'b0100011);     // S-Type ; mem[rs1+Simm] <- rs2
wire isSYSTEM = (instr[6:0] == 7'b1110011);     // special

// Source and destination registers
wire [4:0] rs1Id = instr[19:15];
wire [4:0] rs2Id = instr[24:20];
wire [4:0] rdId  = instr[11:7];

// Function codes
wire [2:0] funct3 = instr[14:12];
wire [6:0] funct7 = instr[31:25];

// 5 immediate formats
/*
The syntax {instr[A], instr[B:C], {D{1'b0}}} combines two parts:
    - The replicated sign bits (bit A from instr)
    - The actual immediate value (bits B to C and D times 1'b0)

    instr[B:C] - upper X bits
    {D{1'b0}}  - lower Y bits
*/
wire [31:0] Uimm = {instr[31], instr[30:12],{12{1'b0}}};

/*
The syntax {{A{instr[B]}}, instr[C:D]} combines two parts:
    - The replicated sign bits (A bits from instr[B])
    - The actual immediate value (32-A bits from instr[C:D])
*/
wire [31:0] Iimm = {{21{instr[31]}}, instr[30:20]};

/*
The syntax {{A{instr[B]}}, instr[C:D],instr[E:F]} combines two parts:
    - The replicated sign bits (A bits from instr[B])
    - The actual immediate value (32-A bits from instr[C:D],instr[E:F])
*/
wire [31:0] Simm = {{21{instr[31]}}, instr[30:25],instr[11:7]};

wire [31:0] Bimm = {{20{instr[31]}}, instr[7],instr[30:25],instr[11:8],1'b0};
wire [31:0] Jimm = {{12{instr[31]}}, instr[19:12],instr[20],instr[30:21],1'b0};


/* 
  R-Type:  rd <- rs1 OP rs2  ;  isALUreg
  I-Type:  rd <- rs1 OP imm  ;  isALUimm  
  ALU takes two inputs:  `aluIn1` and `aluIn2`
  ALU then computes `aluIn1 OP aluIn2` and stores it in `aluOut`

  funct3 (OP):
  3'b000  ;  ADD or SUB
  3'b001  ;  left shift
  3'b010  ;  signed comparison (<)
  3'b011  ;  unsigned comparison (<)
  3'b100  ;  XOR
  3'b101  ;  logical or arithemtical right shift
  3'b110  ;  OR
  3'b111  ;  AND
*/
wire [4:0]  shiftAmmount = isALUreg ? rs2[4:0] : instr[24:20];  // isALUreg ? R-Type : I-Type   ;  instr[24:20] is the same as rs2Id
wire [31:0] aluIn1 = rs1;                                       // R-Type
wire [31:0] aluIn2 = isALUreg ? rs2 : Iimm;                     // I-Type
reg  [31:0] aluOut;

always @(*) begin
    case(funct3)
        /*
        For ADD/SUB, if its an ALUreg operation (R-Type), then one makes the difference between ADD and SUB
        by testing funct7[5] (it's 0 for ADD and 1 for SUB). 
        If it is an ALUimm operation (I-Type), then it can be only ADD. 
        In this context, one just needs to test instr[5] to distinguish between ALUreg (if it is 1) and ALUimm (if it is 0).

        0 & 0 = 0  ;  ALUimm ADD
        0 & 1 = 0  ;  ALUreg ADD
        1 & 0 = 0  ;  ALUimm ADD
        1 & 1 = 1  ;  ALUreg SUB 
        */
        3'b000: aluOut = (funct7[5] & instr[5]) ? (aluIn1-aluIn2) : (aluIn1+aluIn2);    
        
        3'b001: aluOut = aluIn1 << shiftAmmount;
        3'b010: aluOut = ($signed(aluIn1) < $signed(aluIn2));
        3'b011: aluOut = (aluIn1 < aluIn2);
        3'b100: aluOut = (aluIn1 ^ aluIn2);

        /*
        For logical or arithmetic right shift, one makes the difference also by testing funct7[5] 
        1 for arithmetic shift >>> (with sign expansion); 0 for logical shift >>.
        */
        3'b101: aluOut = (funct7[5] ? ($signed(aluIn1) >>> shiftAmmount) : (aluIn1 >> shiftAmmount));
        
        3'b110: aluOut = (aluIn1 | aluIn2);
        3'b111: aluOut = (aluIn1 & aluIn2);
    endcase
end


/*
  There are 6 different branch instructions:

  funct3 (OP):
  3'b000  ;  BEQ   ;  if(rs1 == rs2) PC <- PC+Bimm
  3'b001  ;  BNE   ;  if(rs1 != rs2) PC <- PC+Bimm
  3'b100  ;  BLT   ;  if(signed(rs1) < signed(rs2)) PC <- PC+Bimm 
  3'b101  ;  BGT   ;  if(signed(rs1) >= signed(rs)) PC <- PC+Bimm
  3'b110  ;  BLTU  ;  if(unsigned(rs1) < unsigned(rs2)) PC <- PC+Bimm
  3'b111  ;  BGEU  ;  if(unsigned(rs1) >= unsigned(rs2)) PC <- PC+Bimm
*/
reg takeBranch;
always @(*) begin
    case(funct3)
        3'b000: takeBranch = (rs1 == rs2);
        3'b001: takeBranch = (rs1 != rs2);
        3'b100: takeBranch = ($signed(rs1) < $signed(rs2));
        3'b101: takeBranch = ($signed(rs1) >= $signed(rs2));
        3'b110: takeBranch = (rs1 < rs2);
        3'b111: takeBranch = (rs1 >= rs2);
        default: takeBranch = 1'b0;
    endcase
end


/*
For each instruction, we need to do the following four things:
  - Fetch the instruction:  instr <= MEM[PC]
  - Fetch the values of `rs1` and `rs2`:  rs <= RegisterBank[rs1Id]; rs2 <= RegisterBank[rs2Id];
  - Compute `rs1 OP rs2`, where `OP` depends on `funct3` and `funct7`
  - Store the result in `rd`:  RegisterBank[rdId] <= writeBackData  
*/
reg  [31:0] RegisterBank [0:31];
reg  [31:0] rs1;
reg  [31:0] rs2;
wire [31:0] writeBackData;
wire        writeBackEn;

`ifdef BENCH   
    integer i;
    initial begin
        for(i=0; i<32; ++i) begin
	        RegisterBank[i] = 0;
        end
    end
`endif 


// The first three operations are implemented by a state machine
localparam FETCH_INSTR = 0;
localparam FETCH_REGS  = 1;
localparam EXECUTE     = 2;

reg [1:0] state = FETCH_INSTR;
always @(posedge clk) begin
    case(state)
        FETCH_INSTR: begin
            instr <= MEM[PC[31:2]];
            state <= FETCH_REGS;
        end

        FETCH_REGS: begin
            rs1 <= RegisterBank[rs1Id];
            rs2 <= RegisterBank[rs2Id];
            state <= EXECUTE;
        end

        EXECUTE: begin
            if(!isSYSTEM) begin
                PC <= nextPC;
            end
            state <= FETCH_INSTR;

            `ifdef BENCH
                if(isSYSTEM) $finish();
            `endif
        end
    endcase
end 

// The fourth one (register write-back)
assign writeBackData = (isJAL || isJALR) ? (PC+4) : aluOut;
assign writeBackEn   = (state == EXECUTE && 
                           (isALUreg || isALUimm ||
                            isJAL    || isJALR)
                          );
wire [31:0] nextPC = (isBranch && takeBranch) ? PC+Bimm  :
                      isJAL                   ? PC+Jimm  :
                      isJALR                  ? rs1+Iimm :
                      PC+4;

always @(posedge clk) begin
    // Writing to register 0 (x0) has no effect, hence the check
    if(writeBackEn && rdId != 0) begin
        RegisterBank[rdId] <= writeBackData;

        // DEBUG
        if(rdId == 1) begin
            leds <= writeBackData;
        end
        `ifdef BENCH
            $display("x%0d <= %b", rdId, writeBackData);
        `endif
    end
end


`ifdef BENCH
    always @(posedge clk) begin
        if(state == FETCH_REGS) begin
            case(1'b1)
                isALUreg: $display(
                    "ALUreg rd=%d rs1=%d, rs2=%d funct3=%b",
                    rdId, rs1Id, rs2Id, funct3
                );

                isALUimm: $display(
                    "ALUImm rd=%d rs1=%d imm=%0d funct3=%b",
                    rdId, rs1Id, Iimm, funct3
                );

                isBranch: $display("BRANCH");
                isJAL:    $display("JAL");
                isJALR:   $display("JALR");
                isAUIPC:  $display("AUPIC");
                isLUI:    $display("LUI");
                isLoad:   $display("LOAD");
                isStore:  $display("STORE");
                isSYSTEM: $display("SYSTEM");
            endcase
            if(isSYSTEM) $finish();
        end
    end
`endif


endmodule