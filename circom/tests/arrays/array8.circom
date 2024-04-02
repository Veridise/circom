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
//CHECK:        %[[SRC_PTR:[0-9a-zA-Z_.]+]] = call i256* @return_array_A_{{[0-9]+}}(i256* %{{.*}})
//CHECK-NEXT:   %[[DST_PTR:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[ARENA]], i32 2
//CHECK-NEXT:   %[[COPY_SRC_0:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 0
//CHECK-NEXT:   %[[COPY_DST_0:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 0
//CHECK-NEXT:   %[[COPY_VAL_0:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_0]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_0]], i256* %[[COPY_DST_0]], align 4
//CHECK-NEXT:   %[[COPY_SRC_1:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 1
//CHECK-NEXT:   %[[COPY_DST_1:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 1
//CHECK-NEXT:   %[[COPY_VAL_1:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_1]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_1]], i256* %[[COPY_DST_1]], align 4
//CHECK-NEXT:   %[[COPY_SRC_2:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 2
//CHECK-NEXT:   %[[COPY_DST_2:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 2
//CHECK-NEXT:   %[[COPY_VAL_2:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_2]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_2]], i256* %[[COPY_DST_2]], align 4
//CHECK-NEXT:   %[[COPY_SRC_3:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 3
//CHECK-NEXT:   %[[COPY_DST_3:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 3
//CHECK-NEXT:   %[[COPY_VAL_3:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_3]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_3]], i256* %[[COPY_DST_3]], align 4
//CHECK-NEXT:   %[[COPY_SRC_4:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 4
//CHECK-NEXT:   %[[COPY_DST_4:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 4
//CHECK-NEXT:   %[[COPY_VAL_4:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_4]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_4]], i256* %[[COPY_DST_4]], align 4
//CHECK-NEXT:   br label %return2
//CHECK-EMPTY: 
//CHECK-NEXT: return2:
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[ARENA]], i32 2
//CHECK-NEXT:   ret i256* %[[T10]]
//CHECK-NEXT: }

//CHECK-LABEL: define{{.*}} i256* @return_array_A_{{[0-9]+}}
//CHECK-SAME: (i256* %[[ARENA:[0-9a-zA-Z_.]+]]){{.*}} {
//CHECK:       return{{[0-9]+}}:
//CHECK-NEXT:    %[[T0:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[ARENA]], i32 3
//CHECK-NEXT:    ret i256* %[[T0]]
//CHECK-NEXT:  }

//CHECK-LABEL: define{{.*}} void @ArrayReturnTemplate_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARENA:[0-9a-zA-Z_.]+]]){{.*}} {
//CHECK:        %[[SRC_PTR:[0-9a-zA-Z_.]+]] = call i256* @return_array_B_{{[0-9]+}}(i256* %{{[0-9a-zA-Z_.]+}})
//CHECK-NEXT:   %[[DST_PTR:[0-9a-zA-Z_.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[COPY_SRC_0:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 0
//CHECK-NEXT:   %[[COPY_DST_0:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 0
//CHECK-NEXT:   %[[COPY_VAL_0:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_0]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_0]], i256* %[[COPY_DST_0]], align 4
//CHECK-NEXT:   %[[COPY_SRC_1:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 1
//CHECK-NEXT:   %[[COPY_DST_1:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 1
//CHECK-NEXT:   %[[COPY_VAL_1:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_1]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_1]], i256* %[[COPY_DST_1]], align 4
//CHECK-NEXT:   %[[COPY_SRC_2:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 2
//CHECK-NEXT:   %[[COPY_DST_2:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 2
//CHECK-NEXT:   %[[COPY_VAL_2:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_2]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_2]], i256* %[[COPY_DST_2]], align 4
//CHECK-NEXT:   %[[COPY_SRC_3:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 3
//CHECK-NEXT:   %[[COPY_DST_3:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 3
//CHECK-NEXT:   %[[COPY_VAL_3:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_3]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_3]], i256* %[[COPY_DST_3]], align 4
//CHECK-NEXT:   %[[COPY_SRC_4:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 4
//CHECK-NEXT:   %[[COPY_DST_4:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 4
//CHECK-NEXT:   %[[COPY_VAL_4:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_4]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_4]], i256* %[[COPY_DST_4]], align 4
//CHECK-NEXT:   br label %prologue
