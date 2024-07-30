pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// The circom compiler only gives a warning for this:
// warning[T3001]: Typing warning: Mismatched dimensions, assigning to an array an expression of smaller length, the remaining positions are assigned to 0.

template ImplicitExtension() {
    signal output out[10];
    var temp[10] = [99, 98, 97, 96, 95];
    out[0] <-- temp[0];
    out[4] <-- temp[4];
    out[5] <-- temp[5];
    out[9] <-- temp[9];
}

component main = ImplicitExtension();

//CHECK-LABEL: define{{.*}} void @ImplicitExtension_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK:      store6:
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 99, i256* %[[T06]], align 4
//CHECK:      store7:
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 4
//CHECK-NEXT:   store i256 95, i256* %[[T07]], align 4
