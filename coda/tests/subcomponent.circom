template A() {
    signal input x1;
    signal output x2;

    x2 <== x1;
}

template B() {
  signal input y1;
  signal output y2;
  component a = A();
  a.x1 <== y1;
  y2 <== a.x2;
}

// template C() {
//   signal input z1;
//   signal input z2;
//   signal output z3;
//   component a = A();
//   component b = B();
//   a.x1 <== z1;
//   b.y1 <== z2;
//   z3 <== a.x2 + b.y2;
// }

template C() {
  signal input z1;
  signal input z2;
  signal output z3;
  component a1 = A();
  component b = B();
  component a2 = A();
  a1.x1 <== z1;
  b.y1 <== z1;
  a2.x1 <== z2;
  z3 <== a1.x1 + b.y2 + a2.x1;
}

component main = C();
