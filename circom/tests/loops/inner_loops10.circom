pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template InnerLoops(N) {
    signal input in[N];
    signal output out;
    signal output out2[N];
    var a = 0;
    var b = 0;
    for (var i = 0; i < N; i++) {
        out2[i] <-- in[i] + b;
        for (var j = 0; j < N; j++) {
            a += 99;
        }
        b += 5;
    }
    out <-- a;
}

component main = InnerLoops(2);

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %sig_[[X1:[0-9]+]], i256* %sig_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9]+]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr i256, i256* %sig_[[X1]], i32 0
//CHECK-NEXT:   %1 = getelementptr i256, i256* %sig_[[X2]], i32 0
//CHECK-NEXT:   %2 = load i256, i256* %1, align 4
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %4 = load i256, i256* %3, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %2, i256 %4)
//CHECK-NEXT:   store i256 %call.fr_add, i256* %0, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %5, align 4
//CHECK-NEXT:   br label %loop3
//CHECK-EMPTY: 
//CHECK-NEXT: loop3:
//CHECK-NEXT:   br label %loop.cond
//CHECK-EMPTY: 
//CHECK-NEXT: loop.cond:
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %7 = load i256, i256* %6, align 4
//CHECK-NEXT:   %call.fr_lt = call i1 @fr_lt(i256 %7, i256 2)
//CHECK-NEXT:   br i1 %call.fr_lt, label %loop.body, label %loop.end
//CHECK-EMPTY: 
//CHECK-NEXT: loop.body:
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %10 = load i256, i256* %9, align 4
//CHECK-NEXT:   %call.fr_add1 = call i256 @fr_add(i256 %10, i256 99)
//CHECK-NEXT:   store i256 %call.fr_add1, i256* %8, align 4
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %12 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %13 = load i256, i256* %12, align 4
//CHECK-NEXT:   %call.fr_add2 = call i256 @fr_add(i256 %13, i256 1)
//CHECK-NEXT:   store i256 %call.fr_add2, i256* %11, align 4
//CHECK-NEXT:   br label %loop.cond
//CHECK-EMPTY: 
//CHECK-NEXT: loop.end:
//CHECK-NEXT:   br label %store7
//CHECK-EMPTY: 
//CHECK-NEXT: store7:
//CHECK-NEXT:   %14 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %15 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %16 = load i256, i256* %15, align 4
//CHECK-NEXT:   %call.fr_add3 = call i256 @fr_add(i256 %16, i256 5)
//CHECK-NEXT:   store i256 %call.fr_add3, i256* %14, align 4
//CHECK-NEXT:   br label %store8
//CHECK-EMPTY: 
//CHECK-NEXT: store8:
//CHECK-NEXT:   %17 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %18 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %19 = load i256, i256* %18, align 4
//CHECK-NEXT:   %call.fr_add4 = call i256 @fr_add(i256 %19, i256 1)
//CHECK-NEXT:   store i256 %call.fr_add4, i256* %17, align 4
//CHECK-NEXT:   br label %return9
//CHECK-EMPTY: 
//CHECK-NEXT: return9:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @InnerLoops_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [5 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 2, i256* %1, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %2 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %2, align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %3 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 0, i256* %3, align 4
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %4 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 0, i256* %4, align 4
//CHECK-NEXT:   br label %unrolled_loop5
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop5:
//CHECK-NEXT:   %5 = bitcast [5 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %7 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %5, [0 x i256]* %0, i256* %6, i256* %7)
//CHECK-NEXT:   %8 = bitcast [5 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   %10 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 4
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %8, [0 x i256]* %0, i256* %9, i256* %10)
//CHECK-NEXT:   br label %store6
//CHECK-EMPTY: 
//CHECK-NEXT: store6:
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 396, i256* %11, align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
