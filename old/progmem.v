initial begin
    // R-Type format  ;  funct7_rs2_rs1_funct3_rd_opcode        ;  7b_5b_5b_3b_5b_7b        ;  0000000_00000_00000_000_00000_0000000
    // I-Type format  ;  imm_rs1_funct3_rd_opcode               ;  12b_5b_3b_5b_7b          ;  000000000000_00000_000_00000_0000000
    // S-Type format  ;  imm_rs2_rs1_funct3_imm_opcode          ;  7b_5b_5b_3b_5b_7b        ;  0000000_00000_00000_000_00000_0000000
    // B-Type format  ;  imm_imm_rs2_rs1_funct3_imm_imm_opcode  ;  1b_6b_5b_5b_3b_4b_1b_7b  ;  0_000000_00000_00000_000_0000_0_0000000  ;  0000000_00000_00000_000_00000_0000000
    // U-Type format  ;  imm_rd_opcode                          ;  20b_5b_7b                ;  00000000000000000000_00000_0000000
    // J-Type format  ;  imm_imm_imm_imm_rd_opcode              ;  1b_10b_1b_8b_5b_7b       ;  0_0000000000_0_00000000_00000_0000000    ;  00000000000000000000_00000_0000000

    PC = 0;

    // REGISTER  ;  ALIAS  ;  DESCRIPTION
    // ----------;---------;-----------------------
    //  x0	     ;  zero   ;  Hardwired to 0
    //  x5       ;  t0     ;  Temporary Register 0
    //  x6       ;  t1     ;  Temporary Register 1
    //  x7       ;  t2     ;  Temporary Register 2

    // add x0, x0, x0               add       ALUREG
    // R-Type   funct7  rs2   rs1   f3  rd    opcode
    instr = 32'b0000000_00000_00000_000_00000_0110011;


    // add x5, x6, x7                add       ALUREG
    // R-Type    funct7  rs2   rs1   f3  rd    opcode
    MEM[0] = 32'b0000000_00111_00110_000_00101_0110011;
    
    // sub x5, x6, x7                sub       ALUREG
    // R-Type    funct7  rs2   rs1   f3  rd    opcode
    MEM[1] = 32'b0100000_00111_00110_000_00101_0110011;

    // and x5, x6, x7                and       ALUREG
    // R-Type    funct7  rs2   rs1   f3  rd    opcode
    MEM[2] = 32'b0000000_00111_00110_111_00101_0110011;

    // or x5, x6, x7                 or        ALUREG
    // R-Type    funct7  rs2   rs1   f3  rd    opcode
    MEM[3] = 32'b0000000_00111_00110_110_00101_0110011;

    // xor x5, x6, x7                xor       ALUREG
    // R-Type    funct7  rs2   rs1   f3  rd    opcode
    MEM[4] = 32'b0000000_00111_00110_100_00101_0110011;

    // sll x5, x6, x7                sll       ALUREG
    // R-Type    funct7  rs2   rs1   f3  rd    opcode
    MEM[5] = 32'b0000000_00111_00110_001_00101_0110011;

    // slr x5, x6, x7                slr       ALUREG
    // R-Type    funct7  rs2   rs1   f3  rd    opcode
    MEM[6] = 32'b0000000_00111_00110_101_00101_0110011;


    // addi x5, x6, 1               add       ALUIMM
    // I-Type    imm          rs1   f3  rd    opcode
    MEM[7] = 32'b000000000001_00110_000_00101_0010011;

    // andi x5, x6, 1               and       ALUIMM
    // I-Type    imm          rs1   f3  rd    opcode
    MEM[8] = 32'b000000000001_00110_111_00101_0010011;

    // ori x5, x6, 1                or        ALUIMM
    // I-Type    imm          rs1   f3  rd    opcode
    MEM[9] = 32'b000000000001_00110_110_00101_0010011;

    // xori x5, x6, 1                xor       ALUIMM
    // I-Type     imm          rs1   f3  rd    opcode
    MEM[10] = 32'b000000000001_00110_100_00101_0010011;

    // slli x5, x6, 1                sll       ALUIMM
    // I-Type     imm          rs1   f3  rd    opcode
    MEM[11] = 32'b000000000001_00110_001_00101_0010011;


    // beq x0, x0, 0                 beq       BRANCH
    // B-Type     imm    rs2   rs1   f3  imm   opcode
    MEM[12] = 32'b000000_00000_00000_000_00000_1100011;

    // jal x5, 1                            JAL
    // J-Type     imm                 rd    opcode
    MEM[13] = 32'b0000000000000000001_00000_1101111;

    // jalr x5, x6, 1               jalr      JALR
    // I-Type     imm         rs1   f3  rd    opcode
    MEM[14] = 32'b00000000001_00110_000_00101_1100111;

    // aupic x5, 1                           AUPIC
    // U-Type     imm                  rd    opcode
    MEM[15] = 32'b00000000000000000001_00101_0010111;

    // lui x5, 1                             LUI
    // U-Type     imm                  rd    opcode
    MEM[16] = 32'b00000000000000000001_00101_0110111;

    // lw x2,0(x1)                   w         LOAD
    // I-Type     imm          rs1   f3  rd    opcode
    MEM[17] = 32'b000000000000_00001_010_00010_0000011;

    // sw x2,0(x1)                   w         STORE
    // S-Type     imm    rs2   rs1   f3  imm   opcode
    MEM[18] = 32'b000000_00010_00001_010_00000_0100011;

    // ebreak
    //                                         SYSTEM
    MEM[19] = 32'b000000000001_00000_000_00000_1110011;
end