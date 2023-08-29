pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s

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

// %arena (i.e. %0 param) = [ out[0], out[1], in ]
// %lvars =  [ n, lc1, e2, i ]
// %subcmps = []
//
//CHECK-LABEL: define void @Num2Bits_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9]+]])
//CHECK: unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:  %5 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 2
//CHECK-NEXT:  %6 = load i256, i256* %5, align 4
//CHECK-NEXT:  %7 = getelementptr [4 x i256], [4 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:  %8 = load i256, i256* %7, align 4
//CHECK-NEXT:  %call.fr_shr = call i256 @fr_shr(i256 %6, i256 %8)
//CHECK-NEXT:  %call.fr_bit_and = call i256 @fr_bit_and(i256 %call.fr_shr, i256 1)
//CHECK-NEXT:  %9 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:  store i256 %call.fr_bit_and, i256* %9, align 4
//CHECK-NEXT:  %10 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:  %11 = load i256, i256* %10, align 4
//CHECK-NEXT:  %12 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:  %13 = load i256, i256* %12, align 4
//CHECK-NEXT:  %call.fr_sub = call i256 @fr_sub(i256 %13, i256 1)
//CHECK-NEXT:  %call.fr_mul = call i256 @fr_mul(i256 %11, i256 %call.fr_sub)
//CHECK-NEXT:  %call.fr_eq = call i1 @fr_eq(i256 %call.fr_mul, i256 0)
//CHECK-NEXT:  call void @__assert(i1 %call.fr_eq)
//CHECK-NEXT:  %constraint = alloca i1, align 1
//CHECK-NEXT:  call void @__constraint_value(i1 %call.fr_eq, i1* %constraint)
//CHECK-NEXT:  %14 = getelementptr [4 x i256], [4 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:  %15 = load i256, i256* %14, align 4
//CHECK-NEXT:  %16 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:  %17 = load i256, i256* %16, align 4
//CHECK-NEXT:  %18 = getelementptr [4 x i256], [4 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:  %19 = load i256, i256* %18, align 4
//CHECK-NEXT:  %call.fr_mul1 = call i256 @fr_mul(i256 %17, i256 %19)
//CHECK-NEXT:  %call.fr_add = call i256 @fr_add(i256 %15, i256 %call.fr_mul1)
//CHECK-NEXT:  %20 = getelementptr [4 x i256], [4 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:  store i256 %call.fr_add, i256* %20, align 4
//CHECK-NEXT:  %21 = getelementptr [4 x i256], [4 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:  store i256 2, i256* %21, align 4
//CHECK-NEXT:  %22 = getelementptr [4 x i256], [4 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:  store i256 1, i256* %22, align 4
//CHECK-NEXT:  %23 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 2
//CHECK-NEXT:  %24 = load i256, i256* %23, align 4
//CHECK-NEXT:  %25 = getelementptr [4 x i256], [4 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:  %26 = load i256, i256* %25, align 4
//CHECK-NEXT:  %call.fr_shr2 = call i256 @fr_shr(i256 %24, i256 %26)
//CHECK-NEXT:  %call.fr_bit_and3 = call i256 @fr_bit_and(i256 %call.fr_shr2, i256 1)
//CHECK-NEXT:  %27 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:  store i256 %call.fr_bit_and3, i256* %27, align 4
//CHECK-NEXT:  %28 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:  %29 = load i256, i256* %28, align 4
//CHECK-NEXT:  %30 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:  %31 = load i256, i256* %30, align 4
//CHECK-NEXT:  %call.fr_sub4 = call i256 @fr_sub(i256 %31, i256 1)
//CHECK-NEXT:  %call.fr_mul5 = call i256 @fr_mul(i256 %29, i256 %call.fr_sub4)
//CHECK-NEXT:  %call.fr_eq6 = call i1 @fr_eq(i256 %call.fr_mul5, i256 0)
//CHECK-NEXT:  call void @__assert(i1 %call.fr_eq6)
//CHECK-NEXT:  %constraint7 = alloca i1, align 1
//CHECK-NEXT:  call void @__constraint_value(i1 %call.fr_eq6, i1* %constraint7)
//CHECK-NEXT:  %32 = getelementptr [4 x i256], [4 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:  %33 = load i256, i256* %32, align 4
//CHECK-NEXT:  %34 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:  %35 = load i256, i256* %34, align 4
//CHECK-NEXT:  %36 = getelementptr [4 x i256], [4 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:  %37 = load i256, i256* %36, align 4
//CHECK-NEXT:  %call.fr_mul8 = call i256 @fr_mul(i256 %35, i256 %37)
//CHECK-NEXT:  %call.fr_add9 = call i256 @fr_add(i256 %33, i256 %call.fr_mul8)
//CHECK-NEXT:  %38 = getelementptr [4 x i256], [4 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:  store i256 %call.fr_add9, i256* %38, align 4
//CHECK-NEXT:  %39 = getelementptr [4 x i256], [4 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:  store i256 4, i256* %39, align 4
//CHECK-NEXT:  %40 = getelementptr [4 x i256], [4 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:  store i256 2, i256* %40, align 4
