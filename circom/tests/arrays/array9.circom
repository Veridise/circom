pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function copy(inp) {
    var ret[3] = inp;
    return ret;
}

template ArrayCopyTemplate() {
    var inp[3];
    var outp[3] = copy(inp);
}

component main = ArrayCopyTemplate();

//CHECK-LABEL: define{{.*}} i256* @copy_{{[0-9]+}}
//CHECK-SAME: (i256* %[[ARENA:[0-9a-zA-Z_\.]+]]){{.*}} {
//CHECK:      store1:
//CHECK-NEXT:   %[[DST_PTR:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[ARENA]], i32 3
//CHECK-NEXT:   %[[SRC_PTR:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[ARENA]], i32 0
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
//CHECK-NEXT:   br label %return2
//CHECK-EMPTY:
//CHECK-NEXT: return2:
//CHECK-NEXT:   %[[T3:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[ARENA]], i32 3
//CHECK-NEXT:   ret i256* %[[T3]]
//CHECK-NEXT: }

//CHECK-LABEL: define{{.*}} void @ArrayCopyTemplate_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARENA:[0-9a-zA-Z_\.]+]]){{.*}} {
//CHECK:      call4:
//CHECK-NEXT:   %[[CALL_ARENA:[0-9a-zA-Z_\.]+]] = alloca [6 x i256], align 8
//CHECK-NEXT:   %[[DST_PTR_A:[0-9a-zA-Z_\.]+]] = getelementptr [6 x i256], [6 x i256]* %[[CALL_ARENA]], i32 0, i32 0
//CHECK-NEXT:   %[[SRC_PTR_A:[0-9a-zA-Z_\.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   %[[COPY_SRC_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR_A]], i32 0
//CHECK-NEXT:   %[[COPY_DST_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR_A]], i32 0
//CHECK-NEXT:   %[[COPY_VAL_0:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_0]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_0]], i256* %[[COPY_DST_0]], align 4
//CHECK-NEXT:   %[[COPY_SRC_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR_A]], i32 1
//CHECK-NEXT:   %[[COPY_DST_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR_A]], i32 1
//CHECK-NEXT:   %[[COPY_VAL_1:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_1]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_1]], i256* %[[COPY_DST_1]], align 4
//CHECK-NEXT:   %[[COPY_SRC_2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR_A]], i32 2
//CHECK-NEXT:   %[[COPY_DST_2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR_A]], i32 2
//CHECK-NEXT:   %[[COPY_VAL_2:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_2]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_2]], i256* %[[COPY_DST_2]], align 4
//CHECK-NEXT:   %[[CALL_ARENA_REF:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %[[CALL_ARENA]] to i256*
//CHECK-NEXT:   %[[SRC_PTR_B:[0-9a-zA-Z_\.]+]] = call i256* @copy_0(i256* %[[CALL_ARENA_REF]])
//CHECK-NEXT:   %[[DST_PTR_B:[0-9a-zA-Z_\.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %[[COPY_SRC_0]]1 = getelementptr i256, i256* %[[SRC_PTR_B]], i32 0
//CHECK-NEXT:   %[[COPY_DST_0]]2 = getelementptr i256, i256* %[[DST_PTR_B]], i32 0
//CHECK-NEXT:   %[[COPY_VAL_0]]3 = load i256, i256* %[[COPY_SRC_0]]1, align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_0]]3, i256* %[[COPY_DST_0]]2, align 4
//CHECK-NEXT:   %[[COPY_SRC_1]]4 = getelementptr i256, i256* %[[SRC_PTR_B]], i32 1
//CHECK-NEXT:   %[[COPY_DST_1]]5 = getelementptr i256, i256* %[[DST_PTR_B]], i32 1
//CHECK-NEXT:   %[[COPY_VAL_1]]6 = load i256, i256* %[[COPY_SRC_1]]4, align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_1]]6, i256* %[[COPY_DST_1]]5, align 4
//CHECK-NEXT:   %[[COPY_SRC_2]]7 = getelementptr i256, i256* %[[SRC_PTR_B]], i32 2
//CHECK-NEXT:   %[[COPY_DST_2]]8 = getelementptr i256, i256* %[[DST_PTR_B]], i32 2
//CHECK-NEXT:   %[[COPY_VAL_2]]9 = load i256, i256* %[[COPY_SRC_2]]7, align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_2]]9, i256* %[[COPY_DST_2]]8, align 4
//CHECK-NEXT:   br label %prologue
