pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// like inner_conditional_7 but with 'i' and 'j' uses swapped
template InnerConditional8(N) {
    signal output out;

    var a[N];
    for (var i = 0; i < N; i++) {
        for (var j = 0; j < N; j++) {
            if (j > 1) {
                a[i] += 999;
            } else {
                a[i] -= 111;
            }
        }
    }

    out <-- a[0] + a[1];
}

component main = InnerConditional8(4);

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]], i256* %fix_[[X3:[0-9]+]], i256* %fix_[[X4:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 0, i256* %0, align 4
//CHECK-NEXT:   br label %loop2
//CHECK-EMPTY: 
//CHECK-NEXT: loop2:
//CHECK-NEXT:   br label %loop.cond
//CHECK-EMPTY: 
//CHECK-NEXT: loop.cond:
//CHECK-NEXT:   %1 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %2 = load i256, i256* %1, align 4
//CHECK-NEXT:   %call.fr_lt = call i1 @fr_lt(i256 %2, i256 4)
//CHECK-NEXT:   br i1 %call.fr_lt, label %loop.body, label %loop.end
//CHECK-EMPTY: 
//CHECK-NEXT: loop.body:
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %4 = load i256, i256* %3, align 4
//CHECK-NEXT:   %call.fr_gt = call i1 @fr_gt(i256 %4, i256 1)
//CHECK-NEXT:   br i1 %call.fr_gt, label %if.then, label %if.else
//CHECK-EMPTY: 
//CHECK-NEXT: loop.end:
//CHECK-NEXT:   br label %store9
//CHECK-EMPTY: 
//CHECK-NEXT: if.then:
//CHECK-NEXT:   %5 = getelementptr i256, i256* %fix_[[X4]], i32 0
//CHECK-NEXT:   %6 = load i256, i256* %5, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %6, i256 999)
//CHECK-NEXT:   %7 = getelementptr i256, i256* %fix_[[X3]], i32 0
//CHECK-NEXT:   store i256 %call.fr_add, i256* %7, align 4
//CHECK-NEXT:   br label %if.merge
//CHECK-EMPTY: 
//CHECK-NEXT: if.else:
//CHECK-NEXT:   %8 = getelementptr i256, i256* %fix_[[X2]], i32 0
//CHECK-NEXT:   %9 = load i256, i256* %8, align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %9, i256 111)
//CHECK-NEXT:   %10 = getelementptr i256, i256* %fix_[[X1]], i32 0
//CHECK-NEXT:   store i256 %call.fr_sub, i256* %10, align 4
//CHECK-NEXT:   br label %if.merge
//CHECK-EMPTY: 
//CHECK-NEXT: if.merge:
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %12 = load i256, i256* %11, align 4
//CHECK-NEXT:   %call.fr_add1 = call i256 @fr_add(i256 %12, i256 1)
//CHECK-NEXT:   %13 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 %call.fr_add1, i256* %13, align 4
//CHECK-NEXT:   br label %loop.cond
//CHECK-EMPTY: 
//CHECK-NEXT: store9:
//CHECK-NEXT:   %14 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %15 = load i256, i256* %14, align 4
//CHECK-NEXT:   %call.fr_add2 = call i256 @fr_add(i256 %15, i256 1)
//CHECK-NEXT:   %16 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 %call.fr_add2, i256* %16, align 4
//CHECK-NEXT:   br label %return10
//CHECK-EMPTY: 
//CHECK-NEXT: return10:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @InnerConditional8_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [7 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 4, i256* %1, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %2 = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %2, align 4
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
//CHECK-NEXT:   br label %store6
//CHECK-EMPTY: 
//CHECK-NEXT: store6:
//CHECK-NEXT:   %6 = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 0, i256* %6, align 4
//CHECK-NEXT:   br label %unrolled_loop7
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop7:
//CHECK-NEXT:   %7 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %8 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %8, i32 0, i256 1
//CHECK-NEXT:   %10 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %10, i32 0, i256 1
//CHECK-NEXT:   %12 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %13 = getelementptr [0 x i256], [0 x i256]* %12, i32 0, i256 1
//CHECK-NEXT:   %14 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %15 = getelementptr [0 x i256], [0 x i256]* %14, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %7, [0 x i256]* %0, i256* %9, i256* %11, i256* %13, i256* %15)
//CHECK-NEXT:   %16 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %17 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %18 = getelementptr [0 x i256], [0 x i256]* %17, i32 0, i256 2
//CHECK-NEXT:   %19 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %20 = getelementptr [0 x i256], [0 x i256]* %19, i32 0, i256 2
//CHECK-NEXT:   %21 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %22 = getelementptr [0 x i256], [0 x i256]* %21, i32 0, i256 2
//CHECK-NEXT:   %23 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %24 = getelementptr [0 x i256], [0 x i256]* %23, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %16, [0 x i256]* %0, i256* %18, i256* %20, i256* %22, i256* %24)
//CHECK-NEXT:   %25 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %26 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %27 = getelementptr [0 x i256], [0 x i256]* %26, i32 0, i256 3
//CHECK-NEXT:   %28 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %29 = getelementptr [0 x i256], [0 x i256]* %28, i32 0, i256 3
//CHECK-NEXT:   %30 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %31 = getelementptr [0 x i256], [0 x i256]* %30, i32 0, i256 3
//CHECK-NEXT:   %32 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %33 = getelementptr [0 x i256], [0 x i256]* %32, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %25, [0 x i256]* %0, i256* %27, i256* %29, i256* %31, i256* %33)
//CHECK-NEXT:   %34 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %35 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %36 = getelementptr [0 x i256], [0 x i256]* %35, i32 0, i256 4
//CHECK-NEXT:   %37 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %38 = getelementptr [0 x i256], [0 x i256]* %37, i32 0, i256 4
//CHECK-NEXT:   %39 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %40 = getelementptr [0 x i256], [0 x i256]* %39, i32 0, i256 4
//CHECK-NEXT:   %41 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %42 = getelementptr [0 x i256], [0 x i256]* %41, i32 0, i256 4
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %34, [0 x i256]* %0, i256* %36, i256* %38, i256* %40, i256* %42)
//CHECK-NEXT:   br label %store8
//CHECK-EMPTY: 
//CHECK-NEXT: store8:
//CHECK-NEXT:   %43 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 3552, i256* %43, align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
