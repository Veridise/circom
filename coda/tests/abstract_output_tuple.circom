template AbstractCircuit() {
	signal input a;
	signal output b;
	signal output c;

	b <== a;
	c <== a;
}

template Main() {
	signal input x;
	signal output y;
	signal output z;

	component a = AbstractCircuit();

	a.a <== x;
	y <== a.b;
	z <== a.c;
}

component main = Main();
