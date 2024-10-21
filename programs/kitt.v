// Knight Rider
integer L0_ = 12;
integer L1_ = 12;
integer L2_ = 20;
initial begin
    ADDI(t0, zero, 16);
    ADDI(t1, zero, 1);
    ADDI(t2, zero, 1);
    
    Label(L0_);
        Label(L1_);
            SLLI(t2, t2, 1);
            BNE(t2, t0, LabelRef(L1_));

        Label(L2_);
            SRLI(t2, t2, 1);
            BNE(t2, t1, LabelRef(L2_));

        JAL(zero, LabelRef(L0_));
end