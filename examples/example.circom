pragma circom 2.0.0;

template Example() {
   signal input a1;
   signal input a2;
   signal x;
   signal output b;
   x <== a1;
   b <== x;
}

component main {public [a1, a2]} = Example();