pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s

template B() {
    signal input x;
    signal output y;

    y <== x * x;
}

template C() {
    signal input x;
    signal output y;

    y <== x + x;
}

template A() {
    signal input x;
    signal output y;
    component c = C();
    component bs[3];

    bs[0] = B();
    bs[0].x <== x;

    bs[1] = B();
    bs[1].x <== x;

    bs[2] = B();
    bs[2].x <== x;

    c.x <== x;

    y <== bs[0].y + bs[1].y + bs[2].y + c.y;
}

component main = A();