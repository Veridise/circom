pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// %0 (i.e. signal arena) = [ a[0], a[1] ]
// %lvars = [ n, b[0], b[1], i, j ]
// %subcmps = []
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
//unrolled code:
//	b[0] = b[0] + a[0];     //extracted function 1; call 1
//	b[1] = b[1] + a[1];     //extracted function 1; call 2
//	b[1] = b[1] + a[1];     //extracted function 1; call 2
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME:  [[$F_ID_1:[0-9a-zA-Z_\.]+]]([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %var_0, i256* %var_1, i256* %sig_2){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %[[T00]], align 4
//CHECK-NEXT:   br label %unrolled_loop2
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop2:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_0, i32 0
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_1, i32 0
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T02]], align 4
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_2, i32 0
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T04]], align 4
//CHECK-NEXT:   %[[T97:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T03]], i256 %[[T05]])
//CHECK-NEXT:   store i256 %[[T97]], i256* %[[T01]], align 4
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T07]], align 4
//CHECK-NEXT:   %[[T98:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T08]], i256 1)
//CHECK-NEXT:   store i256 %[[T98]], i256* %[[T06]], align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T10]], align 4
//CHECK-NEXT:   %[[T99:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T11]], i256 1)
//CHECK-NEXT:   store i256 %[[T99]], i256* %[[T09]], align 4
//CHECK-NEXT:   br label %return4
//CHECK-EMPTY: 
//CHECK-NEXT: return4:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME:  [[$F_ID_2:[0-9a-zA-Z_\.]+]]([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %var_0, i256* %var_1, i256* %sig_2){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %[[T00]], align 4
//CHECK-NEXT:   br label %unrolled_loop2
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop2:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_0, i32 0
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T01]] to [0 x i256]*
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T02]], i32 0, i256 0
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_1, i32 0
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T04]] to [0 x i256]*
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T05]], i32 0, i256 0
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_2, i32 0
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T07]] to [0 x i256]*
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T08]], i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_3:[0-9a-zA-Z_\.]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %[[T03]], i256* %[[T06]], i256* %[[T09]])
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_0, i32 0
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T10]] to [0 x i256]*
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T11]], i32 0, i256 0
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_1, i32 0
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T13]] to [0 x i256]*
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T14]], i32 0, i256 0
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_2, i32 0
//CHECK-NEXT:   %[[T17:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T16]] to [0 x i256]*
//CHECK-NEXT:   %[[T18:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T17]], i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_3]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %[[T12]], i256* %[[T15]], i256* %[[T18]])
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T19:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %[[T20:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %[[T21:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T20]], align 4
//CHECK-NEXT:   %[[T97:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T21]], i256 1)
//CHECK-NEXT:   store i256 %[[T97]], i256* %[[T19]], align 4
//CHECK-NEXT:   br label %return4
//CHECK-EMPTY: 
//CHECK-NEXT: return4:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME:  [[$F_ID_3]]([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %subsig_0, i256* %subsig_1, i256* %subsig_2){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_3]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subsig_0, i32 0
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subsig_1, i32 0
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T01]], align 4
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subsig_2, i32 0
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T03]], align 4
//CHECK-NEXT:   %[[T97:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T02]], i256 %[[T04]])
//CHECK-NEXT:   store i256 %[[T97]], i256* %[[T00]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T06]], align 4
//CHECK-NEXT:   %[[T98:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T07]], i256 1)
//CHECK-NEXT:   store i256 %[[T98]], i256* %[[T05]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @InnerLoops_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[T00:[0-9a-zA-Z_\.]+]]){{.*}} {
//CHECK:      unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = bitcast [5 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = bitcast [5 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T06]], i32 0, i256 1
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = bitcast [5 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T08]], i32 0, i256 1
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T00]], i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T05]], [0 x i256]* %[[T00]], i256* %[[T07]], i256* %[[T09]], i256* %[[T10]])
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = bitcast [5 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = bitcast [5 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T12]], i32 0, i256 2
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_\.]+]] = bitcast [5 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T14]], i32 0, i256 2
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T00]], i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T11]], [0 x i256]* %[[T00]], i256* %[[T13]], i256* %[[T15]], i256* %[[T16]])
//CHECK-NEXT:   br label %prologue
