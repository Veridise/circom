pragma circom 2.0.0;

template Example1() {
    signal input x1;
    signal input x2;
    signal tmp;
    signal output y;
    tmp <== x1;
    y <== tmp * x2;
}

component main {public [x1, x2]} = Example1();
