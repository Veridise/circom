pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s

template A() {
	signal input a, b, d;
	signal output out;

	out <== (a + b) * d;
}

component main = A();

