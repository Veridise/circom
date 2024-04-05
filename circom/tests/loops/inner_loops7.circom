pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template InnerLoops(n) {
    signal input a[n];
    var b[n];

    for (var i = 0; i < n; i++) {
        for (var j = 0; j <= i; j++) {
            // NOTE: When processing the outer loop, the following statement is safe to move
            //  into a new function since it does NOT use 'j'. That results in the outer loop
            //  body (i.e. the entire inner loop) being extracted to a new function. Since the
            //  iteration count of the inner loop is different per each iteration of the outer
            //  loop, it cannot be unrolled within the extracted function.
            b[i] += a[i];
        }
    }
}

component main = InnerLoops(2);
//
// %[[T00]] (i.e. signal arena) = { a[0], a[1] }
// %lvars = { n, b[0], b[1], i, j }
//
//unrolled code:
//	b[0] = b[0] + a[0];     //extracted function 1; call 1
//	b[1] = b[1] + a[1];     //extracted function 1; call 2
//	b[1] = b[1] + a[1];     //extracted function 1; call 2
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %var_0, i256* %var_1, i256* %sig_2){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK:      loop2:
//CHECK-NEXT:   br label %loop.cond
//CHECK-EMPTY: 
//CHECK-NEXT: loop.cond:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T01]], align 4
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T03]], align 4
//CHECK-NEXT:   %call.fr_le = call i1 @fr_le(i256 %[[T02]], i256 %[[T04]])
//CHECK-NEXT:   br i1 %call.fr_le, label %loop.body, label %loop.end
//CHECK-EMPTY: 
//CHECK-NEXT: loop.body:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %var_0, i32 0
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %var_1, i32 0
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T06]], align 4
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %sig_2, i32 0
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T08]], align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %[[T07]], i256 %[[T09]])
//CHECK-NEXT:   store i256 %call.fr_add, i256* %[[T05]], align 4
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T11]], align 4
//CHECK-NEXT:   %call.fr_add1 = call i256 @fr_add(i256 %[[T12]], i256 1)
//CHECK-NEXT:   store i256 %call.fr_add1, i256* %[[T10]], align 4
//CHECK-NEXT:   br label %loop.cond
//CHECK-EMPTY: 
//CHECK-NEXT: loop.end:
//CHECK-NEXT:   br label %store6
//CHECK-EMPTY: 
//CHECK-NEXT: store6:
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T14]], align 4
//CHECK-NEXT:   %call.fr_add2 = call i256 @fr_add(i256 %[[T15]], i256 1)
//CHECK-NEXT:   store i256 %call.fr_add2, i256* %[[T13]], align 4
//CHECK-NEXT:   br label %return7
//CHECK-EMPTY: 
//CHECK-NEXT: return7:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @InnerLoops_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[T00:[0-9a-zA-Z_.]+]]){{.*}} {
//CHECK:      unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = bitcast [5 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = bitcast [5 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T06]], i32 0, i256 1
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_.]+]] = bitcast [5 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T08]], i32 0, i256 1
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T00]], i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T05]], [0 x i256]* %[[T00]], i256* %[[T07]], i256* %[[T09]], i256* %[[T10]])
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_.]+]] = bitcast [5 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_.]+]] = bitcast [5 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T12]], i32 0, i256 2
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_.]+]] = bitcast [5 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T14]], i32 0, i256 2
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T00]], i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T11]], [0 x i256]* %[[T00]], i256* %[[T13]], i256* %[[T15]], i256* %[[T16]])
//CHECK-NEXT:   br label %prologue
