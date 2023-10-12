pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*     // TEMPORARY: because EXTRACT_LOOP_BODY_TO_NEW_FUNC == false

// if condition can be known via unrolling, arrays used inside indexed on iteration variable
template InnerConditional4(N) {
    signal output out[N];
    signal input in;

    for (var i = 0; i < N; i++) {
        if (i < 3) {
            out[i] <-- -in;
        } else {
            out[i] <-- in;
        }
    }
}

component main = InnerConditional4(6);

//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %branch1
//CHECK-EMPTY: 
//CHECK-NEXT: branch1:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %call.fr_lt = call i1 @fr_lt(i256 %1, i256 3)
//CHECK-NEXT:   br i1 %call.fr_lt, label %if.then, label %if.else
//CHECK-EMPTY: 
//CHECK-NEXT: if.then:
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 6
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %call.fr_neg = call i256 @fr_neg(i256 %3)
//CHECK-NEXT:   %4 = getelementptr i256, i256* %fix_[[X1]], i32 0
//CHECK-NEXT:   store i256 %call.fr_neg, i256* %4, align 4
//CHECK-NEXT:   br label %if.merge
//CHECK-EMPTY: 
//CHECK-NEXT: if.else:
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 6
//CHECK-NEXT:   %6 = load i256, i256* %5, align 4
//CHECK-NEXT:   %7 = getelementptr i256, i256* %fix_[[X2]], i32 0
//CHECK-NEXT:   store i256 %6, i256* %7, align 4
//CHECK-NEXT:   br label %if.merge
//CHECK-EMPTY: 
//CHECK-NEXT: if.merge:
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %9 = load i256, i256* %8, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %9, i256 1)
//CHECK-NEXT:   %10 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 %call.fr_add, i256* %10, align 4
//CHECK-NEXT:   br label %return6
//CHECK-EMPTY: 
//CHECK-NEXT: return6:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @InnerConditional4_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [2 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 6, i256* %1, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %2 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %2, align 4
//CHECK-NEXT:   br label %unrolled_loop3
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop3:
//CHECK-NEXT:   %3 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %3, [0 x i256]* %0, i256* %4, i256* null)
//CHECK-NEXT:   %5 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %5, [0 x i256]* %0, i256* %6, i256* null)
//CHECK-NEXT:   %7 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %7, [0 x i256]* %0, i256* %8, i256* null)
//CHECK-NEXT:   %9 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %10 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %9, [0 x i256]* %0, i256* null, i256* %10)
//CHECK-NEXT:   %11 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %12 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 4
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %11, [0 x i256]* %0, i256* null, i256* %12)
//CHECK-NEXT:   %13 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %14 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 5
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %13, [0 x i256]* %0, i256* null, i256* %14)
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }