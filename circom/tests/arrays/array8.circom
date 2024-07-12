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

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9a-zA-Z_\.]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:   i256* %var_[[X1:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9a-zA-Z_\.]+]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_[[X1]], i32 0
//CHECK-NEXT:   store i256 999, i256* %[[T0]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T1:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 8
//CHECK-NEXT:   %[[T2:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 8
//CHECK-NEXT:   %[[T3:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T2]], align 4
//CHECK-NEXT:   %[[T4:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T3]], i256 1)
//CHECK-NEXT:   store i256 %[[T4]], i256* %[[T1]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} i256* @return_array_A_
//CHECK-SAME: [[$F_ID_A:[0-9a-zA-Z_\.]+]](i256* %[[ARENA:[0-9a-zA-Z_\.]+]]){{.*}} {
//CHECK:      unrolled_loop7:
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[ARENA]] to [0 x i256]*
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[ARENA]] to [0 x i256]*
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T08]], i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T07]], [0 x i256]* null, i256* %[[T09]])
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[ARENA]] to [0 x i256]*
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[ARENA]] to [0 x i256]*
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T11]], i32 0, i256 4
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T10]], [0 x i256]* null, i256* %[[T12]])
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[ARENA]] to [0 x i256]*
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[ARENA]] to [0 x i256]*
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T14]], i32 0, i256 5
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T13]], [0 x i256]* null, i256* %[[T15]])
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[ARENA]] to [0 x i256]*
//CHECK-NEXT:   %[[T17:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[ARENA]] to [0 x i256]*
//CHECK-NEXT:   %[[T18:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T17]], i32 0, i256 6
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T16]], [0 x i256]* null, i256* %[[T18]])
//CHECK-NEXT:   br label %return8
//CHECK-EMPTY: 
//CHECK-NEXT: return8:
//CHECK-NEXT:   %[[T19:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[ARENA]], i32 3
//CHECK-NEXT:   ret i256* %[[T19]]
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} i256* @return_array_B_
//CHECK-SAME: [[$F_ID_B:[0-9a-zA-Z_\.]+]](i256* %[[ARENA:[0-9a-zA-Z_\.]+]]){{.*}} {
//CHECK:      call1:
//CHECK-NEXT:   %[[CALL_ARENA:[0-9a-zA-Z_\.]+]] = alloca [9 x i256], align 8
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr [9 x i256], [9 x i256]* %[[CALL_ARENA]], i32 0, i32 0
//CHECK-NEXT:   store i256 12, i256* %[[T01]], align 4
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [9 x i256], [9 x i256]* %[[CALL_ARENA]], i32 0, i32 1
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[ARENA]], i32 1
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T03]], align 4
//CHECK-NEXT:   store i256 %[[T04]], i256* %[[T02]], align 4
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr [9 x i256], [9 x i256]* %[[CALL_ARENA]], i32 0, i32 2
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[ARENA]], i32 0
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T06]], align 4
//CHECK-NEXT:   store i256 %[[T07]], i256* %[[T05]], align 4
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = bitcast [9 x i256]* %[[CALL_ARENA]] to i256*
//CHECK-NEXT:   %[[SRC_PTR:[0-9a-zA-Z_\.]+]] = call i256* @return_array_A_[[$F_ID_A]](i256* %[[T08]])
//CHECK-NEXT:   %[[DST_PTR:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[ARENA]], i32 2
//CHECK-NEXT:   %[[COPY_SRC_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 0
//CHECK-NEXT:   %[[COPY_DST_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 0
//CHECK-NEXT:   %[[COPY_VAL_0:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_0]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_0]], i256* %[[COPY_DST_0]], align 4
//CHECK-NEXT:   %[[COPY_SRC_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 1
//CHECK-NEXT:   %[[COPY_DST_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 1
//CHECK-NEXT:   %[[COPY_VAL_1:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_1]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_1]], i256* %[[COPY_DST_1]], align 4
//CHECK-NEXT:   %[[COPY_SRC_2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 2
//CHECK-NEXT:   %[[COPY_DST_2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 2
//CHECK-NEXT:   %[[COPY_VAL_2:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_2]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_2]], i256* %[[COPY_DST_2]], align 4
//CHECK-NEXT:   %[[COPY_SRC_3:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 3
//CHECK-NEXT:   %[[COPY_DST_3:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 3
//CHECK-NEXT:   %[[COPY_VAL_3:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_3]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_3]], i256* %[[COPY_DST_3]], align 4
//CHECK-NEXT:   %[[COPY_SRC_4:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 4
//CHECK-NEXT:   %[[COPY_DST_4:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 4
//CHECK-NEXT:   %[[COPY_VAL_4:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_4]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_4]], i256* %[[COPY_DST_4]], align 4
//CHECK-NEXT:   br label %return2
//CHECK-EMPTY: 
//CHECK-NEXT: return2:
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[ARENA]], i32 2
//CHECK-NEXT:   ret i256* %[[T10]]
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @ArrayReturnTemplate_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARENA:[0-9a-zA-Z_\.]+]]){{.*}} {
//CHECK:      call2:
//CHECK-NEXT:   %[[CALL_ARENA:[0-9a-zA-Z_\.]+]] = alloca [7 x i256], align 8
//CHECK-NEXT:   %[[T2:[0-9a-zA-Z_\.]+]] = getelementptr [7 x i256], [7 x i256]* %[[CALL_ARENA]], i32 0, i32 0
//CHECK-NEXT:   store i256 4, i256* %[[T2]], align 4
//CHECK-NEXT:   %[[T3:[0-9a-zA-Z_\.]+]] = getelementptr [7 x i256], [7 x i256]* %[[CALL_ARENA]], i32 0, i32 1
//CHECK-NEXT:   store i256 13, i256* %[[T3]], align 4
//CHECK-NEXT:   %[[T4:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %[[CALL_ARENA]] to i256*
//CHECK-NEXT:   %[[SRC_PTR:[0-9a-zA-Z_\.]+]] = call i256* @return_array_B_[[$F_ID_B]](i256* %[[T4]])
//CHECK-NEXT:   %[[DST_PTR:[0-9a-zA-Z_\.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[COPY_SRC_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 0
//CHECK-NEXT:   %[[COPY_DST_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 0
//CHECK-NEXT:   %[[COPY_VAL_0:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_0]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_0]], i256* %[[COPY_DST_0]], align 4
//CHECK-NEXT:   %[[COPY_SRC_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 1
//CHECK-NEXT:   %[[COPY_DST_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 1
//CHECK-NEXT:   %[[COPY_VAL_1:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_1]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_1]], i256* %[[COPY_DST_1]], align 4
//CHECK-NEXT:   %[[COPY_SRC_2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 2
//CHECK-NEXT:   %[[COPY_DST_2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 2
//CHECK-NEXT:   %[[COPY_VAL_2:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_2]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_2]], i256* %[[COPY_DST_2]], align 4
//CHECK-NEXT:   %[[COPY_SRC_3:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 3
//CHECK-NEXT:   %[[COPY_DST_3:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 3
//CHECK-NEXT:   %[[COPY_VAL_3:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_3]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_3]], i256* %[[COPY_DST_3]], align 4
//CHECK-NEXT:   %[[COPY_SRC_4:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 4
//CHECK-NEXT:   %[[COPY_DST_4:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 4
//CHECK-NEXT:   %[[COPY_VAL_4:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_4]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_4]], i256* %[[COPY_DST_4]], align 4
//CHECK-NEXT:   br label %prologue
