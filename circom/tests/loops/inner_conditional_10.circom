pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.* // TODO: branch conditions are not be flattened fully for some reason

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

//CHECK-LABEL: define void @Poseidon_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [2 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [2 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %create_cmp1
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp1:
//CHECK-NEXT:   %1 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0
//CHECK-NEXT:   call void @Sigma_0_build({ [0 x i256]*, i32 }* %1)
//CHECK-NEXT:   %2 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1
//CHECK-NEXT:   call void @Sigma_0_build({ [0 x i256]*, i32 }* %2)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %3 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 0, i256* %3, align 4
//CHECK-NEXT:   br label %unrolled_loop3
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop3:
//CHECK-NEXT:   %4 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %4, align 4
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   %6 = load i256, i256* %5, align 4
//CHECK-NEXT:   %7 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %8 = load [0 x i256]*, [0 x i256]** %7, align 8
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %8, i32 0, i32 1
//CHECK-NEXT:   store i256 %6, i256* %9, align 4
//CHECK-NEXT:   %10 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %load.subcmp.counter = load i32, i32* %10, align 4
//CHECK-NEXT:   %decrement.counter = sub i32 %load.subcmp.counter, 1
//CHECK-NEXT:   store i32 %decrement.counter, i32* %10, align 4
//CHECK-NEXT:   %11 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %12 = load [0 x i256]*, [0 x i256]** %11, align 8
//CHECK-NEXT:   call void @Sigma_0_run([0 x i256]* %12)
//CHECK-NEXT:   %13 = load i256, i256* %9, align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %6, i256 %13, i1* %constraint)
//CHECK-NEXT:   %14 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 1, i256* %14, align 4
//CHECK-NEXT:   %15 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 2, i256* %15, align 4
//CHECK-NEXT:   %16 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 3, i256* %16, align 4
//CHECK-NEXT:   %17 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 1, i256* %17, align 4
//CHECK-NEXT:   %18 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   %19 = load i256, i256* %18, align 4
//CHECK-NEXT:   %20 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %21 = load [0 x i256]*, [0 x i256]** %20, align 8
//CHECK-NEXT:   %22 = getelementptr [0 x i256], [0 x i256]* %21, i32 0, i32 1
//CHECK-NEXT:   store i256 %19, i256* %22, align 4
//CHECK-NEXT:   %23 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %load.subcmp.counter1 = load i32, i32* %23, align 4
//CHECK-NEXT:   %decrement.counter2 = sub i32 %load.subcmp.counter1, 1
//CHECK-NEXT:   store i32 %decrement.counter2, i32* %23, align 4
//CHECK-NEXT:   %24 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %25 = load [0 x i256]*, [0 x i256]** %24, align 8
//CHECK-NEXT:   call void @Sigma_0_run([0 x i256]* %25)
//CHECK-NEXT:   %26 = load i256, i256* %22, align 4
//CHECK-NEXT:   %constraint3 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %19, i256 %26, i1* %constraint3)
//CHECK-NEXT:   %27 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 4, i256* %27, align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
