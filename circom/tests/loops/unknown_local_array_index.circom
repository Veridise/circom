pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template ForUnknownIndex() {
    signal input in;
    signal output out;

    var arr1[10] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    var arr2[10] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    var arr3[10] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

    var acc = 0;
    for (var i = 1; i <= in; i++) {
        acc += i;
    }

    // non-quadractic constraint
    // out <== arr[acc];
    out <-- arr2[acc % 10];
}

component main = ForUnknownIndex();

//// Use the block labels to check that the loop is NOT unrolled
//CHECK-LABEL: define{{.*}} void @ForUnknownIndex_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9]+]])
//CHECK-NOT: unrolled_loop{{.*}}:
//CHECK: loop.cond{{.*}}:
//CHECK: loop.body{{.*}}:
//CHECK: loop.end{{.*}}:
//CHECK-NOT: unrolled_loop{{.*}}:
//CHECK:   }
