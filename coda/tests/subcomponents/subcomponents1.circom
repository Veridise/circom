template A() {
    signal input a1;
    signal output a2;
    a2 <== a1;
}

template B() {
    signal input b1;
    signal output b2;
    b2 <== b1;
}

template C() {
    signal input c1;
    signal output c2;
    component a = A();
    a.a1 <== c1;
    component b = B();
    b.b1 <== a.a2;
    c2 <== b.b2;
}

component main = C();
