template AbstractCircuit() {
	signal input x;
	signal y;
	signal output z;

	y <== x;
	z <== y;
}

template XXX() {
	signal input xxx;
	signal yyy;
	signal output zzz;

	yyy <== xxx;
	zzz <== yyy;
}

template Main() {
	signal input a;
	signal output b;

	component ac = AbstractCircuit();

	component xxx = XXX();

	ac.x <== a;
	// b <== ac.z;

	xxx.xxx <== ac.z;

	b <== xxx.zzz;
}

component main = Main();
