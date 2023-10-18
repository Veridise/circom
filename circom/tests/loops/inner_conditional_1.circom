pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// IF condition can be known via in-place unrolling but not when body is extracted to a new function
template InnerConditional1(N) {
    signal output out;

    var acc = 0;
    for (var i = 1; i <= N; i++) {
        if (i < 5) {
            acc += i;
        } else {
            acc -= i;
        }
    }

    out <-- acc;
}

component main = InnerConditional1(10);

//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %branch1
//CHECK-EMPTY: 
//CHECK-NEXT: branch1:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %call.fr_lt = call i1 @fr_lt(i256 %1, i256 5)
//CHECK-NEXT:   br i1 %call.fr_lt, label %if.then, label %if.else
//CHECK-EMPTY: 
//CHECK-NEXT: if.then:
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %5 = load i256, i256* %4, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %3, i256 %5)
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 %call.fr_add, i256* %6, align 4
//CHECK-NEXT:   br label %if.merge
//CHECK-EMPTY: 
//CHECK-NEXT: if.else:
//CHECK-NEXT:   %7 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %8 = load i256, i256* %7, align 4
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %10 = load i256, i256* %9, align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %8, i256 %10)
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 %call.fr_sub, i256* %11, align 4
//CHECK-NEXT:   br label %if.merge
//CHECK-EMPTY: 
//CHECK-NEXT: if.merge:
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %12 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %13 = load i256, i256* %12, align 4
//CHECK-NEXT:   %call.fr_add1 = call i256 @fr_add(i256 %13, i256 1)
//CHECK-NEXT:   %14 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 %call.fr_add1, i256* %14, align 4
//CHECK-NEXT:   br label %return6
//CHECK-EMPTY: 
//CHECK-NEXT: return6:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @InnerConditional1_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [3 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 10, i256* %1, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %2 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %2, align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %3 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 1, i256* %3, align 4
//CHECK-NEXT:   br label %unrolled_loop4
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop4:
//CHECK-NEXT:   %4 = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %4, [0 x i256]* %0)
//CHECK-NEXT:   %5 = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %5, [0 x i256]* %0)
//CHECK-NEXT:   %6 = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %6, [0 x i256]* %0)
//CHECK-NEXT:   %7 = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %7, [0 x i256]* %0)
//CHECK-NEXT:   %8 = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %8, [0 x i256]* %0)
//CHECK-NEXT:   %9 = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %9, [0 x i256]* %0)
//CHECK-NEXT:   %10 = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %10, [0 x i256]* %0)
//CHECK-NEXT:   %11 = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %11, [0 x i256]* %0)
//CHECK-NEXT:   %12 = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %12, [0 x i256]* %0)
//CHECK-NEXT:   %13 = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %13, [0 x i256]* %0)
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %14 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 21888242871839275222246405745257275088548364400416034343698204186575808495582, i256* %14, align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
