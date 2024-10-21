integer L0_ = 8;
initial begin
    ADD(t0, zero, zero);
    ADDI(t1, zero, 32);

    Label(L0_);
        ADDI(t0, t0, 1);
        BNE(t0, t1, LabelRef(L0_));
        EBREAK();

        endASM();
end