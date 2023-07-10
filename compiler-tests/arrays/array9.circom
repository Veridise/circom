pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && circom --llvm -o %t %s

function copy(inp) {
    var ret[3] = inp;
    return ret;
}

template ArrayCopyTemplate() {
    var inp[3];
    var outp[3] = copy(inp);
}

component main = ArrayCopyTemplate();


//CHECK-LABEL: define i256 @copy_0(
//CHECK: call void @fr_copy_n(i256* %{{.*}}, i256* %{{.*}}, i32 3)
