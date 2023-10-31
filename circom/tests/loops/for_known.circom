pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template ForKnown(N) {
    signal output out;

    var acc = 0;
    for (var i = 1; i <= N; i++) {
        acc += i;
    }

    out <-- acc;
}

component main = ForKnown(10);

//CHECK-LABEL: define{{.*}} void @ForKnown_{{[0-9]+}}_run
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
//CHECK:   store i256 55, i256* %{{.*}}[[T]], align 4
//CHECK:   }
