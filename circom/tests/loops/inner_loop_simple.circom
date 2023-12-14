pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL: *


template InnerLoops(n, m) {
    signal input in[m];
    signal output out;
    var b[n];

    for (var i = 0; i < n; i++) {
        for (var j = 0; j < m; j++) {
            b[i] = in[j];
        }
    }
    out <-- b[0];
}

component main = InnerLoops(2, 3);

// %0 (i.e. signal arena) = { out, in[0], in[1], in[2] }
// %lvars = { n, m, b[0], b[1], i, j }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %fix_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %call.fr_cast_to_addr = call i32 @fr_cast_to_addr(i256 %1)
//CHECK-NEXT:   %mul_addr = mul i32 1, %call.fr_cast_to_addr
//CHECK-NEXT:   %add_addr = add i32 %mul_addr, 2
//CHECK-NEXT:   %2 = getelementptr i256, i256* %fix_0, i32 0
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 %add_addr
//CHECK-NEXT:   store i256 %3, i256* %4, align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %6 = load i256, i256* %5, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %6, i256 1)
//CHECK-NEXT:   %7 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 %call.fr_add, i256* %7, align 4
//CHECK-NEXT:   br label %return{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: return{{[0-9]+}}:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @InnerLoops_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK:      unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %6 = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 0, i256* %6, align 4
//CHECK-NEXT:   %7 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %7, [0 x i256]* %0, i256* %8)
//CHECK-NEXT:   %9 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %10 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %9, [0 x i256]* %0, i256* %10)
//CHECK-NEXT:   %11 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %12 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %11, [0 x i256]* %0, i256* %12)
//CHECK-NEXT:   %13 = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %13, align 4
//CHECK-NEXT:   %14 = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 0, i256* %14, align 4
//CHECK-NEXT:   %15 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %16 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %15, [0 x i256]* %0, i256* %16)
//CHECK-NEXT:   %17 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %18 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %17, [0 x i256]* %0, i256* %18)
//CHECK-NEXT:   %19 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %20 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %19, [0 x i256]* %0, i256* %20)
//CHECK-NEXT:   %21 = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %21, align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %22 = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %23 = load i256, i256* %22, align 4
//CHECK-NEXT:   %24 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %23, i256* %24, align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
