pragma circom 2.0.0;

// template Example() {
//    signal input a1;
//    signal input a2;
//    signal x;
//    signal output b;
//    x <== a1;
//    b <== x;
// }
//
// component main {public [a1, a2]} = Example();

template A() {
    signal input a_in;
    signal output a_out;

    a_out <== a_in;
}

template B() {
    signal input b_in;
    signal output b_out;

    component a = A();
    a.a_in <== b_in;
    b_out <== a.a_out;
}

component main {public [b_in]} = B();
