pragma circom 2.0.0;

template Not(){
   signal input in1;
   signal input in2;
   signal input in3;
   signal input in4;
   signal output out;

   out <== in1 + in2 + in3 + in4 + 536;
}

component main {public [in1, in2, in3, in4]} = Not();