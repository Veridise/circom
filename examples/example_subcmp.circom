pragma circom 2.0.0;

template Id1() {
  signal input x;
  signal output y;
  y <== x;
}

template Id2() {
  signal input x;
  signal output y;
  y <== x;
}

template Main() {
  signal input a;
  component id1 = Id1();
  component id2 = Id2();
  id1.x <== a;
  id2.x <== a;
  signal output b;
  b <== id1.y;
}

component main {public [a]} = Main();
