// Infinite loop
integer L0_ = 4;
initial begin
    PC = 0;

    ADD(t0, zero, zero);
    Label(L0_);
        ADDI(t0, t0, 1);
        JAL(zero, LabelRef(L0_));
        EBREAK();
        endASM();   
end