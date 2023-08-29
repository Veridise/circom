pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s

template FibonacciTmpl(N) {
    signal output out;

    var a = 0;
    var b = 1;
    var next = 0;

    var counter = N;
    while (counter > 2) { // known iteration count
        next = a + b;
        a = b;
        b = next;

        counter--;
    }

    if (N == 0) {
        out <-- 0;
    } else if (N == 1) {
        out <-- 1;
    } else {
        out <-- a + b;
    }
}

component main = FibonacciTmpl(5);

//CHECK-LABEL: define void @FibonacciTmpl_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9]+]])
//// Use the block labels to check that the loop is unrolled
//CHECK-NOT: loop.cond{{.*}}:
//CHECK-NOT: loop.body{{.*}}:
//CHECK-NOT: loop.end{{.*}}:
//CHECK: unrolled_loop{{.*}}:
//CHECK-NOT: loop.cond{{.*}}:
//CHECK-NOT: loop.body{{.*}}:
//CHECK-NOT: loop.end{{.*}}:
//// Check that final value stored to 'out' is computed correctly via unrolling
//CHECK: store{{[0-9]+}}:
//CHECK:   %[[T:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %{{.*}}[[ARG]], i32 0, i32 0
//CHECK:   store i256 5, i256* %{{.*}}[[T]], align 4
//CHECK:   }
