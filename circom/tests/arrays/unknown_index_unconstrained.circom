pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// Tests LOAD from an unknown index with STORE to a known index.
template UnknownIndex() {
    signal input in;
    signal output out;

    var arr2[10] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

    // non-quadractic constraint
    // out <== arr[acc];
    out <-- arr2[in];
}

component main = UnknownIndex();

//CHECK-LABEL: define{{.*}} i256 @__array_load__0_to_10([0 x i256]* %0, i32 %1) {
//
//CHECK-LABEL: define{{.*}} void @UnknownIndex_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK:        %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK:        %[[T03:[0-9a-zA-Z_\.]+]] = call i256 @__array_load__0_to_10([0 x i256]* %{{[0-9a-zA-Z_\.]+}}, i32 %{{[0-9a-zA-Z_\.]+}})
//CHECK-NEXT:   store i256 %[[T03]], i256* %[[T04]], align 4
//CHECK-NEXT:   br label %prologue
