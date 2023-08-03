template AND() {
    signal input a;
    signal input b;
    signal output out;

    out <== a*b;
}

template Foo(n) {
    signal input x1;
    signal input x2;
    signal output y;
    component foo1;
    component foo2;

    if (n == 1) {
        y <== 1;
    } else {
        var n_ = n\2;

        foo1 = Foo(n_);
        foo1.x1 <== x1;
        foo1.x2 <== x2;

        foo2 = Foo(n_);
        foo2.x1 <== x1;
        foo2.x2 <== x2;

        y <== foo1.y + foo2.y;
    }
}

template MultiAND(n) {
    signal input in[n];
    signal output out;
    component and1;
    component and2;
    component and3;
    component and4;
    if (n==1) {
        out <== in[0];
    } else if (n==2) {
        and1 = AND();
        and1.a <== in[0];
        and1.b <== in[1];
        out <== and1.out;
    } else {
        and2 = AND();
        var n1 = n\2;
        var n2 = n-n\2;
        and3 = MultiAND(n1);
        and4 = MultiAND(n2);
        var i;
        for (i=0; i<n1; i++) and3.in[i] <== in[i];
        for (i=0; i<n2; i++) and4.in[i] <== in[n1+i];
        and2.a <== and3.out;
        and2.b <== and4.out;
        out <== and2.out;
    }
}

component main = Foo(4);
