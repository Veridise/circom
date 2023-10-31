pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// References to the Inner subcmp use LocationRule::Mapped because of the 'i' parameter
template Inner(i) {
    signal input in;
    signal output out;
    
    out <-- in & i;
}

template Num2Bits(n) {
    signal input in;
    signal output out[n];
    
    component c[n];
    for (var i = 0; i < n; i++) {
    	c[i] = Inner(i);
    	c[i].in <-- in;
    	out[i] <-- c[i].out;
    }
}

component main = Num2Bits(3);

//CHECK-LABEL: define{{.*}} void @Inner_{{[0-9]+}}_build({ [0 x i256]*, i32 }* %0){{.*}} {
//
//CHECK-LABEL: define{{.*}} void @Inner_
//CHECK-SAME: [[$RUN_1:[0-9]+]]_run([0 x i256]* %0){{.*}} {
//
//CHECK-LABEL: define{{.*}} void @Inner_{{[0-9]+}}_build({ [0 x i256]*, i32 }* %0){{.*}} {
//
//CHECK-LABEL: define{{.*}} void @Inner_
//CHECK-SAME: [[$RUN_2:[0-9]+]]_run([0 x i256]* %0){{.*}} {
//
//CHECK-LABEL: define{{.*}} void @Inner_{{[0-9]+}}_build({ [0 x i256]*, i32 }* %0){{.*}} {
//
//CHECK-LABEL: define{{.*}} void @Inner_
//CHECK-SAME: [[$RUN_3:[0-9]+]]_run([0 x i256]* %0){{.*}} {
//
//CHECK-LABEL: define{{.*}} void @Num2Bits_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK: unrolled_loop{{[0-9]+}}:
//CHECK: call void @Inner_[[$RUN_1]]_run([0 x i256]* %
//CHECK: call void @Inner_[[$RUN_2]]_run([0 x i256]* %
//CHECK: call void @Inner_[[$RUN_3]]_run([0 x i256]* %
