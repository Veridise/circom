template A() {
    signal input in;
    signal output out;

    out <== in;
}

template B() {
    signal input in;
    signal output out;

    out <== in;
}

template C() {
    signal input in;
    signal output out;

    out <== in;
}

template D() {
    signal input in;
    signal output out;

    component a = A();
    a.in <== in;

    component b = B();
    b.in <== in;

    component c = C();
    c.in <== in;

    out <== c.out;
}

component main {public [in]} = D();
