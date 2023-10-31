pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s

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

//CHECK-LABEL: define{{.*}} void @return_array_B_{{[0-9]+}}
//CHECK-SAME: (i256* %[[ARENA:.*]])
//CHECK: call void @return_array_A_{{[0-9]+}}(i256* %{{.*}})
//CHECK: %[[TEMP:.*]] = getelementptr i256, i256* %{{.*}}[[ARENA]], i32 2
//CHECK: call void @fr_copy_n(i256* %{{.*}}, i256* %{{.*}}[[TEMP]], i32 5)
//CHECK: ret void
//CHECK: }

//CHECK-LABEL: define{{.*}} void @return_array_A_{{[0-9]+}}
//CHECK-SAME: (i256* %[[ARENA:.*]])
//CHECK: ret void
//CHECK: }

//CHECK-LABEL: define{{.*}} void @ArrayReturnTemplate_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %{{.*}})
//CHECK: %lvars = alloca [6 x i256]
//CHECK: %[[TEMP:.*]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 1
//CHECK: call void @fr_copy_n(i256* %{{.*}}, i256* %{{.*}}[[TEMP]], i32 5)
//CHECK: }
