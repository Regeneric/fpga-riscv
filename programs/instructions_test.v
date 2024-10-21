initial begin    
    ADD(zero, zero, zero);
    ADD(t0, zero, zero);
    
    NOP();
    NOP();
    NOP();

    ADDI(t0, t0, 1);
    ADDI(t0, t0, 1);
    ADDI(t0, t0, 1);
    ADDI(t0, t0, 1);

    ADD(t1, t0, zero);
    ADD(t2, t0, t1);
    
    SRLI(t2, t2, 3);
    SLLI(t2, t2, 31);
    SRAI(t2, t2, 5);
    SRLI(t0, t2, 26);

    EBREAK();
end