pragma circom 2.1.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function sum(a, b) {
    b[0] = a[1];
    b[1] = a[0];
    return b;
}

template CallArgTest() {
    signal input x[2][3];
    signal output z[2][3];

    var y[2][3];
    z <-- sum(x, y);
}

component main = CallArgTest();

//CHECK-LABEL: define{{.*}} i256* @sum_0(i256* %0){{.*}} {
//CHECK:      store1:
//CHECK:        %[[T03:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 6
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 3
//CHECK-NEXT:   call void @fr_copy_n(i256* %[[T04]], i256* %[[T03]], i32 3)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY:
//CHECK:      store2:
//CHECK:        %[[T07:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 9
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   call void @fr_copy_n(i256* %[[T08]], i256* %[[T07]], i32 3)
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY:
//CHECK-NEXT: return3:
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 6
//CHECK-NEXT:   ret i256* %[[T09]]
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @CallArgTest_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [9 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY:
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = getelementptr [9 x i256], [9 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 0, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY:
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = getelementptr [9 x i256], [9 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   store i256 0, i256* %[[T02]], align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY:
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = getelementptr [9 x i256], [9 x i256]* %lvars, i32 0, i32 8
//CHECK-NEXT:   store i256 0, i256* %[[T03]], align 4
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY:
//CHECK-NEXT: store4:
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = getelementptr [9 x i256], [9 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = getelementptr [9 x i256], [9 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   call void @fr_copy_n(i256* %[[T07]], i256* %[[T06]], i32 3)
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY:
//CHECK-NEXT: store5:
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_.]+]] = getelementptr [9 x i256], [9 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_.]+]] = getelementptr [9 x i256], [9 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   call void @fr_copy_n(i256* %[[T11]], i256* %[[T10]], i32 3)
//CHECK-NEXT:   br label %call6
//CHECK-EMPTY:
//CHECK-NEXT: call6:
//CHECK-NEXT:   %sum_0_arena = alloca [12 x i256], align 8
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_.]+]] = getelementptr [12 x i256], [12 x i256]* %sum_0_arena, i32 0, i32 0
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 6
//CHECK-NEXT:   call void @fr_copy_n(i256* %[[T13]], i256* %[[T12]], i32 6)
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_.]+]] = getelementptr [12 x i256], [12 x i256]* %sum_0_arena, i32 0, i32 6
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_.]+]] = getelementptr [9 x i256], [9 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   call void @fr_copy_n(i256* %[[T15]], i256* %[[T14]], i32 6)
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_.]+]] = bitcast [12 x i256]* %sum_0_arena to i256*
//CHECK-NEXT:   %call.sum_0 = call i256* @sum_0(i256* %[[T16]])
//CHECK-NEXT:   %[[T17:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   call void @fr_copy_n(i256* %call.sum_0, i256* %[[T17]], i32 6)
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY:
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
