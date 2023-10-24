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

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+\.F\.F}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9]+\.F\.F]]:
//CHECK-NEXT:   br label %fold_false1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_false1:
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %1, i256 1)
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 %call.fr_add, i256* %2, align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+\.F\.T}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2:[0-9]+\.F\.T]]:
//CHECK-NEXT:   br label %fold_false1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_false1:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr i256, i256* %fix_[[X2]], i32 0
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %1, i256 %3, i1* %constraint)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   %5 = load i256, i256* %4, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %5, i256 1)
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 %call.fr_add, i256* %6, align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+\.T}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_3:[0-9]+\.T]]:
//CHECK-NEXT:   br label %fold_true1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_true1:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr i256, i256* %fix_[[X1]], i32 0
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %1, i256 %3, i1* %constraint)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   %5 = load i256, i256* %4, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %5, i256 1)
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 %call.fr_add, i256* %6, align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
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
//CHECK-NEXT:   %1 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0
//CHECK-NEXT:   call void @Sigma_0_build({ [0 x i256]*, i32 }* %1)
//CHECK-NEXT:   %2 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1
//CHECK-NEXT:   call void @Sigma_0_build({ [0 x i256]*, i32 }* %2)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %3 = getelementptr [1 x i256], [1 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 0, i256* %3, align 4
//CHECK-NEXT:   br label %unrolled_loop3
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop3:
//CHECK-NEXT:   %4 = bitcast [1 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %5 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %6 = load [0 x i256]*, [0 x i256]** %5, align 8
//CHECK-NEXT:   %7 = getelementptr [0 x i256], [0 x i256]* %6, i32 0
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %7, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_3]]([0 x i256]* %4, [0 x i256]* %0, i256* %8, i256* null)
//CHECK-NEXT:   %9 = bitcast [1 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %9, [0 x i256]* %0, i256* null, i256* null)
//CHECK-NEXT:   %10 = bitcast [1 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %10, [0 x i256]* %0, i256* null, i256* null)
//CHECK-NEXT:   %11 = bitcast [1 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %12 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %13 = load [0 x i256]*, [0 x i256]** %12, align 8
//CHECK-NEXT:   %14 = getelementptr [0 x i256], [0 x i256]* %13, i32 0
//CHECK-NEXT:   %15 = getelementptr [0 x i256], [0 x i256]* %14, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %11, [0 x i256]* %0, i256* null, i256* %15)
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
