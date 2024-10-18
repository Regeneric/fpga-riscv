integer memPC;
initial memPC = 0;

localparam  x0 = 0, x1 = 1, x2 = 2, x3 = 3, x4 = 4, x5 = 5, x6 = 6, x7 = 7,
            x8 = 8, x9 = 9, x10=10, x11=11, x12=12, x13=13, x14=14, x15=15, 
            x16=16, x17=17, x18=18, x19=19, x20=20, x21=21, x22=22, x23=23, 
            x24=24, x25=25, x26=26, x27=27, x28=28, x29=29, x30=30, x31=31;

localparam [31:0] NOP_OPCODE = 32'b0000000_00000_00000_000_00000_0110011;   // add x0, x0, x0

// R-Type  ;  Register Type  ;  register-to-register operations  ;  rd, rs1 and rs2  ;  ADD, SUB  etc.
// R-Type format  ;  funct7_rs2_rs1_funct3_rd_opcode  ;  7b_5b_5b_3b_5b_7b  ;  0000000_00000_00000_000_00000_0000000
// rd <- rs1 OP rs2

task RType;
    input [6:0] funct7;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] funct3;
    input [4:0] rd;
    input [6:0] opcode;
    begin
        /*
          By shifting the address using memPC[31:2], we effectively divide the memory address by 4, 
          converting it from a byte address to a word index. This lets us index into a memory array (MEM) 
          that stores 32-bit instructions.
        */
        MEM[memPC[31:2]] = {funct7, rs2, rs1, funct3, rd, opcode};
        memPC = memPC+4;
    end
endtask

// funct3
localparam f3ADD  = 3'b000, f3SUB = 3'b000;
localparam f3SLL  = 3'b001;
localparam f3SLT  = 3'b010;
localparam f3SLTU = 3'b011;
localparam f3XOR  = 3'b100;
localparam f3SRL  = 3'b101, f3SRA = 3'b101;
localparam f3OR   = 3'b110;
localparam f3AND  = 3'b111;

localparam funct7_0 = 7'b0000000;
localparam funct7_1 = 7'b0100000;

localparam opRtype = 7'b0110011;

task ADD;
    input [4:0] rs1;
    input [4:0] rs2;
    input [4:0] rd;
    begin
        RType(funct7_0, rs2, rs1, f3ADD, rd, opRtype);
    end
endtask

task SUB;
    input [4:0] rs1;
    input [4:0] rs2;
    input [4:0] rd;
    begin
        RType(funct7_1, rs2, rs1, f3SUB, rd, opRtype);
    end
endtask

task SLL;
    input [4:0] rs1;
    input [4:0] rs2;
    input [4:0] rd;
    begin
        RType(funct7_0, rs2, rs1, f3SLL, rd, opRtype);
    end
endtask

task SLT;
    input [4:0] rs1;
    input [4:0] rs2;
    input [4:0] rd;
    begin
        RType(funct7_0, rs2, rs1, f3SLT, rd, opRtype);
    end
endtask

task SLTU;
    input [4:0] rs1;
    input [4:0] rs2;
    input [4:0] rd;
    begin
        RType(funct7_0, rs2, rs1, f3SLTU, rd, opRtype);
    end
endtask

task XOR;
    input [4:0] rs1;
    input [4:0] rs2;
    input [4:0] rd;
    begin
        RType(funct7_0, rs2, rs1, f3XOR, rd, opRtype);
    end
endtask

task SRL;
    input [4:0] rs1;
    input [4:0] rs2;
    input [4:0] rd;
    begin
        RType(funct7_0, rs2, rs1, f3SRL, rd, opRtype);
    end
endtask

task SRA;
    input [4:0] rs1;
    input [4:0] rs2;
    input [4:0] rd;
    begin
        RType(funct7_0, rs2, rs1, f3SRA, rd, opRtype);
    end
endtask

task OR;
    input [4:0] rs1;
    input [4:0] rs2;
    input [4:0] rd;
    begin
        RType(funct7_0, rs2, rs1, f3OR, rd, opRtype);
    end
endtask

task AND;
    input [4:0] rs1;
    input [4:0] rs2;
    input [4:0] rd;
    begin
        RType(funct7_0, rs2, rs1, f3AND, rd, opRtype);
    end
endtask


// I-Type  ;  Immediate Type  ;  register and value  ;  rs1, rs2, imm  ;  LW, ADDI
// I-Type format  ;  imm_rs1_funct3_rd_opcode  ;  12b_5b_3b_5b_7b  ;  000000000000_00000_000_00000_0000000
// rd <- rs1 OP imm

task IType;
    input [31:0] imm;
    input [4:0]  rs1;
    input [2:0]  funct3;
    input [4:0]  rd;
    input [6:0]  opcode;
    begin
        // I-Type uses 12 bits of imm
        MEM[memPC[31:2]] = {imm[11:0], rs1, funct3, rd, opcode};
        memPC = memPC+4;
    end
endtask

localparam opItype = 7'b0010011;

task ADDI;
    input [4:0] rs1;
    input [4:0] rd;
    begin
        IType(imm, rs1, f3ADD, rd, opItype);
    end
endtask

task SLTI;
    input [4:0] rs1;
    input [4:0] rd;
    begin
        IType(imm, rs1, f3SLT, rd, opItype);
    end
endtask

task SLTUI;
    input [4:0] rs1;
    input [4:0] rd;
    begin
        IType(imm, rs1, f3SLTU, rd, opItype);
    end
endtask

task XORI;
    input [4:0] rs1;
    input [4:0] rd;
    begin
        IType(imm, rs1, f3XOR, rd, opItype);
    end
endtask

task ORI;
    input [4:0] rs1;
    input [4:0] rd;
    begin
        IType(imm, rs1, f3OR, rd, opItype);
    end
endtask

task ANDI;
    input [4:0] rs1;
    input [4:0] rd;
    begin
        IType(imm, rs1, f3AND, rd, opItype);
    end
endtask

// The three shifts, SLLI, SRLI, SRAI, encoded in R-Type format
// (rs2 is replaced with shift_amount=imm[4:0])  

task SLLI;
    input [4:0]  rs1;
    input [4:0]  rd;
    input [31:0] imm;
    begin
        RType(funct7_0, imm[4:0], rs1, f3SLL, rd, opItype);
    end
endtask

task SRLI;
    input [4:0]  rs1;
    input [4:0]  rd;
    input [31:0] imm;
    begin
        RType(funct7_0, imm[4:0], rs1, f3SRL, rd, opItype);
    end
endtask

task SRAI;
    input [4:0]  rs1;
    input [4:0]  rd;
    input [31:0] imm;
    begin
        RType(funct7_1, imm[4:0], rs1, f3SRA, rd, opItype);
    end
endtask


// J-Type ; Jump Type  ;  unconditional jump  ;  pc, imm  ;  JAL, JALR etc.
// J-Type format  ;  imm_imm_imm_imm_rd_opcode  ;  1b_10b_1b_8b_5b_7b  ;  0_0000000000_0_00000000_00000_0000000
// J-Type format  ;  imm_rd_opcode              ;  20b_5b_7b           ;  00000000000000000000_00000_0000000
// rd <- PC+4; PC <- PC+Jimm   ;  JAL
// rd <- PC+4; PC <- rs1+Iimm  ;  JALR

task JType;
    input [31:0] imm;
    input [4:0]  rd;
    input [6:0]  opcode;
    begin
        MEM[memPC[31:2]] = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode};
        memPC = memPC+4;
    end
endtask

task JAL;
    input [31:0] imm;
    input [4:0]  rd;
    begin
        JType(imm, rd, 7'b1101111);
    end 
endtask

// JALR is encoded in the I-Type format.

task JALR;
    input [4:0]  rs1;
    input [4:0]  rd;
    input [31:0] imm;
    begin
        IType(imm, rs1, 0'b000, rd, 7'b1100111);
    end
endtask


// B-Type  ;  Branch Type  ;  conditional branches  ;  pc, rs1, rs2  ;  BEQ, BNE  etc.
// B-Type format  ;  imm_imm_rs2_rs1_funct3_imm_imm_opcode  ;  1b_6b_5b_5b_3b_4b_1b_7b  ;  0_000000_00000_00000_000_0000_0_0000000
// B-Type format  ;  imm_rs2_rs1_funct3_opcode              ;  12b_5b_5b_3b_7b          ;  000000000000_00000_00000_000_0000000
// if(rs1 OP rs2) PC <- PC+Bimm

task BType;
    input [31:0] imm;
    input [4:0]  rs2;
    input [4:0]  rs1;
    input [2:0]  funct3;
    input [6:0]  opcode;
    begin
        MEM[memPC[31:2]] = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};
        memPC = memPC+4;
    end
endtask

localparam f3BEQ  = 0'b000;
localparam f3BNE  = 0'b001;
localparam f3BLT  = 0'b100;
localparam f3BGE  = 0'b101;
localparam f3BLTU = 0'b110;
localparam f3BGEU = 0'b111;

localparam opBtype = 7'b1100011;

task BEQ;
    input [4:0]  rs1;
    input [4:0]  rs2;
    input [31:0] imm;
    begin
        BType(imm, rs2, rs1, f3BEQ, opBtype);
    end
endtask

task BNE;
    input [4:0]  rs1;
    input [4:0]  rs2;
    input [31:0] imm;
    begin
        BType(imm, rs2, rs1, f3BNE, opBtype);
    end
endtask

task BLT;
    input [4:0]  rs1;
    input [4:0]  rs2;
    input [31:0] imm;
    begin
        BType(imm, rs2, rs1, f3BLT, opBtype);
    end
endtask

task BGE;
    input [4:0]  rs1;
    input [4:0]  rs2;
    input [31:0] imm;
    begin
        BType(imm, rs2, rs1, f3BGE, opBtype);
    end
endtask

task BLTU;
    input [4:0]  rs1;
    input [4:0]  rs2;
    input [31:0] imm;
    begin
        BType(imm, rs2, rs1, f3BLTU, opBtype);
    end
endtask

task BGEU;
    input [4:0]  rs1;
    input [4:0]  rs2;
    input [31:0] imm;
    begin
        BType(imm, rs2, rs1, f3BGEU, opBtype);
    end
endtask


// U-Type instructions
// U-Type format  ;  imm_rd_opcode  ;  20b_5b_7b  ;  00000000000000000000_00000_0000000
// if(rs1 OP rs2) PC <- PC+Bimm

task UType;
    input [31:0] imm;
    input [4:0]  rd;
    input [6:0]  opcode;
    begin
        MEM[memPC[31:2]] = {imm[31:12], rd, opcode};
        memPC = memPC+4;
    end
endtask

task LUI;
    input [4:0]  rd;
    input [31:0] imm;
    begin
        UType(imm, rd, 7'b0110111);
    end
endtask

task LUI;
    input [4:0]  rd;
    input [31:0] imm;
    begin
        UType(imm, rd, 7'b0010111);
    end
endtask