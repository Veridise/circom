template Main() {
    signal input x;
    signal output y;

    var i;
    i = x;
    i += 1;
    i += 1;
    i += 1;
    i += 1;

    y <== i;
}

component main = Main();
