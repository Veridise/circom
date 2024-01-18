pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// Tests LOAD from an unknown index with STORE to an unknown index.
template UnknownIndexLoadStore() {
    signal input in;
    signal output out[8];

    var unused1[9] = [0, 1, 2, 3, 4, 5, 6, 7, 8];
    var arr2[10] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    var unused2[11] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

    out[in] <-- arr2[in];
}

component main = UnknownIndexLoadStore();

// CHECK: define{{.*}} i256 @__array_load__9_to_19([0 x i256]* %0, i32 %1)
// CHECK: define{{.*}} void @__array_store__0_to_8([0 x i256]* %0, i32 %1, i256 %2)
// CHECK-NOT: define{{.*}} @__array_load__0_to_8
// CHECK-NOT: define{{.*}} @__array_store__9_to_19
// CHECK-NOT: define{{.*}} @__array_load__20_to_31
// CHECK-NOT: define{{.*}} @__array_store__20_to_31
