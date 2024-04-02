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
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = getelementptr [19 x i256], [19 x i256]* %sum_0_arena, i32 0, i32 1
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 7
//CHECK-NEXT:   call void @fr_copy_n(i256* %[[T05]], i256* %[[T04]], i32 6)
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = getelementptr [19 x i256], [19 x i256]* %sum_0_arena, i32 0, i32 7
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 13
//CHECK-NEXT:   call void @fr_copy_n(i256* %[[T07]], i256* %[[T06]], i32 6)
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_.]+]] = getelementptr [19 x i256], [19 x i256]* %sum_0_arena, i32 0, i32 13
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 19
//CHECK-NEXT:   call void @fr_copy_n(i256* %[[T09]], i256* %[[T08]], i32 6)
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_.]+]] = bitcast [19 x i256]* %sum_0_arena to i256*
//CHECK-NEXT:   %call.sum_0 = call i256* @sum_0(i256* %[[T10]])
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   call void @fr_copy_n(i256* %call.sum_0, i256* %[[T11]], i32 6)
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY:
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
