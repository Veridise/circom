pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template Num2Bits(n) {
    signal input in;
    signal output out[n];

    var lc1=0;
    var e2=1;
    for (var i = 0; i<n; i++) {
        out[i] <-- (in >> i) & 1;
        out[i] * (out[i] -1 ) === 0;
        lc1 += out[i] * e2;
        e2 = e2+e2;
    }

    lc1 === in;
}

component main = Num2Bits(2);

// %0 (i.e. signal arena) = [ out[0], out[1], in ]
// %lvars =  [ n, lc1, e2, i ]
// %subcmps = []
//
//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]], i256* %fix_[[X3:[0-9]+]], i256* %fix_[[X4:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 2
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %call.fr_shr = call i256 @fr_shr(i256 %1, i256 %3)
//CHECK-NEXT:   %call.fr_bit_and = call i256 @fr_bit_and(i256 %call.fr_shr, i256 1)
//CHECK-NEXT:   %4 = getelementptr i256, i256* %fix_[[X1]], i32 0
//CHECK-NEXT:   store i256 %call.fr_bit_and, i256* %4, align 4
//CHECK-NEXT:   br label %assert2
//CHECK-EMPTY: 
//CHECK-NEXT: assert2:
//CHECK-NEXT:   %5 = getelementptr i256, i256* %fix_[[X2]], i32 0
//CHECK-NEXT:   %6 = load i256, i256* %5, align 4
//CHECK-NEXT:   %7 = getelementptr i256, i256* %fix_[[X3]], i32 0
//CHECK-NEXT:   %8 = load i256, i256* %7, align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %8, i256 1)
//CHECK-NEXT:   %call.fr_mul = call i256 @fr_mul(i256 %6, i256 %call.fr_sub)
//CHECK-NEXT:   %call.fr_eq = call i1 @fr_eq(i256 %call.fr_mul, i256 0)
//CHECK-NEXT:   call void @__assert(i1 %call.fr_eq)
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_value(i1 %call.fr_eq, i1* %constraint)
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %10 = load i256, i256* %9, align 4
//CHECK-NEXT:   %11 = getelementptr i256, i256* %fix_[[X4]], i32 0
//CHECK-NEXT:   %12 = load i256, i256* %11, align 4
//CHECK-NEXT:   %13 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %14 = load i256, i256* %13, align 4
//CHECK-NEXT:   %call.fr_mul1 = call i256 @fr_mul(i256 %12, i256 %14)
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %10, i256 %call.fr_mul1)
//CHECK-NEXT:   %15 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 %call.fr_add, i256* %15, align 4
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %16 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %17 = load i256, i256* %16, align 4
//CHECK-NEXT:   %18 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %19 = load i256, i256* %18, align 4
//CHECK-NEXT:   %call.fr_add2 = call i256 @fr_add(i256 %17, i256 %19)
//CHECK-NEXT:   %20 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 %call.fr_add2, i256* %20, align 4
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %21 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %22 = load i256, i256* %21, align 4
//CHECK-NEXT:   %call.fr_add3 = call i256 @fr_add(i256 %22, i256 1)
//CHECK-NEXT:   %23 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 %call.fr_add3, i256* %23, align 4
//CHECK-NEXT:   br label %return6
//CHECK-EMPTY: 
//CHECK-NEXT: return6:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @Num2Bits_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9]+]])
//CHECK:      unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %5 = bitcast [4 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   %7 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID]]([0 x i256]* %5, [0 x i256]* %0, i256* %6, i256* %7, i256* %8, i256* %9)
//CHECK-NEXT:   %10 = bitcast [4 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %12 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %13 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %14 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID]]([0 x i256]* %10, [0 x i256]* %0, i256* %11, i256* %12, i256* %13, i256* %14)
//CHECK-NEXT:   br label %assert{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: assert{{[0-9]+}}:
//CHECK-NEXT:   %15 = getelementptr [4 x i256], [4 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %16 = load i256, i256* %15, align 4
//CHECK-NEXT:   %17 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 2
//CHECK-NEXT:   %18 = load i256, i256* %17, align 4
//CHECK-NEXT:   %call.fr_eq = call i1 @fr_eq(i256 %16, i256 %18)
//CHECK-NEXT:   call void @__assert(i1 %call.fr_eq)
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_value(i1 %call.fr_eq, i1* %constraint)
//CHECK-NEXT:   br label %prologue
