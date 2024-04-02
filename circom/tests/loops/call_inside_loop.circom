pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

//arena = { a[0], a[1], n, b, c, d, e, f, g}
function fun(a, n, b, c, d, e, f, g) {
	var x[5];
    for (var i = 0; i < n; i++) {
    	x[i] = a[i] + b + c + d + e + f;
    }
	return x[0] + x[2] + x[4];
}

//signal_arena = { out, in }
//lvars = { m, n, a[0], a[1], b[0], b[1], i }
template CallInLoop(n, m) {
    signal input in;
    signal output out;
    var a[n];
    for (var i = 0; i < n; i++) {
    	a[i] = m + in;
    }
    var b[n];
    for (var i = 0; i < n; i++) {
    	b[i] = fun(a, n, m, m, m, m, m, m);
    }
    out <-- b[0];
}

component main = CallInLoop(2, 3);

//
//     var a[2];
//     i = 0;
//     	a[0] = 3 + in;
//     i = 1;
//     	a[1] = 3 + in;
//     i = 2;
//     var b[2];
//     i = 0;
//     	b[0] = fun(a, 2, 3, 3, 3, 3, 3, 3);
//     i = 1;
//     	b[1] = fun(a, 2, 3, 3, 3, 3, 3, 3);
//     i = 2;
//     out <-- b[0];
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %var_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %var_0, i32 0
//CHECK-NEXT:   %[[T000:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 1
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T000]], align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 3, i256 %[[T001]])
//CHECK-NEXT:   store i256 %call.fr_add, i256* %[[T002]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T003]], align 4
//CHECK-NEXT:   %call.fr_add1 = call i256 @fr_add(i256 %[[T004]], i256 1)
//CHECK-NEXT:   store i256 %call.fr_add1, i256* %[[T005]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_2:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %var_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2]]:
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY: 
//CHECK-NEXT: call1:
//CHECK-NEXT:   %fun_0_arena = alloca [15 x i256], align 8
//CHECK-NEXT:   %[[T000:[0-9a-zA-Z_.]+]] = getelementptr [15 x i256], [15 x i256]* %fun_0_arena, i32 0, i32 0
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[COPY_SRC_0:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[T001]], i32 0
//CHECK-NEXT:   %[[COPY_DST_0:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[T000]], i32 0
//CHECK-NEXT:   %[[COPY_VAL_0:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_0]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_0]], i256* %[[COPY_DST_0]], align 4
//CHECK-NEXT:   %[[COPY_SRC_1:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[T001]], i32 1
//CHECK-NEXT:   %[[COPY_DST_1:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[T000]], i32 1
//CHECK-NEXT:   %[[COPY_VAL_1:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_1]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_1]], i256* %[[COPY_DST_1]], align 4
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_.]+]] = getelementptr [15 x i256], [15 x i256]* %fun_0_arena, i32 0, i32 2
//CHECK-NEXT:   store i256 2, i256* %[[T002]], align 4
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_.]+]] = getelementptr [15 x i256], [15 x i256]* %fun_0_arena, i32 0, i32 3
//CHECK-NEXT:   store i256 3, i256* %[[T003]], align 4
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_.]+]] = getelementptr [15 x i256], [15 x i256]* %fun_0_arena, i32 0, i32 4
//CHECK-NEXT:   store i256 3, i256* %[[T004]], align 4
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_.]+]] = getelementptr [15 x i256], [15 x i256]* %fun_0_arena, i32 0, i32 5
//CHECK-NEXT:   store i256 3, i256* %[[T005]], align 4
//CHECK-NEXT:   %[[T006:[0-9a-zA-Z_.]+]] = getelementptr [15 x i256], [15 x i256]* %fun_0_arena, i32 0, i32 6
//CHECK-NEXT:   store i256 3, i256* %[[T006]], align 4
//CHECK-NEXT:   %[[T007:[0-9a-zA-Z_.]+]] = getelementptr [15 x i256], [15 x i256]* %fun_0_arena, i32 0, i32 7
//CHECK-NEXT:   store i256 3, i256* %[[T007]], align 4
//CHECK-NEXT:   %[[T008:[0-9a-zA-Z_.]+]] = getelementptr [15 x i256], [15 x i256]* %fun_0_arena, i32 0, i32 8
//CHECK-NEXT:   store i256 3, i256* %[[T008]], align 4
//CHECK-NEXT:   %[[T009:[0-9a-zA-Z_.]+]] = bitcast [15 x i256]* %fun_0_arena to i256*
//CHECK-NEXT:   %call.fun_0 = call i256 @fun_0(i256* %[[T009]])
//CHECK-NEXT:   %[[T010:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %var_0, i32 0
//CHECK-NEXT:   store i256 %call.fun_0, i256* %[[T010]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T013:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %[[T011:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %[[T012:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T011]], align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %[[T012]], i256 1)
//CHECK-NEXT:   store i256 %call.fr_add, i256* %[[T013]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @CallInLoop_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9a-zA-Z_.]+]]){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [7 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_.]+]] = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 3, i256* %[[T001]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_.]+]] = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 2, i256* %[[T002]], align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_.]+]] = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 0, i256* %[[T003]], align 4
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_.]+]] = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 0, i256* %[[T004]], align 4
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_.]+]] = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %[[T005]], align 4
//CHECK-NEXT:   br label %unrolled_loop6
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop6:
//CHECK-NEXT:   %[[T006:[0-9a-zA-Z_.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T007:[0-9a-zA-Z_.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T008:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T007]], i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T006]], [0 x i256]* %[[ARG]], i256* %[[T008]])
//CHECK-NEXT:   %[[T009:[0-9a-zA-Z_.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T010:[0-9a-zA-Z_.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T011:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T010]], i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T009]], [0 x i256]* %[[ARG]], i256* %[[T011]])
//CHECK-NEXT:   br label %store7
//CHECK-EMPTY: 
//CHECK-NEXT: store7:
//CHECK-NEXT:   %[[T012:[0-9a-zA-Z_.]+]] = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %[[T012]], align 4
//CHECK-NEXT:   br label %store8
//CHECK-EMPTY: 
//CHECK-NEXT: store8:
//CHECK-NEXT:   %[[T013:[0-9a-zA-Z_.]+]] = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 0, i256* %[[T013]], align 4
//CHECK-NEXT:   br label %store9
//CHECK-EMPTY: 
//CHECK-NEXT: store9:
//CHECK-NEXT:   %[[T014:[0-9a-zA-Z_.]+]] = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 0, i256* %[[T014]], align 4
//CHECK-NEXT:   br label %unrolled_loop10
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop10:
//CHECK-NEXT:   %[[T015:[0-9a-zA-Z_.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T016:[0-9a-zA-Z_.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T017:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T016]], i32 0, i256 4
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T015]], [0 x i256]* %[[ARG]], i256* %[[T017]])
//CHECK-NEXT:   %[[T018:[0-9a-zA-Z_.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T019:[0-9a-zA-Z_.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T020:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T019]], i32 0, i256 5
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T018]], [0 x i256]* %[[ARG]], i256* %[[T020]])
//CHECK-NEXT:   br label %store11
//CHECK-EMPTY: 
//CHECK-NEXT: store11:
//CHECK-NEXT:   %[[T023:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i32 0
//CHECK-NEXT:   %[[T021:[0-9a-zA-Z_.]+]] = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %[[T022:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T021]], align 4
//CHECK-NEXT:   store i256 %[[T022]], i256* %[[T023]], align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
