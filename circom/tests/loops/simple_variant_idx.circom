pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template SimpleVariantIdx(n) {
    signal input in;
    signal output out[n];

	var lc;
    for (var i = 0; i < n; i++) {
        out[i] <-- in;	//StoreBucket
        lc = out[i];	//StoreBucket
        //i++			//StoreBucket
    }
}

component main = SimpleVariantIdx(3);

//NOTE: For indexing dependent on the loop variable, need to compute pointer
//	reference outside of the body function call. All else can be done inside.
//
// %0 (i.e. signal arena) = [ out[0], out[1], out[2], in ]
// %lvars =  [ n, lc, i ]
// %subcmps = []
//
//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK:      store{{[0-9]+}}:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 3
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr i256, i256* %fix_[[X1]], i32 0
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY:
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %3 = getelementptr i256, i256* %fix_[[X2]], i32 0
//CHECK-NEXT:   %4 = load i256, i256* %3, align 4
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 %4, i256* %5, align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY:
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %7 = load i256, i256* %6, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %7, i256 1)
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 %call.fr_add, i256* %8, align 4
//CHECK-NEXT:   br label %return{{[0-9]+}}
//CHECK-EMPTY:
//CHECK-NEXT: return{{[0-9]+}}:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @SimpleVariantIdx_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9]+]])
//CHECK:      unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %4 = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID]]([0 x i256]* %4, [0 x i256]* %0, i256* %5, i256* %6)
//CHECK-NEXT:   %7 = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID]]([0 x i256]* %7, [0 x i256]* %0, i256* %8, i256* %9)
//CHECK-NEXT:   %10 = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   %12 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID]]([0 x i256]* %10, [0 x i256]* %0, i256* %11, i256* %12)
//CHECK-NEXT:   br label %prologue
