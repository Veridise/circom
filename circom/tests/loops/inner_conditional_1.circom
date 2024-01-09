pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// IF condition can be known via in-place unrolling but not when body is extracted to a new function
template InnerConditional1(N) {
    signal output out;

    var acc = 0;
    for (var i = 1; i <= N; i++) {
        if (i < 5) {
            acc += i;
        } else {
            acc -= i;
        }
    }
    //Values at loop header per iteration
    //  N, acc, i
    // 10,   0, 1
    // 10,   1, 2
    // 10,   3, 3
    // 10,   6, 4
    // 10,  10, 5
    // 10,   5, 6
    // 10,  -1, 7
    // 10,  -8, 8
    // 10, -16, 9
    // 10, -25, 10

    out <-- acc;
}

component main = InnerConditional1(10);

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}.T([0 x i256]* %lvars, [0 x i256]* %signals){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9]+\.T]]:
//CHECK-NEXT:   br label %fold_true1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_true1:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T00]], align 4
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T02]], align 4
//CHECK-NEXT:   %[[C01:[0-9a-zA-Z_.]+]] = call i256 @fr_add(i256 %[[T01]], i256 %[[T03]])
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 %[[C01]], i256* %[[T04]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T05]], align 4
//CHECK-NEXT:   %[[C02:[0-9a-zA-Z_.]+]] = call i256 @fr_add(i256 %[[T06]], i256 1)
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 %[[C02]], i256* %[[T07]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}.F([0 x i256]* %lvars, [0 x i256]* %signals){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2:[0-9]+\.F]]:
//CHECK-NEXT:   br label %fold_false1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_false1:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T00]], align 4
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T02]], align 4
//CHECK-NEXT:   %[[C01:[0-9a-zA-Z_.]+]] = call i256 @fr_sub(i256 %[[T01]], i256 %[[T03]])
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 %[[C01]], i256* %[[T04]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T05]], align 4
//CHECK-NEXT:   %[[C02:[0-9a-zA-Z_.]+]] = call i256 @fr_add(i256 %[[T06]], i256 1)
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 %[[C02]], i256* %[[T07]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
// 
//CHECK-LABEL: define{{.*}} void @InnerConditional1_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [3 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 10, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T02]], align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 1, i256* %[[T03]], align 4
//CHECK-NEXT:   br label %unrolled_loop4
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop4:
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T04]], [0 x i256]* %0)
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T05]], [0 x i256]* %0)
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T06]], [0 x i256]* %0)
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T07]], [0 x i256]* %0)
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T08]], [0 x i256]* %0)
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T09]], [0 x i256]* %0)
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T10]], [0 x i256]* %0)
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T11]], [0 x i256]* %0)
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T12]], [0 x i256]* %0)
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T13]], [0 x i256]* %0)
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 21888242871839275222246405745257275088548364400416034343698204186575808495582, i256* %[[T14]], align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
