pragma circom 2.0.0;

include "./mux1.circom";

template Main() {
  signal output out;
  component mux1 = Mux1();
  mux1.c[0] <== 1;
  mux1.c[1] <== 2;
  mux1.s <== 3;
  out <== mux1.out;
}

component main = Main();
