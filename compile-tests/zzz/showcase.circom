pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && circom --llvm -o %t %s

template A() {
  signal input a;
  signal input b;
  signal input c;

  signal output x;
  signal output y;
  signal output z;

  x <== a;
  y <-- b;
  y === b;
}

component main = A();
