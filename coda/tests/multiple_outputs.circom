pragma circom 2.0.0;

template Main() {
    signal input a;
    signal output b;
    signal output c;

    b <== a;
    c <== a;
}

component main{public[a]} = Main();
