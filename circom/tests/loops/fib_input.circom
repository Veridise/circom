pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template Fibonacci() {
    signal input nth_fib;
    signal output out;

    var a = 0;
    var b = 1;
    var next = 0;

    var counter = nth_fib;
    while (counter > 2) { // unknown iteration count
        next = a + b;
        a = b;
        b = next;

        counter--;
    }

    out <-- (nth_fib == 0) ? 0 : (nth_fib == 1 ? 1 : a + b);
}

component main = Fibonacci();

//// Use the block labels to check that the loop is NOT unrolled
//CHECK-LABEL: define{{.*}} void @Fibonacci_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9]+]])
//CHECK-NOT: unrolled_loop{{.*}}:
//CHECK: loop.cond{{.*}}:
//CHECK: loop.body{{.*}}:
//CHECK: loop.end{{.*}}:
//CHECK-NOT: unrolled_loop{{.*}}:
//CHECK:   }
