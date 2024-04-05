pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// lvars = [ N, a[0], a[1], a[2], a[3], i, j ]
template InnerConditional9(N) {
    signal output out;

    var a[N];
    for (var i = 0; i < N; i++) {
        // Values of 'a' at the header per iteration:
        // i=0: [0, 0, 0, 0]
        // i=1: [3996, 0, 0, 0]
        // i=2: [3996, 3996, 0, 0]
        // i=3: [3996, 3996, 3552, 0]
        if (i < 2) {
            // runs when i∈{0,1}
            for (var j = 0; j < N; j++) {
                a[i] += 999;
            }
        } else {
            // runs when i∈{2,3}
            for (var j = 0; j < N; j++) {
                a[i] += 888;
            }
        }
    }
    // At this point, 'a = [3996, 3996, 3552, 3552]', so 'out = 7992'
    out <-- a[0] + a[1];
}

component main = InnerConditional9(4);

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}.T([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %var_[[X1:[0-9]+]], i256* %var_[[X2:[0-9]+]], i256* %var_[[X3:[0-9]+]], i256* %var_[[X4:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9]+\.T]]:
//CHECK-NEXT:   br label %fold_true1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_true1:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 0, i256* %[[T00]], align 4
//CHECK-NEXT:   br label %loop.cond
//CHECK-EMPTY: 
//CHECK-NEXT: loop.cond:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T01]], align 4
//CHECK-NEXT:   %[[C01:[0-9a-zA-Z_.]+]] = call i1 @fr_lt(i256 %[[T02]], i256 4)
//CHECK-NEXT:   br i1 %[[C01]], label %loop.body, label %loop.end
//CHECK-EMPTY: 
//CHECK-NEXT: loop.body:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %var_[[X1]], i32 0
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %var_[[X2]], i32 0
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T03]], align 4
//CHECK-NEXT:   %[[C02:[0-9a-zA-Z_.]+]] = call i256 @fr_add(i256 %[[T04]], i256 999)
//CHECK-NEXT:   store i256 %[[C02]], i256* %[[T05]], align 4
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T06]], align 4
//CHECK-NEXT:   %[[C03:[0-9a-zA-Z_.]+]] = call i256 @fr_add(i256 %[[T07]], i256 1)
//CHECK-NEXT:   store i256 %[[C03]], i256* %[[T08]], align 4
//CHECK-NEXT:   br label %loop.cond
//CHECK-EMPTY: 
//CHECK-NEXT: loop.end:
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T09]], align 4
//CHECK-NEXT:   %[[C04:[0-9a-zA-Z_.]+]] = call i256 @fr_add(i256 %[[T10]], i256 1)
//CHECK-NEXT:   store i256 %[[C04]], i256* %[[T11]], align 4
//CHECK-NEXT:   br label %return6
//CHECK-EMPTY: 
//CHECK-NEXT: return6:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}.F([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %var_[[X1:[0-9]+]], i256* %var_[[X2:[0-9]+]], i256* %var_[[X3:[0-9]+]], i256* %var_[[X4:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2:[0-9]+\.F]]:
//CHECK-NEXT:   br label %fold_false1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_false1:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 0, i256* %[[T00]], align 4
//CHECK-NEXT:   br label %loop.cond
//CHECK-EMPTY: 
//CHECK-NEXT: loop.cond:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T01]], align 4
//CHECK-NEXT:   %[[C01:[0-9a-zA-Z_.]+]] = call i1 @fr_lt(i256 %[[T02]], i256 4)
//CHECK-NEXT:   br i1 %[[C01]], label %loop.body, label %loop.end
//CHECK-EMPTY: 
//CHECK-NEXT: loop.body:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %var_[[X3]], i32 0
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %var_[[X4]], i32 0
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T03]], align 4
//CHECK-NEXT:   %[[C02:[0-9a-zA-Z_.]+]] = call i256 @fr_add(i256 %[[T04]], i256 888)
//CHECK-NEXT:   store i256 %[[C02]], i256* %[[T05]], align 4
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T06]], align 4
//CHECK-NEXT:   %[[C03:[0-9a-zA-Z_.]+]] = call i256 @fr_add(i256 %[[T07]], i256 1)
//CHECK-NEXT:   store i256 %[[C03]], i256* %[[T08]], align 4
//CHECK-NEXT:   br label %loop.cond
//CHECK-EMPTY: 
//CHECK-NEXT: loop.end:
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T09]], align 4
//CHECK-NEXT:   %[[C04:[0-9a-zA-Z_.]+]] = call i256 @fr_add(i256 %[[T10]], i256 1)
//CHECK-NEXT:   store i256 %[[C04]], i256* %[[T11]], align 4
//CHECK-NEXT:   br label %return6
//CHECK-EMPTY: 
//CHECK-NEXT: return6:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @InnerConditional9_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [7 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 4, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T02]], align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 0, i256* %[[T03]], align 4
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 0, i256* %[[T04]], align 4
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %[[T05]], align 4
//CHECK-NEXT:   br label %store6
//CHECK-EMPTY: 
//CHECK-NEXT: store6:
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 0, i256* %[[T06]], align 4
//CHECK-NEXT:   br label %unrolled_loop7
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop7:
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T08]], i32 0, i256 1
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T10]], i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T07]], [0 x i256]* %0, i256* %[[T09]], i256* %[[T11]], i256* null, i256* null)
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T13]], i32 0, i256 2
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T15]], i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T12]], [0 x i256]* %0, i256* %[[T14]], i256* %[[T16]], i256* null, i256* null)
//CHECK-NEXT:   %[[T17:[0-9a-zA-Z_.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T18:[0-9a-zA-Z_.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T19:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T18]], i32 0, i256 3
//CHECK-NEXT:   %[[T20:[0-9a-zA-Z_.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T21:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T20]], i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T17]], [0 x i256]* %0, i256* null, i256* null, i256* %[[T19]], i256* %[[T21]])
//CHECK-NEXT:   %[[T22:[0-9a-zA-Z_.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T23:[0-9a-zA-Z_.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T24:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T23]], i32 0, i256 4
//CHECK-NEXT:   %[[T25:[0-9a-zA-Z_.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T26:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T25]], i32 0, i256 4
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T22]], [0 x i256]* %0, i256* null, i256* null, i256* %[[T24]], i256* %[[T26]])
//CHECK-NEXT:   br label %store8
//CHECK-EMPTY: 
//CHECK-NEXT: store8:
//CHECK-NEXT:   %[[T27:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 7992, i256* %[[T27]], align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
