rm -f a.out
iverilog -DBENCH -DSIM -DPASSTHROUGH_PLL -DBOARD_FREQ=10 -DCPU_FREQ=10 $1 $2 $3
vvp a.out
