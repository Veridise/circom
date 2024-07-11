pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// Test STORE to an unknown index followed by LOAD from a known index.
// Ensure the interpreter doesn't mark more than necessary with Value::Unknown.
template UnknownIndexOverwriteKnown() {
    signal input in;
    signal output out;

    var scalar1 = 45;
    var arr1[10] = [00, 01, 02, 03, 04, 05, 06, 07, 08, 09];
    var arr2[10] = [10, 11, 12, 13, 14, 15, 16, 17, 18, 19];
    var arr3[10] = [20, 21, 22, 23, 24, 25, 26, 27, 28, 29];

    arr2[in] = 99;
    scalar1 = 46;

    // Neither of the below can be known at compile time since 'arr2[in]' is overwritten.
    // In fact, either assert could fail in certain runs, depends on the value of 'in'.
    assert(arr2[9] == 19);
    assert(arr2[9] == 99);

    // Those below CAN be known at compile time because the underlying arrays are not modified.
    assert(arr1[9] == 09);
    assert(arr1[4] == 04);
    assert(arr3[0] == 20);
    assert(arr3[7] == 27);

    // This can be known because the 'lvars' index for scalar values is always known.
    assert(scalar1 == 46);
}

component main = UnknownIndexOverwriteKnown();

//CHECK-LABEL: define{{.*}} void @UnknownIndexOverwriteKnown_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK:        call void @__assert(i1 %{{[0-9a-zA-Z_\.]+}})
//CHECK:        call void @__assert(i1 %{{[0-9a-zA-Z_\.]+}})
//CHECK:        call void @__assert(i1 true)
//CHECK:        call void @__assert(i1 true)
//CHECK:        call void @__assert(i1 true)
//CHECK:        call void @__assert(i1 true)
//CHECK:        call void @__assert(i1 true)
