pragma circom 2.0.3;

// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template GetWeight(A) {
    signal input inp;
}

template ComputeValue() {
    component getWeights[2];

    getWeights[0] = GetWeight(0);
    getWeights[0].inp <-- 888;

    getWeights[1] = GetWeight(1);
    getWeights[1].inp <-- 999;
}

component main = ComputeValue();

//CHECK-LABEL: define void @GetWeight_0_build({ [0 x i256]*, i32 }* %0){{.*}} {
//CHECK-NEXT: main:
//CHECK-NEXT:   %1 = alloca [1 x i256], align 8
//CHECK-NEXT:   %2 = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 1
//CHECK-NEXT:   store i32 1, i32* %2, align 4
//CHECK-NEXT:   %3 = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 0
//CHECK-NEXT:   %4 = bitcast [1 x i256]* %1 to [0 x i256]*
//CHECK-NEXT:   store [0 x i256]* %4, [0 x i256]** %3, align 8
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @GetWeight_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [1 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr [1 x i256], [1 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 0, i256* %1, align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @GetWeight_1_build({ [0 x i256]*, i32 }* %0){{.*}} {
//CHECK-NEXT: main:
//CHECK-NEXT:   %1 = alloca [1 x i256], align 8
//CHECK-NEXT:   %2 = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 1
//CHECK-NEXT:   store i32 1, i32* %2, align 4
//CHECK-NEXT:   %3 = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 0
//CHECK-NEXT:   %4 = bitcast [1 x i256]* %1 to [0 x i256]*
//CHECK-NEXT:   store [0 x i256]* %4, [0 x i256]** %3, align 8
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @GetWeight_1_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [1 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr [1 x i256], [1 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 1, i256* %1, align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @ComputeValue_2_build({ [0 x i256]*, i32 }* %0){{.*}} {
//CHECK-NEXT: main:
//CHECK-NEXT:   %1 = alloca [0 x i256], align 8
//CHECK-NEXT:   %2 = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 1
//CHECK-NEXT:   store i32 0, i32* %2, align 4
//CHECK-NEXT:   %3 = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 0
//CHECK-NEXT:   store [0 x i256]* %1, [0 x i256]** %3, align 8
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
//CHECK-NEXT:   br label %create_cmp2
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp2:
//CHECK-NEXT:   %2 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1
//CHECK-NEXT:   call void @GetWeight_1_build({ [0 x i256]*, i32 }* %2)
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %3 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %4 = load [0 x i256]*, [0 x i256]** %3, align 8
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %4, i32 0, i32 0
//CHECK-NEXT:   store i256 888, i256* %5, align 4
//CHECK-NEXT:   %6 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %load.subcmp.counter = load i32, i32* %6, align 4
//CHECK-NEXT:   %decrement.counter = sub i32 %load.subcmp.counter, 1
//CHECK-NEXT:   store i32 %decrement.counter, i32* %6, align 4
//CHECK-NEXT:   %7 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %8 = load [0 x i256]*, [0 x i256]** %7, align 8
//CHECK-NEXT:   call void @GetWeight_0_run([0 x i256]* %8)
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %9 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %10 = load [0 x i256]*, [0 x i256]** %9, align 8
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %10, i32 0, i32 0
//CHECK-NEXT:   store i256 999, i256* %11, align 4
//CHECK-NEXT:   %12 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %load.subcmp.counter1 = load i32, i32* %12, align 4
//CHECK-NEXT:   %decrement.counter2 = sub i32 %load.subcmp.counter1, 1
//CHECK-NEXT:   store i32 %decrement.counter2, i32* %12, align 4
//CHECK-NEXT:   %13 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %14 = load [0 x i256]*, [0 x i256]** %13, align 8
//CHECK-NEXT:   call void @GetWeight_1_run([0 x i256]* %14)
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
