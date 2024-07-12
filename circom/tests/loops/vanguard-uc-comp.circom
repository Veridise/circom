pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// %0 (i.e. signal arena) = [ out[0], out[1], in ]
// %lvars = [ n, lc1, e2, i ]
// %subcmps = []
template Num2Bits(n) {
    signal input in;
    signal output out[n];

    var lc1=0;
    var e2=1;
    for (var i = 0; i<n; i++) {
        out[i] <-- (in >> i) & 1;
        out[i] * (out[i] -1 ) === 0;
        lc1 += out[i] * e2;
        e2 = e2+e2;
    }

    lc1 === in;
}

component main = Num2Bits(2);

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID:[0-9a-zA-Z_\.]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %sig_[[X1:[0-9]+]], i256* %sig_[[X2:[0-9]+]], i256* %sig_[[X3:[0-9]+]], i256* %sig_[[X4:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_[[X1]], i32 0
//CHECK-NEXT:   %[[T000:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 2
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T000]], align 4
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T002]], align 4
//CHECK-NEXT:   %call.fr_shr = call i256 @fr_shr(i256 %[[T001]], i256 %[[T003]])
//CHECK-NEXT:   %call.fr_bit_and = call i256 @fr_bit_and(i256 %call.fr_shr, i256 1)
//CHECK-NEXT:   store i256 %call.fr_bit_and, i256* %[[T004]], align 4
//CHECK-NEXT:   br label %assert2
//CHECK-EMPTY: 
//CHECK-NEXT: assert2:
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_[[X2]], i32 0
//CHECK-NEXT:   %[[T006:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T005]], align 4
//CHECK-NEXT:   %[[T007:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_[[X3]], i32 0
//CHECK-NEXT:   %[[T008:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T007]], align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %[[T008]], i256 1)
//CHECK-NEXT:   %call.fr_mul = call i256 @fr_mul(i256 %[[T006]], i256 %call.fr_sub)
//CHECK-NEXT:   %call.fr_eq = call i1 @fr_eq(i256 %call.fr_mul, i256 0)
//CHECK-NEXT:   call void @__assert(i1 %call.fr_eq)
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_value(i1 %call.fr_eq, i1* %constraint)
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T015:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T009:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T010:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T009]], align 4
//CHECK-NEXT:   %[[T011:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_[[X4]], i32 0
//CHECK-NEXT:   %[[T012:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T011]], align 4
//CHECK-NEXT:   %[[T013:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[T014:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T013]], align 4
//CHECK-NEXT:   %call.fr_mul1 = call i256 @fr_mul(i256 %[[T012]], i256 %[[T014]])
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %[[T010]], i256 %call.fr_mul1)
//CHECK-NEXT:   store i256 %call.fr_add, i256* %[[T015]], align 4
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %[[T020:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[T016:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[T017:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T016]], align 4
//CHECK-NEXT:   %[[T018:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[T019:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T018]], align 4
//CHECK-NEXT:   %call.fr_add2 = call i256 @fr_add(i256 %[[T017]], i256 %[[T019]])
//CHECK-NEXT:   store i256 %call.fr_add2, i256* %[[T020]], align 4
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %[[T023:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %[[T021:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %[[T022:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T021]], align 4
//CHECK-NEXT:   %call.fr_add3 = call i256 @fr_add(i256 %[[T022]], i256 1)
//CHECK-NEXT:   store i256 %call.fr_add3, i256* %[[T023]], align 4
//CHECK-NEXT:   br label %return6
//CHECK-EMPTY: 
//CHECK-NEXT: return6:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @Num2Bits_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9]+]]){{.*}} {
//CHECK:      unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_\.]+]] = bitcast [4 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T006:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 0
//CHECK-NEXT:   %[[T007:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 0
//CHECK-NEXT:   %[[T008:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 0
//CHECK-NEXT:   %[[T009:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID]]([0 x i256]* %[[T005]], [0 x i256]* %[[ARG]], i256* %[[T006]], i256* %[[T007]], i256* %[[T008]], i256* %[[T009]])
//CHECK-NEXT:   %[[T010:[0-9a-zA-Z_\.]+]] = bitcast [4 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T011:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 1
//CHECK-NEXT:   %[[T012:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 1
//CHECK-NEXT:   %[[T013:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 1
//CHECK-NEXT:   %[[T014:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID]]([0 x i256]* %[[T010]], [0 x i256]* %[[ARG]], i256* %[[T011]], i256* %[[T012]], i256* %[[T013]], i256* %[[T014]])
//CHECK-NEXT:   br label %assert{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: assert{{[0-9]+}}:
//CHECK-NEXT:   %[[T015:[0-9a-zA-Z_\.]+]] = getelementptr [4 x i256], [4 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T016:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T015]], align 4
//CHECK-NEXT:   %[[T017:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i32 2
//CHECK-NEXT:   %[[T018:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T017]], align 4
//CHECK-NEXT:   %call.fr_eq = call i1 @fr_eq(i256 %[[T016]], i256 %[[T018]])
//CHECK-NEXT:   call void @__assert(i1 %call.fr_eq)
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_value(i1 %call.fr_eq, i1* %constraint)
//CHECK-NEXT:   br label %prologue
