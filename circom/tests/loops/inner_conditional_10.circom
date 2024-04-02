pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template Sigma() {
    signal input inp;
    signal output out;
}

template Poseidon() {
    signal input inp;

    component sigmaF[2];

    // NOTE: When processing the loop, the statements indexed with 'k' are determined
    //  NOT safe to move into a new function since 'k' is unknown. That results in
    //  the loop unrolling in place.
    for (var i=0; i<4; i++) {
        if (i < 1 || i >= 3) {
            var k = i < 1 ? 0 : 1;
            sigmaF[k] = Sigma();
            sigmaF[k].inp <== inp;
        }
    }
}

component main = Poseidon();

//CHECK-LABEL: define{{.*}} void @Poseidon_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [2 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [2 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %create_cmp1
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0
//CHECK-NEXT:   call void @Sigma_0_build({ [0 x i256]*, i32 }* %[[T01]])
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1
//CHECK-NEXT:   call void @Sigma_0_build({ [0 x i256]*, i32 }* %[[T02]])
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 0, i256* %[[T03]], align 4
//CHECK-NEXT:   br label %unrolled_loop3
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop3:
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T04]], align 4
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T07]], align 8
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T08]], i32 0, i32 1
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T05]], align 4
//CHECK-NEXT:   store i256 %[[T06]], i256* %[[T09]], align 4
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %load.subcmp.counter = load i32, i32* %[[T10]], align 4
//CHECK-NEXT:   %decrement.counter = sub i32 %load.subcmp.counter, 1
//CHECK-NEXT:   store i32 %decrement.counter, i32* %[[T10]], align 4
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T11]], align 8
//CHECK-NEXT:   call void @Sigma_0_run([0 x i256]* %[[T12]])
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T09]], align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T06]], i256 %[[T13]], i1* %constraint)
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 1, i256* %[[T14]], align 4
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 2, i256* %[[T15]], align 4
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 3, i256* %[[T16]], align 4
//CHECK-NEXT:   %[[T17:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 1, i256* %[[T17]], align 4
//CHECK-NEXT:   %[[T20:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T21:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T20]], align 8
//CHECK-NEXT:   %[[T22:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T21]], i32 0, i32 1
//CHECK-NEXT:   %[[T18:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   %[[T19:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T18]], align 4
//CHECK-NEXT:   store i256 %[[T19]], i256* %[[T22]], align 4
//CHECK-NEXT:   %[[T23:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %load.subcmp.counter1 = load i32, i32* %[[T23]], align 4
//CHECK-NEXT:   %decrement.counter2 = sub i32 %load.subcmp.counter1, 1
//CHECK-NEXT:   store i32 %decrement.counter2, i32* %[[T23]], align 4
//CHECK-NEXT:   %[[T24:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T25:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T24]], align 8
//CHECK-NEXT:   call void @Sigma_0_run([0 x i256]* %[[T25]])
//CHECK-NEXT:   %[[T26:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T22]], align 4
//CHECK-NEXT:   %constraint3 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T19]], i256 %[[T26]], i1* %constraint3)
//CHECK-NEXT:   %[[T27:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 4, i256* %[[T27]], align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
