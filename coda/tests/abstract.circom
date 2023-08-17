template AbstractCircuit() {
	signal input x;
	signal output y;
	y <== x;
}

template Main() {
	signal input a;
	signal output b;

	component ac = AbstractCircuit();

	ac.x <== a;
	b <== ac.y;
}

component main = Main();
