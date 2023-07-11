pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s

// Arena layout (setup by caller):
// | l   m   n |        ret        | j |
// | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
function return_array_A(l, m, n) {
    var ret[5];
    for (var j = 0; j < n; j++) {
        ret[j] = 999;
    }
    return ret;
}

// Arena layout (setup by caller):
// | n   m |        ret        |
// | 0 | 1 | 2 | 3 | 4 | 5 | 6 |
function return_array_B(n, m) {
    var r[5] = return_array_A(12, m, n);
    return r;
}


template ArrayReturnTemplate(n) {
    var r[5] = return_array_B(n, 13);
}

component main = ArrayReturnTemplate(4);

//CHECK-LABEL: define i256 @return_array_B
//CHECK: call void @fr_copy_n(i256* %{{.*}}, i256* %{{.*}}, i32 5)
//CHECK: }

//CHECK-LABEL: define void @ArrayReturnTemplate
//CHECK: call void @fr_copy_n(i256* %{{.*}}, i256* %{{.*}}, i32 5)
//CHECK: }
