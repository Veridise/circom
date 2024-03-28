pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

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

//CHECK-LABEL: define{{.*}} i256* @return_array_B_{{[0-9]+}}
//CHECK-SAME: (i256* %[[ARENA:[0-9a-zA-Z_.]+]]){{.*}} {
//CHECK:         %[[C0:[0-9a-zA-Z_.]+]] = call i256* @return_array_A_{{[0-9]+}}(i256* %{{.*}})
//CHECK:       return{{[0-9]+}}:
//CHECK-NEXT:    %[[T0:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[ARENA]], i32 2
//CHECK-NEXT:    ret i256* %[[T0]]
//CHECK: }

//CHECK-LABEL: define{{.*}} i256* @return_array_A_{{[0-9]+}}
//CHECK-SAME: (i256* %[[ARENA:[0-9a-zA-Z_.]+]]){{.*}} {
//CHECK:       return{{[0-9]+}}:
//CHECK-NEXT:    %[[T0:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[ARENA]], i32 3
//CHECK-NEXT:    ret i256* %[[T0]]
//CHECK: }

//CHECK-LABEL: define{{.*}} void @ArrayReturnTemplate_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARENA:[0-9a-zA-Z_.]+]]){{.*}} {
//CHECK:       call{{[0-9]+}}:
//CHECK-NEXT:    %[[ARENA_B:[0-9a-zA-Z_.]+]] = alloca [7 x i256], align 8
//CHECK-NEXT:    %[[T02:[0-9a-zA-Z_.]+]] = getelementptr [7 x i256], [7 x i256]* %[[ARENA_B]], i32 0, i32 0
//CHECK-NEXT:    store i256 4, i256* %[[T02]], align 4
//CHECK-NEXT:    %[[T03:[0-9a-zA-Z_.]+]] = getelementptr [7 x i256], [7 x i256]* %[[ARENA_B]], i32 0, i32 1
//CHECK-NEXT:    store i256 13, i256* %[[T03]], align 4
//CHECK-NEXT:    %[[T04:[0-9a-zA-Z_.]+]] = bitcast [7 x i256]* %[[ARENA_B]] to i256*
//CHECK-NEXT:    %[[C01:[0-9a-zA-Z_.]+]] = call i256* @return_array_B_0(i256* %[[T04]])
//CHECK-NEXT:    %[[T05:[0-9a-zA-Z_.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:    call void @fr_copy_n(i256* %[[C01]], i256* %[[T05]], i32 5)
//CHECK: }
