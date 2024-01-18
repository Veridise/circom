pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// Tests literal value STORE to an unknown index.
template UnknownIndexStore() {
    signal input in;
    signal output out[8];

    out[in] <-- 999;
}

component main = UnknownIndexStore();

// CHECK: define{{.*}} void @__array_store__0_to_8([0 x i256]* %0, i32 %1, i256 %2)
// CHECK-NOT: define{{.*}} @__array_load__
// CHECK-NOT: define{{.*}} @__array_store__
