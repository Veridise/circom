pragma circom 2.0.0;

// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template FixIdxNested() {
    var arr[9] = [8, 7, 6, 5, 4, 3, 2, 1, 0];
    signal out[9];
    for (var i = 0; i < 9; i++) {
        out[arr[i]] <-- arr[i];
    }
}

component main = FixIdxNested();

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %sig_0, i256* %var_1){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_0, i32 0
//CHECK-NEXT:   %[[T000:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_1, i32 0
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T000]], align 4
//CHECK-NEXT:   store i256 %[[T001]], i256* %[[T002]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 9
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 9
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T003]], align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %[[T004]], i256 1)
//CHECK-NEXT:   store i256 %call.fr_add, i256* %[[T005]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }

//CHECK-LABEL: define{{.*}} void @FixIdxNested_0_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9a-zA-Z_\.]+]]){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [10 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY:
//CHECK:      unrolled_loop11:
//CHECK-NEXT:   %[[T011:[0-9a-zA-Z_\.]+]] = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T012:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 8
//CHECK-NEXT:   %[[T013:[0-9a-zA-Z_\.]+]] = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T014:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T013]], i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T011]], [0 x i256]* %[[ARG]], i256* %[[T012]], i256* %[[T014]])
//CHECK-NEXT:   %[[T015:[0-9a-zA-Z_\.]+]] = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T016:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 7
//CHECK-NEXT:   %[[T017:[0-9a-zA-Z_\.]+]] = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T018:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T017]], i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T015]], [0 x i256]* %[[ARG]], i256* %[[T016]], i256* %[[T018]])
//CHECK-NEXT:   %[[T019:[0-9a-zA-Z_\.]+]] = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T020:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 6
//CHECK-NEXT:   %[[T021:[0-9a-zA-Z_\.]+]] = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T022:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T021]], i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T019]], [0 x i256]* %[[ARG]], i256* %[[T020]], i256* %[[T022]])
//CHECK-NEXT:   %[[T023:[0-9a-zA-Z_\.]+]] = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T024:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 5
//CHECK-NEXT:   %[[T025:[0-9a-zA-Z_\.]+]] = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T026:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T025]], i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T023]], [0 x i256]* %[[ARG]], i256* %[[T024]], i256* %[[T026]])
//CHECK-NEXT:   %[[T027:[0-9a-zA-Z_\.]+]] = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T028:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 4
//CHECK-NEXT:   %[[T029:[0-9a-zA-Z_\.]+]] = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T030:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T029]], i32 0, i256 4
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T027]], [0 x i256]* %[[ARG]], i256* %[[T028]], i256* %[[T030]])
//CHECK-NEXT:   %[[T031:[0-9a-zA-Z_\.]+]] = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T032:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 3
//CHECK-NEXT:   %[[T033:[0-9a-zA-Z_\.]+]] = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T034:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T033]], i32 0, i256 5
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T031]], [0 x i256]* %[[ARG]], i256* %[[T032]], i256* %[[T034]])
//CHECK-NEXT:   %[[T035:[0-9a-zA-Z_\.]+]] = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T036:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 2
//CHECK-NEXT:   %[[T037:[0-9a-zA-Z_\.]+]] = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T038:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T037]], i32 0, i256 6
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T035]], [0 x i256]* %[[ARG]], i256* %[[T036]], i256* %[[T038]])
//CHECK-NEXT:   %[[T039:[0-9a-zA-Z_\.]+]] = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T040:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 1
//CHECK-NEXT:   %[[T041:[0-9a-zA-Z_\.]+]] = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T042:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T041]], i32 0, i256 7
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T039]], [0 x i256]* %[[ARG]], i256* %[[T040]], i256* %[[T042]])
//CHECK-NEXT:   %[[T043:[0-9a-zA-Z_\.]+]] = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T044:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 0
//CHECK-NEXT:   %[[T045:[0-9a-zA-Z_\.]+]] = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T046:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T045]], i32 0, i256 8
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T043]], [0 x i256]* %[[ARG]], i256* %[[T044]], i256* %[[T046]])
//CHECK-NEXT:   br label %prologue
