pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// This test contains inner loops with different iteration counts. Further, one is
//  independent of the outer loop induction variable and the other loop depends on it.
//
// lvars = [ N, a[0], a[1], a[2], a[3], i, j ]
template InnerConditional12(N) {
    signal output out;

    var a[N];
    for (var i = 0; i < N; i++) {
        if (i < 2) {
            // runs when i∈{0,1}
            for (var j = 0; j < N; j++) {
                a[i] += 999;
            }
        } else {
            // runs when i∈{2,3}
            for (var j = 0; j < i; j++) {
                a[i] += 888;
            }
        }
    }
    out <-- a[0] + a[1];
}

component main = InnerConditional12(4);

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+\.T}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %var_[[X1:[0-9]+]], i256* %var_[[X2:[0-9]+]], i256* %var_[[X3:[0-9]+]], i256* %var_[[X4:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9]+\.T]]:
//CHECK-NEXT:   br label %fold_true1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_true1:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 0, i256* %0, align 4
//CHECK-NEXT:   br label %loop.cond
//CHECK-EMPTY: 
//CHECK-NEXT: loop.cond:
//CHECK-NEXT:   %1 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %2 = load i256, i256* %1, align 4
//CHECK-NEXT:   %call.fr_lt = call i1 @fr_lt(i256 %2, i256 4)
//CHECK-NEXT:   br i1 %call.fr_lt, label %loop.body, label %loop.end
//CHECK-EMPTY: 
//CHECK-NEXT: loop.body:
//CHECK-NEXT:   %3 = getelementptr i256, i256* %var_[[X1]], i32 0
//CHECK-NEXT:   %4 = getelementptr i256, i256* %var_[[X2]], i32 0
//CHECK-NEXT:   %5 = load i256, i256* %4, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %5, i256 999)
//CHECK-NEXT:   store i256 %call.fr_add, i256* %3, align 4
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %7 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %8 = load i256, i256* %7, align 4
//CHECK-NEXT:   %call.fr_add1 = call i256 @fr_add(i256 %8, i256 1)
//CHECK-NEXT:   store i256 %call.fr_add1, i256* %6, align 4
//CHECK-NEXT:   br label %loop.cond
//CHECK-EMPTY: 
//CHECK-NEXT: loop.end:
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %10 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %11 = load i256, i256* %10, align 4
//CHECK-NEXT:   %call.fr_add2 = call i256 @fr_add(i256 %11, i256 1)
//CHECK-NEXT:   store i256 %call.fr_add2, i256* %9, align 4
//CHECK-NEXT:   br label %return6
//CHECK-EMPTY: 
//CHECK-NEXT: return6:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+\.F}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %var_[[X1:[0-9]+]], i256* %var_[[X2:[0-9]+]], i256* %var_[[X3:[0-9]+]], i256* %var_[[X4:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2:[0-9]+\.F]]:
//CHECK-NEXT:   br label %fold_false1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_false1:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 0, i256* %0, align 4
//CHECK-NEXT:   br label %loop.cond
//CHECK-EMPTY: 
//CHECK-NEXT: loop.cond:
//CHECK-NEXT:   %1 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %2 = load i256, i256* %1, align 4
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %4 = load i256, i256* %3, align 4
//CHECK-NEXT:   %call.fr_lt = call i1 @fr_lt(i256 %2, i256 %4)
//CHECK-NEXT:   br i1 %call.fr_lt, label %loop.body, label %loop.end
//CHECK-EMPTY: 
//CHECK-NEXT: loop.body:
//CHECK-NEXT:   %5 = getelementptr i256, i256* %var_[[X3]], i32 0
//CHECK-NEXT:   %6 = getelementptr i256, i256* %var_[[X4]], i32 0
//CHECK-NEXT:   %7 = load i256, i256* %6, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %7, i256 888)
//CHECK-NEXT:   store i256 %call.fr_add, i256* %5, align 4
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %10 = load i256, i256* %9, align 4
//CHECK-NEXT:   %call.fr_add1 = call i256 @fr_add(i256 %10, i256 1)
//CHECK-NEXT:   store i256 %call.fr_add1, i256* %8, align 4
//CHECK-NEXT:   br label %loop.cond
//CHECK-EMPTY: 
//CHECK-NEXT: loop.end:
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %12 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %13 = load i256, i256* %12, align 4
//CHECK-NEXT:   %call.fr_add2 = call i256 @fr_add(i256 %13, i256 1)
//CHECK-NEXT:   store i256 %call.fr_add2, i256* %11, align 4
//CHECK-NEXT:   br label %return6
//CHECK-EMPTY: 
//CHECK-NEXT: return6:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }

//CHECK-LABEL: define{{.*}} void @InnerConditional12_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK:      unrolled_loop7:
//CHECK-NEXT:   %7 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %8 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %8, i32 0, i256 1
//CHECK-NEXT:   %10 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %10, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %7, [0 x i256]* %0, i256* %9, i256* %11, i256* null, i256* null)
//CHECK-NEXT:   %12 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %13 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %14 = getelementptr [0 x i256], [0 x i256]* %13, i32 0, i256 2
//CHECK-NEXT:   %15 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %16 = getelementptr [0 x i256], [0 x i256]* %15, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %12, [0 x i256]* %0, i256* %14, i256* %16, i256* null, i256* null)
//CHECK-NEXT:   %17 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %18 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %19 = getelementptr [0 x i256], [0 x i256]* %18, i32 0, i256 3
//CHECK-NEXT:   %20 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %21 = getelementptr [0 x i256], [0 x i256]* %20, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %17, [0 x i256]* %0, i256* null, i256* null, i256* %19, i256* %21)
//CHECK-NEXT:   %22 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %23 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %24 = getelementptr [0 x i256], [0 x i256]* %23, i32 0, i256 4
//CHECK-NEXT:   %25 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %26 = getelementptr [0 x i256], [0 x i256]* %25, i32 0, i256 4
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %22, [0 x i256]* %0, i256* null, i256* null, i256* %24, i256* %26)
//CHECK-NEXT:   br label %store8
