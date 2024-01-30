pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

//arena = { a[0], a[1], n, b, c, d, e, f, g}
function fun(a, n, b, c, d, e, f, g) {
	var x[5];
    for (var i = 0; i < n; i++) {
    	x[i] = a[i] + b + c + d + e + f;
    }
	return x[0] + x[2] + x[4];
}

//signal_arena = { out, in }
//lvars = { m, n, a[0], a[1], b[0], b[1], i }
template CallInLoop(n, m) {
    signal input in;
    signal output out;
    var a[n];
    for (var i = 0; i < n; i++) {
    	a[i] = m + in;
    }
    var b[n];
    for (var i = 0; i < n; i++) {
    	b[i] = fun(a, n, m, m, m, m, m, m);
    }
    out <-- b[0];
}

component main = CallInLoop(2, 3);

//
//     var a[2];
//     i = 0;
//     	a[0] = 3 + in;
//     i = 1;
//     	a[1] = 3 + in;
//     i = 2;
//     var b[2];
//     i = 0;
//     	b[0] = fun(a, 2, 3, 3, 3, 3, 3, 3);
//     i = 1;
//     	b[1] = fun(a, 2, 3, 3, 3, 3, 3, 3);
//     i = 2;
//     out <-- b[0];
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %var_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 1
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 3, i256 %1)
//CHECK-NEXT:   %2 = getelementptr i256, i256* %var_0, i32 0
//CHECK-NEXT:   store i256 %call.fr_add, i256* %2, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %4 = load i256, i256* %3, align 4
//CHECK-NEXT:   %call.fr_add1 = call i256 @fr_add(i256 %4, i256 1)
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 %call.fr_add1, i256* %5, align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_2:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %var_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2]]:
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY: 
//CHECK-NEXT: call1:
//CHECK-NEXT:   %fun_0_arena = alloca [15 x i256], align 8
//CHECK-NEXT:   %0 = getelementptr [15 x i256], [15 x i256]* %fun_0_arena, i32 0, i32 0
//CHECK-NEXT:   %1 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   call void @fr_copy_n(i256* %1, i256* %0, i32 2)
//CHECK-NEXT:   %2 = getelementptr [15 x i256], [15 x i256]* %fun_0_arena, i32 0, i32 2
//CHECK-NEXT:   store i256 2, i256* %2, align 4
//CHECK-NEXT:   %3 = getelementptr [15 x i256], [15 x i256]* %fun_0_arena, i32 0, i32 3
//CHECK-NEXT:   store i256 3, i256* %3, align 4
//CHECK-NEXT:   %4 = getelementptr [15 x i256], [15 x i256]* %fun_0_arena, i32 0, i32 4
//CHECK-NEXT:   store i256 3, i256* %4, align 4
//CHECK-NEXT:   %5 = getelementptr [15 x i256], [15 x i256]* %fun_0_arena, i32 0, i32 5
//CHECK-NEXT:   store i256 3, i256* %5, align 4
//CHECK-NEXT:   %6 = getelementptr [15 x i256], [15 x i256]* %fun_0_arena, i32 0, i32 6
//CHECK-NEXT:   store i256 3, i256* %6, align 4
//CHECK-NEXT:   %7 = getelementptr [15 x i256], [15 x i256]* %fun_0_arena, i32 0, i32 7
//CHECK-NEXT:   store i256 3, i256* %7, align 4
//CHECK-NEXT:   %8 = getelementptr [15 x i256], [15 x i256]* %fun_0_arena, i32 0, i32 8
//CHECK-NEXT:   store i256 3, i256* %8, align 4
//CHECK-NEXT:   %9 = bitcast [15 x i256]* %fun_0_arena to i256*
//CHECK-NEXT:   %call.fun_0 = call i256 @fun_0(i256* %9)
//CHECK-NEXT:   %10 = getelementptr i256, i256* %var_0, i32 0
//CHECK-NEXT:   store i256 %call.fun_0, i256* %10, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %12 = load i256, i256* %11, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %12, i256 1)
//CHECK-NEXT:   %13 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 %call.fr_add, i256* %13, align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @CallInLoop_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [7 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 3, i256* %1, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %2 = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 2, i256* %2, align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %3 = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 0, i256* %3, align 4
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %4 = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 0, i256* %4, align 4
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %5 = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %5, align 4
//CHECK-NEXT:   br label %unrolled_loop6
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop6:
//CHECK-NEXT:   %6 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %7 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %7, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %6, [0 x i256]* %0, i256* %8)
//CHECK-NEXT:   %9 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %10 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %10, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %9, [0 x i256]* %0, i256* %11)
//CHECK-NEXT:   br label %store7
//CHECK-EMPTY: 
//CHECK-NEXT: store7:
//CHECK-NEXT:   %12 = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %12, align 4
//CHECK-NEXT:   br label %store8
//CHECK-EMPTY: 
//CHECK-NEXT: store8:
//CHECK-NEXT:   %13 = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 0, i256* %13, align 4
//CHECK-NEXT:   br label %store9
//CHECK-EMPTY: 
//CHECK-NEXT: store9:
//CHECK-NEXT:   %14 = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 0, i256* %14, align 4
//CHECK-NEXT:   br label %unrolled_loop10
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop10:
//CHECK-NEXT:   %15 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %16 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %17 = getelementptr [0 x i256], [0 x i256]* %16, i32 0, i256 4
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %15, [0 x i256]* %0, i256* %17)
//CHECK-NEXT:   %18 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %19 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %20 = getelementptr [0 x i256], [0 x i256]* %19, i32 0, i256 5
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %18, [0 x i256]* %0, i256* %20)
//CHECK-NEXT:   br label %store11
//CHECK-EMPTY: 
//CHECK-NEXT: store11:
//CHECK-NEXT:   %21 = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %22 = load i256, i256* %21, align 4
//CHECK-NEXT:   %23 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %22, i256* %23, align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
