pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// if condition can be known via unrolling, arrays used inside indexed on iteration variable
template InnerConditional4(N) {
    signal output out[N];
    signal input in;

    for (var i = 0; i < N; i++) {
        if (i < 3) {
            out[i] <-- -in;
        } else {
            out[i] <-- in;
        }
    }
}

component main = InnerConditional4(6);

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}.T([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %sig_[[X1:[0-9]+]], i256* %sig_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9]+\.T]]:
//CHECK-NEXT:   br label %fold_true1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_true1:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_[[X1]], i32 0
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 6
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T00]], align 4
//CHECK-NEXT:   %[[C01:[0-9a-zA-Z_\.]+]] = call i256 @fr_neg(i256 %[[T01]])
//CHECK-NEXT:   store i256 %[[C01]], i256* %[[T02]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T03]], align 4
//CHECK-NEXT:   %[[C02:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T04]], i256 1)
//CHECK-NEXT:   store i256 %[[C02]], i256* %[[T05]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}.F([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %sig_[[X1:[0-9]+]], i256* %sig_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2:[0-9]+\.F]]:
//CHECK-NEXT:   br label %fold_false1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_false1:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_[[X2]], i32 0
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 6
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T00]], align 4
//CHECK-NEXT:   store i256 %[[T01]], i256* %[[T02]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T03]], align 4
//CHECK-NEXT:   %[[C01:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T04]], i256 1)
//CHECK-NEXT:   store i256 %[[C01]], i256* %[[T05]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @InnerConditional4_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [2 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 6, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T02]], align 4
//CHECK-NEXT:   br label %unrolled_loop3
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop3:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T03]], [0 x i256]* %0, i256* %[[T04]], i256* null)
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T05]], [0 x i256]* %0, i256* %[[T06]], i256* null)
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T07]], [0 x i256]* %0, i256* %[[T08]], i256* null)
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T09]], [0 x i256]* %0, i256* null, i256* %[[T10]])
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 4
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T11]], [0 x i256]* %0, i256* null, i256* %[[T12]])
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_\.]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 5
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T13]], [0 x i256]* %0, i256* null, i256* %[[T14]])
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
