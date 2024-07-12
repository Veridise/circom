pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template Sigma() {
    signal input inp;
    signal output out;
}

// Equivalent to inner_conditional_10 but refactored to allow the loop body to be extracted to a new function. 
template Poseidon() {
    signal input inp;

    component sigmaF[2];

    for (var i=0; i<4; i++) {
        if (i < 1) {
            sigmaF[0] = Sigma();
            sigmaF[0].inp <== inp;
        } else if (i >= 3) {
            sigmaF[1] = Sigma();
            sigmaF[1].inp <== inp;
        }
    }
}

component main = Poseidon();

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9a-zA-Z_\.]+\.T\.T}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %subsig_[[X1:[0-9]+]], i256* %subsig_[[X2:[0-9]+]], [0 x i256]* %sub_[[X2]], i256* %subc_[[X2]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9a-zA-Z_\.]+\.T\.T]]:
//CHECK-NEXT:   br label %fold_true1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_true1:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subsig_[[X1]], i32 0
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 0
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T00]], align 4
//CHECK-NEXT:   store i256 %[[T01]], i256* %[[T02]], align 4
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T02]], align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T01]], i256 %[[T03]], i1* %constraint)
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subc_[[X2]], i32 0
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = load i256, i256* %subc_[[X2]], align 4
//CHECK-NEXT:   %[[C02:[0-9a-zA-Z_\.]+]] = call i256 @fr_sub(i256 %[[T04]], i256 1)
//CHECK-NEXT:   store i256 %[[C02]], i256* %[[T05]], align 4
//CHECK-NEXT:   call void @Sigma_0_run([0 x i256]* %sub_[[X2]])
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T06]], align 4
//CHECK-NEXT:   %[[C03:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T07]], i256 1)
//CHECK-NEXT:   store i256 %[[C03]], i256* %[[T08]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9a-zA-Z_\.]+\.F\.F}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %subsig_[[X1:[0-9]+]], i256* %subsig_[[X2:[0-9]+]], [0 x i256]* %sub_[[X2]], i256* %subc_[[X2]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2:[0-9a-zA-Z_\.]+\.F\.F]]:
//CHECK-NEXT:   br label %fold_false1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_false1:
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T00]], align 4
//CHECK-NEXT:   %[[C01:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T01]], i256 1)
//CHECK-NEXT:   store i256 %[[C01]], i256* %[[T02]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9a-zA-Z_\.]+\.F\.T\.T}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %subsig_[[X1:[0-9]+]], i256* %subsig_[[X2:[0-9]+]], [0 x i256]* %sub_[[X2]], i256* %subc_[[X2]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_3:[0-9a-zA-Z_\.]+\.F\.T\.T]]:
//CHECK-NEXT:   br label %fold_false1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_false1:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subsig_[[X2]], i32 0
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 0
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T00]], align 4
//CHECK-NEXT:   store i256 %[[T01]], i256* %[[T02]], align 4
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T02]], align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T01]], i256 %[[T03]], i1* %constraint)
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subc_[[X2]], i32 0
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = load i256, i256* %subc_[[X2]], align 4
//CHECK-NEXT:   %[[C04:[0-9a-zA-Z_\.]+]] = call i256 @fr_sub(i256 %[[T04]], i256 1)
//CHECK-NEXT:   store i256 %[[C04]], i256* %[[T05]], align 4
//CHECK-NEXT:   call void @Sigma_0_run([0 x i256]* %sub_[[X2]])
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T06]], align 4
//CHECK-NEXT:   %[[C05:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T07]], i256 1)
//CHECK-NEXT:   store i256 %[[C05]], i256* %[[T08]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @Sigma_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [0 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @Poseidon_1_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [1 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [2 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %create_cmp1
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0
//CHECK-NEXT:   call void @Sigma_0_build({ [0 x i256]*, i32 }* %[[T01]])
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1
//CHECK-NEXT:   call void @Sigma_0_build({ [0 x i256]*, i32 }* %[[T02]])
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [1 x i256], [1 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 0, i256* %[[T03]], align 4
//CHECK-NEXT:   br label %unrolled_loop3
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop3:
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = bitcast [1 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T05]], align 8
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T06]], i32 0
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T07]], i32 0, i256 1
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T09]], align 8
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T10]], i32 0
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_\.]+]] = bitcast i32* %[[T12]] to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T04]], [0 x i256]* %0, i256* %[[T08]], i256* null, [0 x i256]* %[[T11]], i256* %[[T13]])
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_\.]+]] = bitcast [1 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T14]], [0 x i256]* %0, i256* null, i256* null, [0 x i256]* null, i256* null)
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_\.]+]] = bitcast [1 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T15]], [0 x i256]* %0, i256* null, i256* null, [0 x i256]* null, i256* null)
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_\.]+]] = bitcast [1 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T17:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T18:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T17]], align 8
//CHECK-NEXT:   %[[T19:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T18]], i32 0
//CHECK-NEXT:   %[[T20:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T19]], i32 0, i256 1
//CHECK-NEXT:   %[[T21:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T22:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T21]], align 8
//CHECK-NEXT:   %[[T23:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T22]], i32 0
//CHECK-NEXT:   %[[T24:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %[[T25:[0-9a-zA-Z_\.]+]] = bitcast i32* %[[T24]] to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_3]]([0 x i256]* %[[T16]], [0 x i256]* %0, i256* null, i256* %[[T20]], [0 x i256]* %[[T23]], i256* %[[T25]])
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
