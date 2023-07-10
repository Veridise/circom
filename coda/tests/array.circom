pragma circom 2.0.0;

template Main(n) {
    signal input xs[n];
    signal output out;

    out <== xs[0];
}

component main{public[xs]} = Main(4);
