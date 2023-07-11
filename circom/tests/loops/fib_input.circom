pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s

template Fibonacci() {
    signal input nth_fib;
    signal output out;

    var a = 0;
    var b = 1;
    var next = 0;

    var counter = nth_fib;
    while (counter > 2) {
        next = a + b;
        a = b;
        b = next;

        counter--;
    }

    out <-- (nth_fib == 0) ? 0 : (nth_fib == 1 ? 1 : a + b);
}

component main = Fibonacci();