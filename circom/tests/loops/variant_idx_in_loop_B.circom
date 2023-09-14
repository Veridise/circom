pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template VariantIndex(n) {
    signal input in;
    signal output out;

    var temp[n];
    for (var i = 0; i<n; i++) {
        temp[i] = (in >> i);
    }
    out <-- temp[0] + temp[1];
}

component main = VariantIndex(2);

// %0 (i.e. signal arena) = [ out, in ]
// %lvars =  [ n, temp[0], temp[1], i ]
// %subcmps = []
//
//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %fixed_0){{.*}} {
//CHECK:      store{{[0-9]+}}:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 1
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %call.fr_shr = call i256 @fr_shr(i256 %1, i256 %3)
//CHECK-NEXT:   %4 = getelementptr i256, i256* %fixed_0, i32 0
//CHECK-NEXT:   store i256 %call.fr_shr, i256* %4, align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %6 = load i256, i256* %5, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %6, i256 1)
//CHECK-NEXT:   %7 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 %call.fr_add, i256* %7, align 4
//CHECK-NEXT:   br label %return{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: return{{[0-9]+}}:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @VariantIndex_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9]+]])
//CHECK:      unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %5 = bitcast [4 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %6 = bitcast [4 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %7 = getelementptr [0 x i256], [0 x i256]* %6, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.{{.*}}[[$F_ID]]([0 x i256]* %5, [0 x i256]* %0, i256* %7)
//CHECK-NEXT:   %8 = bitcast [4 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %9 = bitcast [4 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %10 = getelementptr [0 x i256], [0 x i256]* %9, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.{{.*}}[[$F_ID]]([0 x i256]* %8, [0 x i256]* %0, i256* %10)
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %11 = getelementptr [4 x i256], [4 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %12 = load i256, i256* %11, align 4
//CHECK-NEXT:   %13 = getelementptr [4 x i256], [4 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %14 = load i256, i256* %13, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %12, i256 %14)
//CHECK-NEXT:   %15 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %call.fr_add, i256* %15, align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
