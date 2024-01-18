pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// Test STORE to an unknown index followed by LOAD from a known index.
template UnknownIndexOverwriteKnown() {
    signal input in;
    signal output out;

    var arr[10] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    arr[in] = 99;

    // NOTE: The compiler will not allow constraints to be generated using 'arr' since an
    // unknown index was used to assign a value within 'arr'. The following are not allowed:
    //      arr[in] === 99;
    //      arr[9] === 9;
    //      out <== arr[9];

    // We can however use assert statements...
    // Neither of the below can be known at compile time since index 'in' is overwritten.
    // In fact, either assert could fail in certain runs, depends on the value of 'in'.
    assert(arr[9] == 9);
    assert(arr[9] == 99);
}

component main = UnknownIndexOverwriteKnown();

//CHECK-LABEL: define{{.*}} void @UnknownIndexOverwriteKnown_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NOT: @__assert(i1 true)
