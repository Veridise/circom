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

//CHECK-LABEL: define void @GetWeight_0_build({ [0 x i256]*, i32 }* %0){{.*}} {
//CHECK-NEXT: main:
//CHECK-NEXT:   %1 = alloca [3 x i256], align 8
//CHECK-NEXT:   %2 = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 1
//CHECK-NEXT:   store i32 0, i32* %2, align 4
//CHECK-NEXT:   %3 = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 0
//CHECK-NEXT:   %4 = bitcast [3 x i256]* %1 to [0 x i256]*
//CHECK-NEXT:   store [0 x i256]* %4, [0 x i256]** %3, align 8
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @GetWeight_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [2 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 999, i256* %1, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %2 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %2, align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 2
//CHECK-NEXT:   store i256 999, i256* %3, align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @GetWeight_1_build({ [0 x i256]*, i32 }* %0){{.*}} {
//CHECK-NEXT: main:
//CHECK-NEXT:   %1 = alloca [3 x i256], align 8
//CHECK-NEXT:   %2 = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 1
//CHECK-NEXT:   store i32 0, i32* %2, align 4
//CHECK-NEXT:   %3 = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 0
//CHECK-NEXT:   %4 = bitcast [3 x i256]* %1 to [0 x i256]*
//CHECK-NEXT:   store [0 x i256]* %4, [0 x i256]** %3, align 8
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @GetWeight_1_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [2 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 888, i256* %1, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %2 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 1, i256* %2, align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 2
//CHECK-NEXT:   store i256 888, i256* %3, align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @ComputeValue_2_build({ [0 x i256]*, i32 }* %0){{.*}} {
//CHECK-NEXT: main:
//CHECK-NEXT:   %1 = alloca [2 x i256], align 8
//CHECK-NEXT:   %2 = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 1
//CHECK-NEXT:   store i32 0, i32* %2, align 4
//CHECK-NEXT:   %3 = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 0
//CHECK-NEXT:   %4 = bitcast [2 x i256]* %1 to [0 x i256]*
//CHECK-NEXT:   store [0 x i256]* %4, [0 x i256]** %3, align 8
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @ComputeValue_2_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [0 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [2 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %create_cmp1
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp1:
//CHECK-NEXT:   %1 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0
//CHECK-NEXT:   call void @GetWeight_0_build({ [0 x i256]*, i32 }* %1)
//CHECK-NEXT:   %2 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %3 = load [0 x i256]*, [0 x i256]** %2, align 8
//CHECK-NEXT:   call void @GetWeight_0_run([0 x i256]* %3)
//CHECK-NEXT:   br label %create_cmp2
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp2:
//CHECK-NEXT:   %4 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1
//CHECK-NEXT:   call void @GetWeight_1_build({ [0 x i256]*, i32 }* %4)
//CHECK-NEXT:   %5 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %6 = load [0 x i256]*, [0 x i256]** %5, align 8
//CHECK-NEXT:   call void @GetWeight_1_run([0 x i256]* %6)
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %7 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %8 = load [0 x i256]*, [0 x i256]** %7, align 8
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %8, i32 0, i32 2
//CHECK-NEXT:   %10 = load i256, i256* %9, align 4
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %10, i256* %11, align 4
//CHECK-NEXT:   %12 = load i256, i256* %11, align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %10, i256 %12, i1* %constraint)
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %13 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %14 = load [0 x i256]*, [0 x i256]** %13, align 8
//CHECK-NEXT:   %15 = getelementptr [0 x i256], [0 x i256]* %14, i32 0, i32 2
//CHECK-NEXT:   %16 = load i256, i256* %15, align 4
//CHECK-NEXT:   %17 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:   store i256 %16, i256* %17, align 4
//CHECK-NEXT:   %18 = load i256, i256* %17, align 4
//CHECK-NEXT:   %constraint1 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %16, i256 %18, i1* %constraint1)
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
