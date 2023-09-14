pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// %0 (i.e. signal arena)  = [ out[0], out[1], out[2], out[3], in ]
// %lvars =  [ n, i, j ]
// %subcmps = []
template Num2Bits(n) {
    signal input in;
    signal output out[n*n];

    for (var i = 0; i < n; i++) {
    	for (var j = 0; j < n; j++) {
            // NOTE: When processing the outer loop, the following statement is determined NOT
            //  safe to move into a new function since it uses 'j' which is unknown. That results
            //  in the outer loop unrolling without extrating the body to a new function. Then
            //  the two copies of the inner loop are processed and their bodies are extracted to
            //  new functions and replaced with calls to those functions before unrolling.
            //  This result is logically correct but not optimal because the 2 extracted body
            //  functions are identical.
        	out[i*n + j] <-- in;
        }
    }
}

component main = Num2Bits(2);
//
// %0 (i.e. signal arena) = { out[0], out[1], out[2], out[3], in }
// %lvars = { n, i, j }
//
//unrolled code:
//	out[0] = in;
//	out[1] = in;
//	out[2] = in;
//	out[3] = in;
//
//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %fixed_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.{{.*}}[[$F_ID_1]]:
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 4
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr i256, i256* %fixed_0, i32 0
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %4 = load i256, i256* %3, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %4, i256 1)
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 %call.fr_add, i256* %5, align 4
//CHECK-NEXT:   br label %return{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: return{{[0-9]+}}:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
// 
//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_2:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %fixed_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.{{.*}}[[$F_ID_2]]:
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 4
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr i256, i256* %fixed_0, i32 0
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %4 = load i256, i256* %3, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %4, i256 1)
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 %call.fr_add, i256* %5, align 4
//CHECK-NEXT:   br label %return{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: return{{[0-9]+}}:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @Num2Bits_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK:      unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %3 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 0, i256* %3, align 4
//CHECK-NEXT:   %4 = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.{{.*}}[[$F_ID_1]]([0 x i256]* %4, [0 x i256]* %0, i256* %5)
//CHECK-NEXT:   %6 = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %7 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.{{.*}}[[$F_ID_1]]([0 x i256]* %6, [0 x i256]* %0, i256* %7)
//CHECK-NEXT:   %8 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %9 = load i256, i256* %8, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %9, i256 1)
//CHECK-NEXT:   %10 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 %call.fr_add, i256* %10, align 4
//CHECK-NEXT:   %11 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 0, i256* %11, align 4
//CHECK-NEXT:   %12 = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %13 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.{{.*}}[[$F_ID_2]]([0 x i256]* %12, [0 x i256]* %0, i256* %13)
//CHECK-NEXT:   %14 = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %15 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.{{.*}}[[$F_ID_2]]([0 x i256]* %14, [0 x i256]* %0, i256* %15)
//CHECK-NEXT:   %16 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %17 = load i256, i256* %16, align 4
//CHECK-NEXT:   %call.fr_add15 = call i256 @fr_add(i256 %17, i256 1)
//CHECK-NEXT:   %18 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 %call.fr_add15, i256* %18, align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
