`include "memory.v"

module Processor (
    input             clk, 
    input             reset, 
    output     [31:0] mem_addr,
    input      [31:0] mem_rdata,
    output     [31:0] mem_access,
    output reg [31:0] debug
);

    reg [31:0] PC = 0;  // Program Counter
    reg [31:0] instr;   // Current instruction

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

    // 5 immediate formats
    /*
    The U-Type syntax {instr[A], instr[B:C], {D{1'b0}}} combines two parts:
        - The replicated sign bits (bit A from instr)
        - The actual immediate value (bits B to C and D times 1'b0)

        instr[B:C] - upper X bits
        {D{1'b0}}  - lower Y bits
    */
    wire [31:0] Uimm = {instr[31], instr[30:12],{12{1'b0}}};

    /*
    The I-Type syntax {{A{instr[B]}}, instr[C:D]} combines two parts:
        - The replicated sign bits (A bits from instr[B])
        - The actual immediate value (32-A bits from instr[C:D])
    */
    wire [31:0] Iimm = {{21{instr[31]}}, instr[30:20]};

    /*
    The S-Type syntax {{A{instr[B]}}, instr[C:D],instr[E:F]} combines two parts:
        - The replicated sign bits (A bits from instr[B])
        - The actual immediate value (32-A bits from instr[C:D],instr[E:F])
    */
    wire [31:0] Simm = {{21{instr[31]}}, instr[30:25],instr[11:7]};

    wire [31:0] Bimm = {{20{instr[31]}}, instr[7],instr[30:25],instr[11:8],1'b0};
    wire [31:0] Jimm = {{12{instr[31]}}, instr[19:12],instr[20],instr[30:21],1'b0};

    // Source and destination registers
    wire [4:0] rs1Id = instr[19:15];
    wire [4:0] rs2Id = instr[24:20];
    wire [4:0] rdId  = instr[11:7];

    // Function codes
    wire [2:0] funct3 = instr[14:12];
    wire [6:0] funct7 = instr[31:25];

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
    wire [31:0] aluIn2 = isALUreg | isBranch ? rs2 : Iimm;          // I-Type
    reg  [31:0] aluOut;
    
    // The adder is used by both arithmetic instructions and JALR.
    wire [31:0] aluPlus = aluIn1 + aluIn2;

    // Use a single 33 bits subtract to do subtraction and all comparisons
    // (trick borrowed from swapforth/J1)
    wire [32:0] aluMinus = {1'b1, ~aluIn2} + {1'b0, aluIn1} + 33'b1;    // Yes, [32:0]
    
    wire LT  = (aluIn1[31]^aluIn2[31]) ? aluIn1[31] : aluIn2[32];
    wire LTU = aluMinus[32];
    wire EQ  = (aluMinus[31:0] == 0);

    // Flip a 32 bit word. Used by the shifter (a single shifter for left and right shifts)
    function [31:0] flip32;
        input [31:0] x;
        flip32 = {x[ 0], x[ 1], x[ 2], x[ 3], x[ 4], x[ 5], x[ 6], x[ 7], 
		          x[ 8], x[ 9], x[10], x[11], x[12], x[13], x[14], x[15], 
		          x[16], x[17], x[18], x[19], x[20], x[21], x[22], x[23],
		          x[24], x[25], x[26], x[27], x[28], x[29], x[30], x[31]};
    endfunction

    wire [31:0] shifterIn = (funct3 == 3'b001) ? flip32(aluIn1) : aluIn1;
    
    /* verilator lint_off WIDTH */
    wire [31:0] shifter   = $signed({instr[30] & aluIn1[31], shifterIn}) >>> aluIn2[4:0];
    /* verilator lint_on WIDTH */

    wire [31:0] leftShift = flip32(shifter);

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
            3'b000: aluOut = (funct7[5] & instr[5]) ? aluMinus[31:0] : aluPlus;    
            
            3'b001: aluOut = leftShift;
            3'b010: aluOut = {31'b0, LT};
            3'b011: aluOut = {31'b0, LTU};
            3'b100: aluOut = (aluIn1 ^ aluIn2);

            /*
            For logical or arithmetic right shift, one makes the difference also by testing funct7[5] 
            1 for arithmetic shift >>> (with sign expansion); 0 for logical shift >>.
            */
            3'b101: aluOut = shifter;
            
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
            3'b000: takeBranch = EQ;
            3'b001: takeBranch = !EQ;
            3'b100: takeBranch = LT;
            3'b101: takeBranch = !LT;
            3'b110: takeBranch = LTU;
            3'b111: takeBranch = !LTU;
            default: takeBranch = 1'b0;
        endcase
    end


    // The first three operations are implemented by a state machine
    localparam FETCH_INSTR = 0;
    localparam WAIT_INSTR  = 1;
    localparam FETCH_REGS  = 2;
    localparam EXECUTE     = 3;
    reg [1:0] state = FETCH_INSTR;

    // The fourth one (register write-back)
    assign writeBackData = (isJAL || isJALR) ? (PCplus4)    : 
                           (isLUI)           ?  Uimm     :
                           (isAUIPC)         ? (PCplusImm) :
                            aluOut;

    assign writeBackEn   = (state == EXECUTE && (
                            isALUreg || 
                            isALUimm ||
                            isJAL    || 
                            isJALR   ||
                            isLUI    ||
                            isAUIPC));

    wire [31:0] PCplusImm = PC + (instr[3] ? Jimm[31:0] :
                                  instr[4] ? Uimm[31:0] :
                                             Bimm[31:0]);
    wire [31:0] PCplus4 = PC+4;

    wire [31:0] nextPC   = ((isBranch && takeBranch) || isJAL) ? PCplusImm             :
                            isJALR                             ? {aluPlus[31:1],1'b0}  :
                            PCplus4;
                          

    always @(posedge clk) begin
        if(!reset) begin
            PC <= 0;
            state <= FETCH_INSTR;
        end else begin
            if(writeBackEn && rdId != 0) begin
                RegisterBank[rdId] <= writeBackData;
    
                `ifdef BENCH
                    $display("x%0d <= %b", rdId, writeBackData);
                `endif
            end

            case(state)
                FETCH_INSTR: begin
                    state = WAIT_INSTR;
                end

                WAIT_INSTR: begin
                    instr <= mem_rdata;    // instr <= MEM[PC[31:2]];
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
                end
            endcase
        end
    end 

    assign mem_addr = PC;
    assign mem_access = (state == FETCH_INSTR);

    `ifdef BENCH
        always @(posedge clk) begin
            if(state == FETCH_REGS) begin
                case(1'b1)
                    isALUreg: $display("ALUreg rd=%d rs1=%d rs2=%d  funct3=%b", rdId, rs1Id, rs2Id, funct3);
                    isALUimm: $display("ALUImm rd=%d rs1=%d imm=%0d funct3=%b", rdId, rs1Id, Iimm, funct3);
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
