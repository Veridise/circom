pragma circom 2.0.0;

template Not(){
   signal input in;
   signal output out <== (in + 1) - (2 * in);
}

component main {public [in]} = Not();