pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function funWithLoop(n) {
	var acc = 0;
    for (var i = 1; i <= n; i++) {
        acc += i;
    }
    return acc;
}

template KnownFunctionArgs() {
    signal output out[3];

    out[0] <-- funWithLoop(4); // 0 + 1 + 2 + 3 + 4 = 10
    out[1] <-- funWithLoop(5); // 0 + 1 + 2 + 3 + 4 + 5 = 15
    
    var acc = 1;
    for (var i = 2; i <= funWithLoop(3); i++) {
        acc *= i;
    }
    out[2] <-- acc; // 1 * 2 * 3 * 4 * 5 * 6 = 720
}

component main = KnownFunctionArgs();

//CHECK-LABEL: define void @KnownFunctionArgs_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9]+]])
//// Check storing initial constant values to 'out'
//CHECK: store{{[0-9]+}}:
//CHECK:   %[[T1:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %{{.*}}[[ARG]], i32 0, i32 0
//CHECK:   store i256 10, i256* %{{.*}}[[T1]], align 4
//CHECK: store{{[0-9]+}}:
//CHECK:   %[[T2:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %{{.*}}[[ARG]], i32 0, i32 1
//CHECK:   store i256 15, i256* %{{.*}}[[T2]], align 4
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
//CHECK:   %[[T3:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %{{.*}}[[ARG]], i32 0, i32 2
//CHECK:   store i256 720, i256* %{{.*}}[[T3]], align 4
