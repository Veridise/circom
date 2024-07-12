pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template InnerLoops(N) {
    signal output out;
    var a = 0;
    var b = 1000;
    for (var i = 0; i < N; i++) {
        b += a;
        for (var j = 0; j < N; j++) {
            a += 99;
        }
        b -= 5;
    }
    out <-- a;
}

component main = InnerLoops(2);

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME:  [[$F_ID_0:[0-9a-zA-Z_\.]+]]([0 x i256]* %lvars, [0 x i256]* %signals){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_0]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T01]], align 4
//CHECK-NEXT:   %[[T97:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T02]], i256 99)
//CHECK-NEXT:   store i256 %[[T97]], i256* %[[T00]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T04]], align 4
//CHECK-NEXT:   %[[T98:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T05]], i256 1)
//CHECK-NEXT:   store i256 %[[T98]], i256* %[[T03]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME:  [[$F_ID_1:[0-9a-zA-Z_\.]+]]([0 x i256]* %lvars, [0 x i256]* %signals){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T01]], align 4
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T03]], align 4
//CHECK-NEXT:   %[[T97:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T02]], i256 %[[T04]])
//CHECK-NEXT:   store i256 %[[T97]], i256* %[[T00]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %[[T05]], align 4
//CHECK-NEXT:   br label %unrolled_loop3
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop3:
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_0]]([0 x i256]* %lvars, [0 x i256]* %signals)
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_0]]([0 x i256]* %lvars, [0 x i256]* %signals)
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T15]], align 4
//CHECK-NEXT:   %[[T96:[0-9a-zA-Z_\.]+]] = call i256 @fr_sub(i256 %[[T16]], i256 5)
//CHECK-NEXT:   store i256 %[[T96]], i256* %[[T14]], align 4
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %[[T17:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %[[T18:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %[[T19:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T18]], align 4
//CHECK-NEXT:   %[[T99:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T19]], i256 1)
//CHECK-NEXT:   store i256 %[[T99]], i256* %[[T17]], align 4
//CHECK-NEXT:   br label %return6
//CHECK-EMPTY: 
//CHECK-NEXT: return6:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @InnerLoops_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [5 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 2, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T02]], align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 1000, i256* %[[T03]], align 4
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 0, i256* %[[T04]], align 4
//CHECK-NEXT:   br label %unrolled_loop5
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop5:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = bitcast [5 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T05]], [0 x i256]* %0)
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = bitcast [5 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T06]], [0 x i256]* %0)
//CHECK-NEXT:   br label %store6
//CHECK-EMPTY: 
//CHECK-NEXT: store6:
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 396, i256* %[[T07]], align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
