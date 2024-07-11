pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// %0 (i.e. signal arena) = [ out[0], out[1], out[2], in ]
// %lvars = [ n, lc, i ]
// %subcmps = []
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
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %sig_[[X1:[0-9]+]], i256* %sig_[[X2:[0-9]+]]){{.*}} {
//CHECK:      store{{[0-9]+}}:
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_[[X1]], i32 0
//CHECK-NEXT:   %[[T000:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 3
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T000]], align 4
//CHECK-NEXT:   store i256 %[[T001]], i256* %[[T002]], align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY:
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_[[X2]], i32 0
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T003]], align 4
//CHECK-NEXT:   store i256 %[[T004]], i256* %[[T005]], align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY:
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %[[T008:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[T006:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[T007:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T006]], align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %[[T007]], i256 1)
//CHECK-NEXT:   store i256 %call.fr_add, i256* %[[T008]], align 4
//CHECK-NEXT:   br label %return{{[0-9]+}}
//CHECK-EMPTY:
//CHECK-NEXT: return{{[0-9]+}}:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @SimpleVariantIdx_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %0)
//CHECK:      unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   %[[T006:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID]]([0 x i256]* %[[T004]], [0 x i256]* %0, i256* %[[T005]], i256* %[[T006]])
//CHECK-NEXT:   %[[T007:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T008:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %[[T009:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID]]([0 x i256]* %[[T007]], [0 x i256]* %0, i256* %[[T008]], i256* %[[T009]])
//CHECK-NEXT:   %[[T010:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T011:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   %[[T012:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID]]([0 x i256]* %[[T010]], [0 x i256]* %0, i256* %[[T011]], i256* %[[T012]])
//CHECK-NEXT:   br label %prologue
