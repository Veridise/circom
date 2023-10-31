pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template InnerLoops(n) {
    signal input a[n];
    var b[n];

    for (var i = 0; i < n; i++) {
        for (var j = 0; j <= i; j++) {
            // NOTE: When processing the outer loop, the following statement is determined NOT
            //  safe to move into a new function since it uses 'j' which is unknown. That results
            //  in the outer loop unrolling without extrating the body to a new function. Then
            //  the two copies of the inner loop are processed and their bodies are extracted to
            //  new functions and replaced with calls to those functions before unrolling. So
            //  it ends up creating two slightly different functions for this innermost body,
            //  one for each iteration of the outer loop (i.e. when b=0 and when b=1).
            b[i] += a[i - j];
        }
    }
}

component main = InnerLoops(2);
//
// %0 (i.e. signal arena) = { a[0], a[1] }
// %lvars = { n, b[0], b[1], i, j }
//
//unrolled code:
//	b[0] = b[0] + a[0 - 0 = 0];     //extracted function 1
//	b[1] = b[1] + a[1 - 0 = 1];     //extracted function 2
//	b[1] = b[1] + a[1 - 1 = 0];     //extracted function 2
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %call.fr_cast_to_addr = call i32 @fr_cast_to_addr(i256 %1)
//CHECK-NEXT:   %mul_addr = mul i32 1, %call.fr_cast_to_addr
//CHECK-NEXT:   %add_addr = add i32 %mul_addr, 1
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %call.fr_cast_to_addr1 = call i32 @fr_cast_to_addr(i256 %3)
//CHECK-NEXT:   %mul_addr2 = mul i32 1, %call.fr_cast_to_addr1
//CHECK-NEXT:   %add_addr3 = add i32 %mul_addr2, 1
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 %add_addr3
//CHECK-NEXT:   %5 = load i256, i256* %4, align 4
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %7 = load i256, i256* %6, align 4
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %9 = load i256, i256* %8, align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %7, i256 %9)
//CHECK-NEXT:   %call.fr_cast_to_addr4 = call i32 @fr_cast_to_addr(i256 %call.fr_sub)
//CHECK-NEXT:   %mul_addr5 = mul i32 1, %call.fr_cast_to_addr4
//CHECK-NEXT:   %add_addr6 = add i32 %mul_addr5, 0
//CHECK-NEXT:   %10 = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 %add_addr6
//CHECK-NEXT:   %11 = load i256, i256* %10, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %5, i256 %11)
//CHECK-NEXT:   %12 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 %add_addr
//CHECK-NEXT:   store i256 %call.fr_add, i256* %12, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %13 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %14 = load i256, i256* %13, align 4
//CHECK-NEXT:   %call.fr_add7 = call i256 @fr_add(i256 %14, i256 1)
//CHECK-NEXT:   %15 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 %call.fr_add7, i256* %15, align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
// 
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_2:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %fix_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %call.fr_cast_to_addr = call i32 @fr_cast_to_addr(i256 %1)
//CHECK-NEXT:   %mul_addr = mul i32 1, %call.fr_cast_to_addr
//CHECK-NEXT:   %add_addr = add i32 %mul_addr, 1
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %call.fr_cast_to_addr1 = call i32 @fr_cast_to_addr(i256 %3)
//CHECK-NEXT:   %mul_addr2 = mul i32 1, %call.fr_cast_to_addr1
//CHECK-NEXT:   %add_addr3 = add i32 %mul_addr2, 1
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 %add_addr3
//CHECK-NEXT:   %5 = load i256, i256* %4, align 4
//CHECK-NEXT:   %6 = getelementptr i256, i256* %fix_0, i32 0
//CHECK-NEXT:   %7 = load i256, i256* %6, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %5, i256 %7)
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 %add_addr
//CHECK-NEXT:   store i256 %call.fr_add, i256* %8, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %10 = load i256, i256* %9, align 4
//CHECK-NEXT:   %call.fr_add4 = call i256 @fr_add(i256 %10, i256 1)
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 %call.fr_add4, i256* %11, align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @InnerLoops_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK:      unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %5 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %5, align 4
//CHECK-NEXT:   %6 = bitcast [5 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %6, [0 x i256]* %0)
//CHECK-NEXT:   %7 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 1, i256* %7, align 4
//CHECK-NEXT:   %8 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %8, align 4
//CHECK-NEXT:   %9 = bitcast [5 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %10 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %9, [0 x i256]* %0, i256* %10)
//CHECK-NEXT:   %11 = bitcast [5 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %12 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %11, [0 x i256]* %0, i256* %12)
//CHECK-NEXT:   %13 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 2, i256* %13, align 4
//CHECK-NEXT:   br label %prologue
