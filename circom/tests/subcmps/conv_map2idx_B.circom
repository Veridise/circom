pragma circom 2.0.3;

// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template GetWeight(A, B) {
    signal output x;    //signal index 0
    signal output y;    //signal index 1
    signal output out;  //signal index 2
    out <-- A;
}

template ComputeValue() {
    component ws[2];
    ws[0] = GetWeight(999, 0);
    ws[1] = GetWeight(888, 1);

    signal ret[2];
    ret[0] <== ws[0].out;
    ret[1] <== ws[1].out;
}

component main = ComputeValue();

//CHECK-LABEL: define{{.*}} void @GetWeight_0_build({ [0 x i256]*, i32 }* %0){{.*}} {
//CHECK-NEXT: main:
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_.]+]] = alloca [3 x i256], align 8
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_.]+]] = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 1
//CHECK-NEXT:   store i32 0, i32* %[[T002]], align 4
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_.]+]] = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 0
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_.]+]] = bitcast [3 x i256]* %[[T001]] to [0 x i256]*
//CHECK-NEXT:   store [0 x i256]* %[[T004]], [0 x i256]** %[[T003]], align 8
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @GetWeight_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [2 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 999, i256* %[[T001]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T002]], align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 2
//CHECK-NEXT:   store i256 999, i256* %[[T003]], align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @GetWeight_1_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [2 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 888, i256* %[[T001]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 1, i256* %[[T002]], align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 2
//CHECK-NEXT:   store i256 888, i256* %[[T003]], align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @ComputeValue_2_build({ [0 x i256]*, i32 }* %0){{.*}} {
//CHECK-NEXT: main:
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_.]+]] = alloca [2 x i256], align 8
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_.]+]] = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 1
//CHECK-NEXT:   store i32 0, i32* %[[T002]], align 4
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_.]+]] = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 0
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_.]+]] = bitcast [2 x i256]* %[[T001]] to [0 x i256]*
//CHECK-NEXT:   store [0 x i256]* %[[T004]], [0 x i256]** %[[T003]], align 8
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @ComputeValue_2_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [0 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [2 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %create_cmp1
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp1:
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0
//CHECK-NEXT:   call void @GetWeight_0_build({ [0 x i256]*, i32 }* %[[T001]])
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T002]], align 8
//CHECK-NEXT:   call void @GetWeight_0_run([0 x i256]* %[[T003]])
//CHECK-NEXT:   br label %create_cmp2
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp2:
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1
//CHECK-NEXT:   call void @GetWeight_0_build({ [0 x i256]*, i32 }* %[[T004]])
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T006:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T005]], align 8
//CHECK-NEXT:   call void @GetWeight_1_run([0 x i256]* %[[T006]])
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T011:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   %[[T007:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T008:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T007]], align 8
//CHECK-NEXT:   %[[T009:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T008]], i32 0, i32 2
//CHECK-NEXT:   %[[T010:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T009]], align 4
//CHECK-NEXT:   store i256 %[[T010]], i256* %[[T011]], align 4
//CHECK-NEXT:   %[[T012:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T011]], align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T010]], i256 %[[T012]], i1* %constraint)
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %[[T017:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:   %[[T013:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T014:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T013]], align 8
//CHECK-NEXT:   %[[T015:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T014]], i32 0, i32 2
//CHECK-NEXT:   %[[T016:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T015]], align 4
//CHECK-NEXT:   store i256 %[[T016]], i256* %[[T017]], align 4
//CHECK-NEXT:   %[[T018:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T017]], align 4
//CHECK-NEXT:   %constraint1 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T016]], i256 %[[T018]], i1* %constraint1)
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
