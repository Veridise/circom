pragma circom 2.0.0;

template Loop() {
    signal input a;
    signal output b;

    var x = a;
    for (var i = 0; i < 10; i++) {
        x++;
    }

    b <== x;
}

component main{public[a]} = Loop();
