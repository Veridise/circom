pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// Ensure that non-zero initialization of for-loop iteration variable is handled properly.
template NonZeroInit() {
    signal input a[9];
    signal output b[9];

    for (var i = 4; i < 7; i++) {
        b[i] <-- a[i];
    }
    for (var i = 7; i < 9; i++) {
        b[i] <-- a[i];
    }
    for (var i = 0; i < 4; i++) {
        b[i] <-- a[i];
    }
}

component main = NonZeroInit();

//CHECK-LABEL: define{{.*}} void @NonZeroInit_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//
//CHECK:      store{{[0-9]+}}:
//CHECK-NEXT:   %[[VAR1:[0-9]+]] = getelementptr [1 x i256], [1 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 4, i256* %{{.*}}[[VAR1]], align 4
//CHECK-NEXT:   br label %{{.*}}
//
//CHECK:      store{{[0-9]+}}:
//CHECK-NEXT:   %[[VAR2:[0-9]+]] = getelementptr [1 x i256], [1 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 7, i256* %{{.*}}[[VAR2]], align 4
//CHECK-NEXT:   br label %{{.*}}
//
//CHECK:      store{{[0-9]+}}:
//CHECK-NEXT:   %[[VAR3:[0-9]+]] = getelementptr [1 x i256], [1 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 0, i256* %{{.*}}[[VAR3]], align 4
//CHECK-NEXT:   br label %{{.*}}
