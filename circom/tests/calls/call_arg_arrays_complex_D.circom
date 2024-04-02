pragma circom 2.1.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function sum(a, b, c, d) {
    if (a < 7) {
        return b;
    } else if (a > 12) {
        return c;
    } else {
        return d;
    }
}

template CallArgTest() {
    signal input a;
    signal input b[2][3];
    signal input c[2][3];
    signal input d[2][3];
    signal output z[2][3];

    z <-- sum(a, b, c, d);
}

component main = CallArgTest();

//CHECK-LABEL: define{{.*}} i256* @sum_0(i256* %0){{.*}} {
//CHECK-NEXT: sum_0:
//CHECK-NEXT:   br label %branch1
//CHECK-EMPTY:
//CHECK-NEXT: branch1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T01]], align 4
//CHECK-NEXT:   %call.fr_lt = call i1 @fr_lt(i256 %[[T02]], i256 7)
//CHECK-NEXT:   br i1 %call.fr_lt, label %if.then, label %if.else
//CHECK-EMPTY:
//CHECK-NEXT: if.then:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 1
//CHECK-NEXT:   ret i256* %[[T03]]
//CHECK-EMPTY:
//CHECK-NEXT: if.else:
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T04]], align 4
//CHECK-NEXT:   %call.fr_gt = call i1 @fr_gt(i256 %[[T05]], i256 12)
//CHECK-NEXT:   br i1 %call.fr_gt, label %if.then1, label %if.else2
//CHECK-EMPTY:
//CHECK-NEXT: if.merge:
//CHECK-NEXT:   unreachable
//CHECK-EMPTY:
//CHECK-NEXT: if.then1:
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 7
//CHECK-NEXT:   ret i256* %[[T06]]
//CHECK-EMPTY:
//CHECK-NEXT: if.else2:
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 13
//CHECK-NEXT:   ret i256* %[[T07]]
//CHECK-EMPTY:
//CHECK-NEXT: if.merge3:
//CHECK-NEXT:   unreachable
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @CallArgTest_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [0 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY:
//CHECK-NEXT: call1:
//CHECK-NEXT:   %sum_0_arena = alloca [19 x i256], align 8
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = getelementptr [19 x i256], [19 x i256]* %sum_0_arena, i32 0, i32 0
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 6
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T02]], align 4
//CHECK-NEXT:   store i256 %[[T03]], i256* %[[T01]], align 4
//CHECK-NEXT:   %[[DST_PTR:[0-9a-zA-Z_.]+]] = getelementptr [19 x i256], [19 x i256]* %sum_0_arena, i32 0, i32 1
//CHECK-NEXT:   %[[SRC_PTR:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 7
//CHECK-NEXT:   %copy_src_0 = getelementptr i256, i256* %[[SRC_PTR]], i32 0
//CHECK-NEXT:   %copy_dst_0 = getelementptr i256, i256* %[[DST_PTR]], i32 0
//CHECK-NEXT:   %copy_val_0 = load i256, i256* %copy_src_0, align 4
//CHECK-NEXT:   store i256 %copy_val_0, i256* %copy_dst_0, align 4
//CHECK-NEXT:   %copy_src_1 = getelementptr i256, i256* %[[SRC_PTR]], i32 1
//CHECK-NEXT:   %copy_dst_1 = getelementptr i256, i256* %[[DST_PTR]], i32 1
//CHECK-NEXT:   %copy_val_1 = load i256, i256* %copy_src_1, align 4
//CHECK-NEXT:   store i256 %copy_val_1, i256* %copy_dst_1, align 4
//CHECK-NEXT:   %copy_src_2 = getelementptr i256, i256* %[[SRC_PTR]], i32 2
//CHECK-NEXT:   %copy_dst_2 = getelementptr i256, i256* %[[DST_PTR]], i32 2
//CHECK-NEXT:   %copy_val_2 = load i256, i256* %copy_src_2, align 4
//CHECK-NEXT:   store i256 %copy_val_2, i256* %copy_dst_2, align 4
//CHECK-NEXT:   %copy_src_3 = getelementptr i256, i256* %[[SRC_PTR]], i32 3
//CHECK-NEXT:   %copy_dst_3 = getelementptr i256, i256* %[[DST_PTR]], i32 3
//CHECK-NEXT:   %copy_val_3 = load i256, i256* %copy_src_3, align 4
//CHECK-NEXT:   store i256 %copy_val_3, i256* %copy_dst_3, align 4
//CHECK-NEXT:   %copy_src_4 = getelementptr i256, i256* %[[SRC_PTR]], i32 4
//CHECK-NEXT:   %copy_dst_4 = getelementptr i256, i256* %[[DST_PTR]], i32 4
//CHECK-NEXT:   %copy_val_4 = load i256, i256* %copy_src_4, align 4
//CHECK-NEXT:   store i256 %copy_val_4, i256* %copy_dst_4, align 4
//CHECK-NEXT:   %copy_src_5 = getelementptr i256, i256* %[[SRC_PTR]], i32 5
//CHECK-NEXT:   %copy_dst_5 = getelementptr i256, i256* %[[DST_PTR]], i32 5
//CHECK-NEXT:   %copy_val_5 = load i256, i256* %copy_src_5, align 4
//CHECK-NEXT:   store i256 %copy_val_5, i256* %copy_dst_5, align 4
//CHECK-NEXT:   %[[DST_PTR:[0-9a-zA-Z_.]+]] = getelementptr [19 x i256], [19 x i256]* %sum_0_arena, i32 0, i32 7
//CHECK-NEXT:   %[[SRC_PTR:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 13
//CHECK-NEXT:   %copy_src_01 = getelementptr i256, i256* %[[SRC_PTR]], i32 0
//CHECK-NEXT:   %copy_dst_02 = getelementptr i256, i256* %[[DST_PTR]], i32 0
//CHECK-NEXT:   %copy_val_03 = load i256, i256* %copy_src_01, align 4
//CHECK-NEXT:   store i256 %copy_val_03, i256* %copy_dst_02, align 4
//CHECK-NEXT:   %copy_src_14 = getelementptr i256, i256* %[[SRC_PTR]], i32 1
//CHECK-NEXT:   %copy_dst_15 = getelementptr i256, i256* %[[DST_PTR]], i32 1
//CHECK-NEXT:   %copy_val_16 = load i256, i256* %copy_src_14, align 4
//CHECK-NEXT:   store i256 %copy_val_16, i256* %copy_dst_15, align 4
//CHECK-NEXT:   %copy_src_27 = getelementptr i256, i256* %[[SRC_PTR]], i32 2
//CHECK-NEXT:   %copy_dst_28 = getelementptr i256, i256* %[[DST_PTR]], i32 2
//CHECK-NEXT:   %copy_val_29 = load i256, i256* %copy_src_27, align 4
//CHECK-NEXT:   store i256 %copy_val_29, i256* %copy_dst_28, align 4
//CHECK-NEXT:   %copy_src_310 = getelementptr i256, i256* %[[SRC_PTR]], i32 3
//CHECK-NEXT:   %copy_dst_311 = getelementptr i256, i256* %[[DST_PTR]], i32 3
//CHECK-NEXT:   %copy_val_312 = load i256, i256* %copy_src_310, align 4
//CHECK-NEXT:   store i256 %copy_val_312, i256* %copy_dst_311, align 4
//CHECK-NEXT:   %copy_src_413 = getelementptr i256, i256* %[[SRC_PTR]], i32 4
//CHECK-NEXT:   %copy_dst_414 = getelementptr i256, i256* %[[DST_PTR]], i32 4
//CHECK-NEXT:   %copy_val_415 = load i256, i256* %copy_src_413, align 4
//CHECK-NEXT:   store i256 %copy_val_415, i256* %copy_dst_414, align 4
//CHECK-NEXT:   %copy_src_516 = getelementptr i256, i256* %[[SRC_PTR]], i32 5
//CHECK-NEXT:   %copy_dst_517 = getelementptr i256, i256* %[[DST_PTR]], i32 5
//CHECK-NEXT:   %copy_val_518 = load i256, i256* %copy_src_516, align 4
//CHECK-NEXT:   store i256 %copy_val_518, i256* %copy_dst_517, align 4
//CHECK-NEXT:   %[[DST_PTR:[0-9a-zA-Z_.]+]] = getelementptr [19 x i256], [19 x i256]* %sum_0_arena, i32 0, i32 13
//CHECK-NEXT:   %[[SRC_PTR:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 19
//CHECK-NEXT:   %copy_src_019 = getelementptr i256, i256* %[[SRC_PTR]], i32 0
//CHECK-NEXT:   %copy_dst_020 = getelementptr i256, i256* %[[DST_PTR]], i32 0
//CHECK-NEXT:   %copy_val_021 = load i256, i256* %copy_src_019, align 4
//CHECK-NEXT:   store i256 %copy_val_021, i256* %copy_dst_020, align 4
//CHECK-NEXT:   %copy_src_122 = getelementptr i256, i256* %[[SRC_PTR]], i32 1
//CHECK-NEXT:   %copy_dst_123 = getelementptr i256, i256* %[[DST_PTR]], i32 1
//CHECK-NEXT:   %copy_val_124 = load i256, i256* %copy_src_122, align 4
//CHECK-NEXT:   store i256 %copy_val_124, i256* %copy_dst_123, align 4
//CHECK-NEXT:   %copy_src_225 = getelementptr i256, i256* %[[SRC_PTR]], i32 2
//CHECK-NEXT:   %copy_dst_226 = getelementptr i256, i256* %[[DST_PTR]], i32 2
//CHECK-NEXT:   %copy_val_227 = load i256, i256* %copy_src_225, align 4
//CHECK-NEXT:   store i256 %copy_val_227, i256* %copy_dst_226, align 4
//CHECK-NEXT:   %copy_src_328 = getelementptr i256, i256* %[[SRC_PTR]], i32 3
//CHECK-NEXT:   %copy_dst_329 = getelementptr i256, i256* %[[DST_PTR]], i32 3
//CHECK-NEXT:   %copy_val_330 = load i256, i256* %copy_src_328, align 4
//CHECK-NEXT:   store i256 %copy_val_330, i256* %copy_dst_329, align 4
//CHECK-NEXT:   %copy_src_431 = getelementptr i256, i256* %[[SRC_PTR]], i32 4
//CHECK-NEXT:   %copy_dst_432 = getelementptr i256, i256* %[[DST_PTR]], i32 4
//CHECK-NEXT:   %copy_val_433 = load i256, i256* %copy_src_431, align 4
//CHECK-NEXT:   store i256 %copy_val_433, i256* %copy_dst_432, align 4
//CHECK-NEXT:   %copy_src_534 = getelementptr i256, i256* %[[SRC_PTR]], i32 5
//CHECK-NEXT:   %copy_dst_535 = getelementptr i256, i256* %[[DST_PTR]], i32 5
//CHECK-NEXT:   %copy_val_536 = load i256, i256* %copy_src_534, align 4
//CHECK-NEXT:   store i256 %copy_val_536, i256* %copy_dst_535, align 4
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_.]+]] = bitcast [19 x i256]* %sum_0_arena to i256*
//CHECK-NEXT:   %[[SRC_PTR:[0-9a-zA-Z_.]+]] = call i256* @sum_0(i256* %[[T10]])
//CHECK-NEXT:   %[[DST_PTR:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   %copy_src_037 = getelementptr i256, i256* %[[SRC_PTR]], i32 0
//CHECK-NEXT:   %copy_dst_038 = getelementptr i256, i256* %[[DST_PTR]], i32 0
//CHECK-NEXT:   %copy_val_039 = load i256, i256* %copy_src_037, align 4
//CHECK-NEXT:   store i256 %copy_val_039, i256* %copy_dst_038, align 4
//CHECK-NEXT:   %copy_src_140 = getelementptr i256, i256* %[[SRC_PTR]], i32 1
//CHECK-NEXT:   %copy_dst_141 = getelementptr i256, i256* %[[DST_PTR]], i32 1
//CHECK-NEXT:   %copy_val_142 = load i256, i256* %copy_src_140, align 4
//CHECK-NEXT:   store i256 %copy_val_142, i256* %copy_dst_141, align 4
//CHECK-NEXT:   %copy_src_243 = getelementptr i256, i256* %[[SRC_PTR]], i32 2
//CHECK-NEXT:   %copy_dst_244 = getelementptr i256, i256* %[[DST_PTR]], i32 2
//CHECK-NEXT:   %copy_val_245 = load i256, i256* %copy_src_243, align 4
//CHECK-NEXT:   store i256 %copy_val_245, i256* %copy_dst_244, align 4
//CHECK-NEXT:   %copy_src_346 = getelementptr i256, i256* %[[SRC_PTR]], i32 3
//CHECK-NEXT:   %copy_dst_347 = getelementptr i256, i256* %[[DST_PTR]], i32 3
//CHECK-NEXT:   %copy_val_348 = load i256, i256* %copy_src_346, align 4
//CHECK-NEXT:   store i256 %copy_val_348, i256* %copy_dst_347, align 4
//CHECK-NEXT:   %copy_src_449 = getelementptr i256, i256* %[[SRC_PTR]], i32 4
//CHECK-NEXT:   %copy_dst_450 = getelementptr i256, i256* %[[DST_PTR]], i32 4
//CHECK-NEXT:   %copy_val_451 = load i256, i256* %copy_src_449, align 4
//CHECK-NEXT:   store i256 %copy_val_451, i256* %copy_dst_450, align 4
//CHECK-NEXT:   %copy_src_552 = getelementptr i256, i256* %[[SRC_PTR]], i32 5
//CHECK-NEXT:   %copy_dst_553 = getelementptr i256, i256* %[[DST_PTR]], i32 5
//CHECK-NEXT:   %copy_val_554 = load i256, i256* %copy_src_552, align 4
//CHECK-NEXT:   store i256 %copy_val_554, i256* %copy_dst_553, align 4
//CHECK-NEXT:   br label %prologue
