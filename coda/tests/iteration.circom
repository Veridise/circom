template Test1(n) {
    signal input xs[n];
	signal output ys[n];

    for (var i = 0; i < n; i++) {
        ys[i] <== xs[i];
    }
}

// component main = Test1(4);

template Test2(n) {
    signal output x;

	var total = 0;
    for (var i = 0; i < n; i++) {
        total += i;
    }

    x <== total;
}

component main = Test2(4);
