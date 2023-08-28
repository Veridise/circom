template A(n) {
	signal input xs[n];
	signal output y;

	var total = 0;
	for (var i = 0; i < n; i++) {
		total += xs[i];
	}

	y <== total;
}

template Main() {
	signal output y;

	component a2 = A(2);
	for (var i = 0; i < 2; i++) {
		a2.xs[i] <== 2;
	}

	component a3 = A(3);
	for (var j = 0; j < 3; j++) {
		a3.xs[j] <== 3;
	}

	y <== a2.y + a3.y;
}

component main = Main();
