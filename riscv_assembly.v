integer memPC;
initial memPC = 0;

localparam  x0 = 0, x1 = 1, x2 = 2, x3 = 3, x4 = 4, x5 = 5, x6 = 6, x7 = 7,
            x8 = 8, x9 = 9, x10=10, x11=11, x12=12, x13=13, x14=14, x15=15, 
            x16=16, x17=17, x18=18, x19=19, x20=20, x21=21, x22=22, x23=23, 
            x24=24, x25=25, x26=26, x27=27, x28=28, x29=29, x30=30, x31=31;

// ABI register names
localparam  zero = x0, ra = x1, sp = x2, gp = x3, tp = x4, t0 = x5, t1 = x6, 
            t2   = x7, fp = x8, s0 = x8, s1 = x9, a0 =x10, a1 =x11, a2 =x12,
            a3   =x13, a4 =x14, a5 =x15, a6 =x16, a7 =x17, s2 =x18, s3 =x19,
            s4   =x20, s5 =x21, s6 =x22, s7 =x23, s8 =x24, s9 =x25, s10=x26,
            s11  =x27, t3 =x28, t4 =x29, t5 =x30, t6 =x31; 


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
    input [4:0] rd;
    input [4:0] rs1;
    input [4:0] rs2;
    begin
        RType(funct7_0, rs2, rs1, f3ADD, rd, opRtype);
    end
endtask

task SUB;
    input [4:0] rd;
    input [4:0] rs1;
    input [4:0] rs2;
    begin
        RType(funct7_1, rs2, rs1, f3SUB, rd, opRtype);
    end
endtask

task SLL;
    input [4:0] rd;
    input [4:0] rs1;
    input [4:0] rs2;
    begin
        RType(funct7_0, rs2, rs1, f3SLL, rd, opRtype);
    end
endtask

task SLT;
    input [4:0] rd;
    input [4:0] rs1;
    input [4:0] rs2;
    begin
        RType(funct7_0, rs2, rs1, f3SLT, rd, opRtype);
    end
endtask

task SLTU;
    input [4:0] rd;
    input [4:0] rs1;
    input [4:0] rs2;
    begin
        RType(funct7_0, rs2, rs1, f3SLTU, rd, opRtype);
    end
endtask

task XOR;
    input [4:0] rd;
    input [4:0] rs1;
    input [4:0] rs2;
    begin
        RType(funct7_0, rs2, rs1, f3XOR, rd, opRtype);
    end
endtask

task SRL;
    input [4:0] rd;
    input [4:0] rs1;
    input [4:0] rs2;
    begin
        RType(funct7_0, rs2, rs1, f3SRL, rd, opRtype);
    end
endtask

task SRA;
    input [4:0] rd;
    input [4:0] rs1;
    input [4:0] rs2;
    begin
        RType(funct7_0, rs2, rs1, f3SRA, rd, opRtype);
    end
endtask

task OR;
    input [4:0] rd;
    input [4:0] rs1;
    input [4:0] rs2;
    begin
        RType(funct7_0, rs2, rs1, f3OR, rd, opRtype);
    end
endtask

task AND;
    input [4:0] rd;
    input [4:0] rs1;
    input [4:0] rs2;
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
    input [4:0]  rd;
    input [4:0]  rs1;
    input [31:0] imm;
    begin
        IType(imm, rs1, f3ADD, rd, opItype);
    end
endtask

task SLTI;
    input [4:0] rd;
    input [4:0] rs1;
    input [31:0] imm;
    begin
        IType(imm, rs1, f3SLT, rd, opItype);
    end
endtask

task SLTUI;
    input [4:0] rd;
    input [4:0] rs1;
    input [31:0] imm;
    begin
        IType(imm, rs1, f3SLTU, rd, opItype);
    end
endtask

task XORI;
    input [4:0] rd;
    input [4:0] rs1;
    input [31:0] imm;
    begin
        IType(imm, rs1, f3XOR, rd, opItype);
    end
endtask

task ORI;
    input [4:0] rd;
    input [4:0] rs1;
    input [31:0] imm;
    begin
        IType(imm, rs1, f3OR, rd, opItype);
    end
endtask

task ANDI;
    input [4:0] rd;
    input [4:0] rs1;
    input [31:0] imm;
    begin
        IType(imm, rs1, f3AND, rd, opItype);
    end
endtask

// The three shifts, SLLI, SRLI, SRAI, encoded in R-Type format
// (rs2 is replaced with shift_amount=imm[4:0])  

task SLLI;
    input [4:0] rd;
    input [4:0] rs1;
    input [31:0] imm;
    begin
        RType(funct7_0, imm[4:0], rs1, f3SLL, rd, opItype);
    end
endtask

task SRLI;
    input [4:0] rd;
    input [4:0] rs1;
    input [31:0] imm;
    begin
        RType(funct7_0, imm[4:0], rs1, f3SRL, rd, opItype);
    end
endtask

task SRAI;
    input [4:0] rd;
    input [4:0] rs1;
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
    input [4:0]  rd;
    input [31:0] imm;
    begin
        JType(imm, rd, 7'b1101111);
    end 
endtask

// JALR is encoded in the I-Type format.

task JALR;
    input [4:0]  rd;
    input [4:0]  rs1;
    input [31:0] imm;
    begin
        IType(imm, rs1, 3'b000, rd, 7'b1100111);
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

localparam f3BEQ  = 3'b000;
localparam f3BNE  = 3'b001;
localparam f3BLT  = 3'b100;
localparam f3BGE  = 3'b101;
localparam f3BLTU = 3'b110;
localparam f3BGEU = 3'b111;

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


// U-Type  ;  Upper Immediate Type  ;  20 bit value to upper bits  ;  rd, imm  ;  LUI, AUIPC  etc.
// U-Type format  ;  imm_rd_opcode  ;  20b_5b_7b  ;  00000000000000000000_00000_0000000
// rd <- Uimm
// rd <- PC+Uimm

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

task AUIPC;
    input [4:0]  rd;
    input [31:0] imm;
    begin
        UType(imm, rd, 7'b0010111);
    end
endtask


// Load Instructions are I-Type instructions
// I-Type  ;  Immediate Type  ;  register and value  ;  rs1, rd, imm  ;  LW, ADDI
// I-Type format  ;  imm_rs1_funct3_rd_opcode  ;  12b_5b_3b_5b_7b  ;  000000000000_00000_000_00000_0000000
// rd <- mem[rs1+Iimm]

localparam f3LB  = 3'b000;
localparam f3LH  = 3'b001;
localparam f3LW  = 3'b010;
localparam f3LBU = 3'b100;
localparam f3LHU = 3'b101;

localparam opLoad = 7'b0000011;

task LB;
    input [4:0]  rd;
    input [4:0]  rs1;
    input [31:0] imm;
    begin
        IType(imm, rs1, f3LB, rd, opLoad);
    end
endtask

task LH;
    input [4:0]  rd;
    input [4:0]  rs1;
    input [31:0] imm;
    begin
        IType(imm, rs1, f3LH, rd, opLoad);
    end
endtask

task LW;
    input [4:0]  rd;
    input [4:0]  rs1;
    input [31:0] imm;
    begin
        IType(imm, rs1, f3LW, rd, opLoad);
    end
endtask

task LBU;
    input [4:0]  rd;
    input [4:0]  rs1;
    input [31:0] imm;
    begin
        IType(imm, rs1, f3LBU, rd, opLoad);
    end
endtask

task LHU;
    input [4:0]  rd;
    input [4:0]  rs1;
    input [31:0] imm;
    begin
        IType(imm, rs1, f3LHU, rd, opLoad);
    end
endtask


// S-Type  ;  Store Type  ;  register-to-memory  ;  mem, rs1, rs2  ;  SW, SB etc.
// S-Type format  ;  imm_rs2_rs1_funct3_imm_opcode  ;  7b_5b_5b_3b_5b_7b  ;  0000000_00000_00000_000_00000_0000000
// S-Type format  ;  imm_rs2_rs1_funct3_opcode      ;  12b_5b_5b_3b_7b    ;  000000000000_00000_00000_000_0000000
// mem[rs1+Simm] <- rs2

task SType;
    input [31:0] imm;
    input [4:0]  rs2;
    input [4:0]  rs1;
    input [2:0]  funct3;
    input [6:0]  opcode;
    begin
        MEM[memPC[31:2]] = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
        memPC = memPC+4;
    end
endtask

localparam f3SB = 3'b000;
localparam f3SH = 3'b001;
localparam f3SW = 3'b010;

localparam opStore = 7'b0100011;

task SB;
    input [4:0]  rs1;
    input [4:0]  rs2;
    input [32:0] imm;
    begin
        SType(imm, rs2, rs1, f3SB, opStore);
    end
endtask

task SH;
    input [4:0]  rs1;
    input [4:0]  rs2;
    input [32:0] imm;
    begin
        SType(imm, rs2, rs1, f3SH, opStore);
    end
endtask

task SW;
    input [4:0]  rs1;
    input [4:0]  rs2;
    input [32:0] imm;
    begin
        SType(imm, rs2, rs1, f3SW, opStore);
    end
endtask


//
// System Instructions

localparam opSystem = 7'b1110011;

task FENCE;
    input [3:0] pred;
    input [3:0] succ;
    begin
        MEM[memPC[31:2]] = {4'b0000, pred, succ, 5'b00000, 3'b000, opSystem};
        memPC = memPC+4;
    end
endtask

task FENCE_I;
    begin
        MEM[memPC[31:2]] = {4'b0000, 4'b0000, 4'b0000, 5'b00000, 3'b001, 5'b00000, opSystem};
        memPC = memPC+4;
    end
endtask

task ECALL;
    begin
        MEM[memPC[31:2]] = {12'b000000000001, 5'b00000, 3'b000, 5'b00000, opSystem};
        memPC = memPC+4;
    end
endtask

task EBREAK;
   begin
      MEM[memPC[31:2]] = {12'b000000000001, 5'b00000, 3'b000, 5'b00000, opSystem};
      memPC = memPC+4;
   end
endtask 

task CSRRW;
    input [4:0]  rd;
    input [11:0] csr;
    input [4:0]  rs1;
    begin
        MEM[memPC[31:2]] = {csr, rs1, 3'b010, rd, opSystem};
        memPC = memPC+4;
    end
endtask

task CSRRC;
    input [4:0]  rd;
    input [11:0] csr;
    input [4:0]  rs1;
    begin
        MEM[memPC[31:2]] = {csr, rs1, 3'b011, rd, opSystem};
        memPC = memPC+4;
    end 
endtask

task CSRRWI;
    input [4:0]  rd;
    input [11:0] csr;
    input [32:0] imm;
    begin
        MEM[memPC[31:2]] = {csr, imm[4:0], 3'b101, rd, opSystem};
        memPC = memPC+4;
    end
endtask

task CSRRI;
    input [4:0]  rd;
    input [11:0] csr;
    input [31:0] imm;
    begin
        MEM[memPC[31:2]] = {csr, imm[4:0], 3'b101, rd, opSystem};
        memPC = memPC+4;
    end
endtask

task CSRRCI;
    input [4:0]  rd;
    input [11:0] csr;
    input [31:0] imm;
    begin
        MEM[memPC[31:2]] = {csr, imm[4:0], 3'b111, rd, opSystem};
        memPC = memPC+4;
    end
endtask


//
// Pseudo Instructions

localparam [31:0] NOP_OPCODE = 32'b0000000_00000_00000_000_00000_0110011;   // add x0, x0, x0
task NOP;
    begin
        ADD(zero, zero, zero);
    end
endtask


/*
  https://stackoverflow.com/questions/50742420/
  risc-v-build-32-bit-constants-with-lui-and-addi
  Add imm[11] << 12 to the constant passed to LUI
  if imm[11] == 1
*/
task LI;
    input [4:0]  rd;
    input [31:0] imm;
    begin
        if(imm == 0) begin
            ADD(rd, zero, zero);
        end else if($signed(imm) >= -2048 && $signed(imm) < 2048) begin
            ADDI(rd, zero, imm);
        end else begin
            LUI(rd, imm+(imm[11] << 12));
            if(imm[11:0] != 0) begin
                ADDI(rd, rd, imm[11:0]);
            end
        end
    end
endtask

task CALL;
    input [31:0] offset;
    begin
        AUIPC(t1, offset);
        JALR(ra, t1, offset[11:0]);
    end
endtask

task RET;
    begin
        JALR(zero, ra, 0);
    end
endtask

task MV;
    input [4:0] rd;
    input [4:0] rs1;
    begin
        ADD(rd, rs1, zero);
    end
endtask

task J;
    input [31:0] imm;
    begin
        JAL(zero, imm);
    end
endtask;

task JR;
    input [4:0]  rs1;
    input [31:0] imm;
    begin
        JALR(zero, rs1, imm);
    end
endtask

task BEQZ;
    input [4:0]  rs1;
    input [31:0] imm;
    begin
        BEQ(rs1, zero, imm);
    end
endtask

task BNEZ;
    input [4:0]  rs1;
    input [31:0] imm;
    begin
        BNE(rs1, zero, imm);
    end
endtask

task BGT;
    input [4:0]  rs1;
    input [4:0]  rs2;
    input [31:0] imm;
    begin
        BLT(rs2, rs1, imm);
    end
endtask

task DATAW;
    input [31:0] w;
    begin
        MEM[memPC[31:2]] = w;
        memPC = memPC+4;
    end
endtask

task DATAB;
    input [7:0] b1;
    input [7:0] b2;
    input [7:0] b3;
    input [7:0] b4;
    begin
        MEM[memPC[31:2]][ 7: 0] = b1;
        MEM[memPC[31:2]][15: 8] = b2;
        MEM[memPC[31:2]][23:16] = b3;
        MEM[memPC[31:2]][31:24] = b4;
        memPC = memPC+4;
    end
endtask


//
// Labels

integer ASMerror = 0;

task Label;
    inout integer L;
    begin
       `ifdef BENCH
            if(L[0] === 1'bx) begin
                $display("Missing label initialization!");
                ASMerror = 1;
            end else if(L != memPC) begin
                $display("Incorrect label initialization!");
                $display("Expected: %0d     Got: %0d", memPC, L);
                ASMerror = 1;
            end
            $display("Label: ", memPC);
        `endif
    end
endtask

function [31:0] LabelRef;
    input integer L;
    begin
        `ifdef BENCH
            if(L[0] === 1'bx) begin
                $display("Reference to uninitialized label!");
                ASMerror = 1;
            end
        `endif
        
        LabelRef = L - memPC;
    end 
endfunction

task endASM;
    begin
        `ifdef GET_ASM_LABELS
            $finish();
        `endif
        
        `ifdef BENCH
            if(ASMerror) $finish();
        `endif
    end 
endtask