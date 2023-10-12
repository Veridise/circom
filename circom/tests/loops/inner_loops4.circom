pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*     // TEMPORARY: because EXTRACT_LOOP_BODY_TO_NEW_FUNC == false

template InnerLoops(n) {
    signal input a[n];
    var b[n];
    var j;
    for (var i = 0; i < n; i++) {
        for (j = 0; j <= i; j++) {
            // NOTE: When processing the outer loop, the following statement is determined NOT
            //  safe to move into a new function since it uses 'j' which is unknown. That results
            //  in the outer loop unrolling without extrating the body to a new function. Then
            //  the two copies of the inner loop are processed and their bodies are extracted to
            //  new functions and replaced with calls to those functions before unrolling. So it
            //  ends up creating two slightly different functions for this innermost body, one
            //  for each iteration of the outer loop (i.e. when b=0 and when b=1). This result
            //  is logically correct but not optimal in terms of code size.
            b[i] = a[i - j];
        }
    }
}

component main = InnerLoops(2);

// %0 (i.e. signal arena) = { a[0], a[1] }
// %lvars = { n, b[0], b[1], j, i }
//
//Fully unrolled:
//  b[0] = a[0];
//  b[1] = a[1];
//  b[1] = a[0];
//
//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %call.fr_cast_to_addr = call i32 @fr_cast_to_addr(i256 %1)
//CHECK-NEXT:   %mul_addr = mul i32 1, %call.fr_cast_to_addr
//CHECK-NEXT:   %add_addr = add i32 %mul_addr, 1
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %5 = load i256, i256* %4, align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %3, i256 %5)
//CHECK-NEXT:   %call.fr_cast_to_addr1 = call i32 @fr_cast_to_addr(i256 %call.fr_sub)
//CHECK-NEXT:   %mul_addr2 = mul i32 1, %call.fr_cast_to_addr1
//CHECK-NEXT:   %add_addr3 = add i32 %mul_addr2, 0
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 %add_addr3
//CHECK-NEXT:   %7 = load i256, i256* %6, align 4
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 %add_addr
//CHECK-NEXT:   store i256 %7, i256* %8, align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %10 = load i256, i256* %9, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %10, i256 1)
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 %call.fr_add, i256* %11, align 4
//CHECK-NEXT:   br label %return{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: return{{[0-9]+}}:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_2:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %fix_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2]]:
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %call.fr_cast_to_addr = call i32 @fr_cast_to_addr(i256 %1)
//CHECK-NEXT:   %mul_addr = mul i32 1, %call.fr_cast_to_addr
//CHECK-NEXT:   %add_addr = add i32 %mul_addr, 1
//CHECK-NEXT:   %2 = getelementptr i256, i256* %fix_0, i32 0
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 %add_addr
//CHECK-NEXT:   store i256 %3, i256* %4, align 4
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
//CHECK-LABEL: define void @InnerLoops_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK:      unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %6 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 0, i256* %6, align 4
//CHECK-NEXT:   %7 = bitcast [5 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %7, [0 x i256]* %0)
//CHECK-NEXT:   %8 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %8, align 4
//CHECK-NEXT:   %9 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 0, i256* %9, align 4
//CHECK-NEXT:   %10 = bitcast [5 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %10, [0 x i256]* %0, i256* %11)
//CHECK-NEXT:   %12 = bitcast [5 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %13 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %12, [0 x i256]* %0, i256* %13)
//CHECK-NEXT:   %14 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %14, align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
