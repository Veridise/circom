template A() {
    signal input x;
    signal output y;
    y <== x;
}

template Main(n) {
    signal input x[n];
    signal output y[n];

    component a[n];

    for (var i = 0; i < n; i++) {
        a[i] = A();
        a[i].x <== x[i];
        y[i] <== a[i].y;
    }
}

component main = Main(4);
