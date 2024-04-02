pragma circom 2.1.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function overwrite(a, b) {
    a[0] = b[1];
    a[1] = b[0];
    return a[0] + a[1];
}

template Gotcha() {
    signal input x[2];
    signal input y[2];
    signal output p;
    log(x[0]);
    p <== overwrite(x, y);
    log(x[0]);
}

component main = Gotcha();

//CHECK-LABEL: define{{.*}} i256 @overwrite_0(i256* %0){{.*}} {
//CHECK-NEXT: overwrite_0:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY:
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 3
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T01]], align 4
//CHECK-NEXT:   store i256 %[[T02]], i256* %[[T03]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY:
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 1
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 2
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T04]], align 4
//CHECK-NEXT:   store i256 %[[T05]], i256* %[[T06]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY:
//CHECK-NEXT: return3:
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T07]], align 4
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 1
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T09]], align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %[[T08]], i256 %[[T10]])
//CHECK-NEXT:   ret i256 %call.fr_add
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @Gotcha_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [0 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %log1
//CHECK-EMPTY:
//CHECK-NEXT: log1:
//CHECK-NEXT:   br label %call2
//CHECK-EMPTY:
//CHECK-NEXT: call2:
//CHECK-NEXT:   %overwrite_0_arena = alloca [4 x i256], align 8
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = getelementptr [4 x i256], [4 x i256]* %overwrite_0_arena, i32 0, i32 0
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:   call void @fr_copy_n(i256* %[[T02]], i256* %[[T01]], i32 2)
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = getelementptr [4 x i256], [4 x i256]* %overwrite_0_arena, i32 0, i32 2
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 3
//CHECK-NEXT:   call void @fr_copy_n(i256* %[[T04]], i256* %[[T03]], i32 2)
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = bitcast [4 x i256]* %overwrite_0_arena to i256*
//CHECK-NEXT:   %call.overwrite_0 = call i256 @overwrite_0(i256* %[[T05]])
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %call.overwrite_0, i256* %[[T06]], align 4
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T06]], align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %call.overwrite_0, i256 %[[T07]], i1* %constraint)
//CHECK-NEXT:   br label %log3
//CHECK-EMPTY:
//CHECK-NEXT: log3:
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY:
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
