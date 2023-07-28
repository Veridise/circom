template Main() {
  signal input a;
  signal output b;

  b <== 4*a + 2;
}

component main = Main();
