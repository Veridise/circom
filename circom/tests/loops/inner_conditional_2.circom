pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// if condition is known constant
template InnerConditional2(N, T) {
    signal output out;

    var acc = 1;
    for (var i = 1; i <= N; i++) {
        if (T == 0) {
            acc += i;
        } else {
            acc *= i;
        }
    }

    out <-- acc;
}

template runner() {
    signal output out;

    component a = InnerConditional2(4, 0);
    component b = InnerConditional2(5, 1);

    out <-- a.out + b.out;
}

component main = runner();

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T00]], align 4
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T02]], align 4
//CHECK-NEXT:   %[[C01:[0-9a-zA-Z_.]+]] = call i256 @fr_add(i256 %[[T01]], i256 %[[T03]])
//CHECK-NEXT:   store i256 %[[C01]], i256* %[[T04]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T05]], align 4
//CHECK-NEXT:   %[[C02:[0-9a-zA-Z_.]+]] = call i256 @fr_add(i256 %[[T06]], i256 1)
//CHECK-NEXT:   store i256 %[[C02]], i256* %[[T07]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_2:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T00]], align 4
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T02]], align 4
//CHECK-NEXT:   %[[C01:[0-9a-zA-Z_.]+]] = call i256 @fr_mul(i256 %[[T01]], i256 %[[T03]])
//CHECK-NEXT:   store i256 %[[C01]], i256* %[[T04]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T05]], align 4
//CHECK-NEXT:   %[[C02:[0-9a-zA-Z_.]+]] = call i256 @fr_add(i256 %[[T06]], i256 1)
//CHECK-NEXT:   store i256 %[[C02]], i256* %[[T07]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @InnerConditional2_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [4 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = getelementptr [4 x i256], [4 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 4, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = getelementptr [4 x i256], [4 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T02]], align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = getelementptr [4 x i256], [4 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 1, i256* %[[T03]], align 4
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = getelementptr [4 x i256], [4 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 1, i256* %[[T04]], align 4
//CHECK-NEXT:   br label %unrolled_loop5
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop5:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = bitcast [4 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T05]], [0 x i256]* %0)
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = bitcast [4 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T06]], [0 x i256]* %0)
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = bitcast [4 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T07]], [0 x i256]* %0)
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_.]+]] = bitcast [4 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T08]], [0 x i256]* %0)
//CHECK-NEXT:   br label %store6
//CHECK-EMPTY: 
//CHECK-NEXT: store6:
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 11, i256* %[[T09]], align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @InnerConditional2_1_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [4 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = getelementptr [4 x i256], [4 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 5, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = getelementptr [4 x i256], [4 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 1, i256* %[[T02]], align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = getelementptr [4 x i256], [4 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 1, i256* %[[T03]], align 4
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = getelementptr [4 x i256], [4 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 1, i256* %[[T04]], align 4
//CHECK-NEXT:   br label %unrolled_loop5
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop5:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = bitcast [4 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T05]], [0 x i256]* %0)
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = bitcast [4 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T06]], [0 x i256]* %0)
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = bitcast [4 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T07]], [0 x i256]* %0)
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_.]+]] = bitcast [4 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T08]], [0 x i256]* %0)
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_.]+]] = bitcast [4 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T09]], [0 x i256]* %0)
//CHECK-NEXT:   br label %store6
//CHECK-EMPTY: 
//CHECK-NEXT: store6:
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 120, i256* %[[T10]], align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @runner_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [0 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [2 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %create_cmp1
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0
//CHECK-NEXT:   call void @InnerConditional2_0_build({ [0 x i256]*, i32 }* %[[T01]])
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T02]], align 8
//CHECK-NEXT:   call void @InnerConditional2_0_run([0 x i256]* %[[T03]])
//CHECK-NEXT:   br label %create_cmp2
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp2:
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1
//CHECK-NEXT:   call void @InnerConditional2_0_build({ [0 x i256]*, i32 }* %[[T04]])
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T05]], align 8
//CHECK-NEXT:   call void @InnerConditional2_1_run([0 x i256]* %[[T06]])
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T07]], align 8
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T08]], i32 0, i32 0
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T09]], align 4
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T11]], align 8
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T12]], i32 0, i32 0
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T13]], align 4
//CHECK-NEXT:   %[[C01:[0-9a-zA-Z_.]+]] = call i256 @fr_add(i256 %[[T10]], i256 %[[T14]])
//CHECK-NEXT:   store i256 %[[C01]], i256* %[[T15]], align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
