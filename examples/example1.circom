pragma circom 2.0.0;

template Not(){
   signal input a;
   signal output b;
   b <== (a + 1) - (2 * a);
}

component main {public [a]} = Not();