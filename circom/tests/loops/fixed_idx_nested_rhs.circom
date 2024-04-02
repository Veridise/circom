pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// This case initially triggered the "assert!(bucket_to_args.is_empty());" line in body_extractor.rs
//  because the entire expression 'in[arr[i]]'' is replaced but the 'arr[i]' expression
//  is also listed in the "bucket_to_args" map as a safe replacement.
template FixIdxNested() {
    signal input in[16];
    signal output out[16];
    
    var arr[16] = [0, 5, 10, 15, 4, 9, 14, 3, 8, 13, 2, 7, 12, 1, 6, 11];

    for (var i = 0; i < 16; i++) {
        out[i] <== in[arr[i]];
    }
}

component main = FixIdxNested();

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %sig_0, i256* %sig_1){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %sig_0, i32 0
//CHECK-NEXT:   %[[T000:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %sig_1, i32 0
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T000]], align 4
//CHECK-NEXT:   store i256 %[[T001]], i256* %[[T002]], align 4
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T002]], align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T001]], i256 %[[T003]], i1* %constraint)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T006:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 16
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 16
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T004]], align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %[[T005]], i256 1)
//CHECK-NEXT:   store i256 %call.fr_add, i256* %[[T006]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @FixIdxNested_0_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9a-zA-Z_.]+]]){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [17 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY:
//CHECK:      unrolled_loop18:
//CHECK-NEXT:   %[[T018:[0-9a-zA-Z_.]+]] = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T019:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 0
//CHECK-NEXT:   %[[T020:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 16
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T018]], [0 x i256]* %[[ARG]], i256* %[[T019]], i256* %[[T020]])
//CHECK-NEXT:   %[[T021:[0-9a-zA-Z_.]+]] = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T022:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 1
//CHECK-NEXT:   %[[T023:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 21
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T021]], [0 x i256]* %[[ARG]], i256* %[[T022]], i256* %[[T023]])
//CHECK-NEXT:   %[[T024:[0-9a-zA-Z_.]+]] = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T025:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 2
//CHECK-NEXT:   %[[T026:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 26
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T024]], [0 x i256]* %[[ARG]], i256* %[[T025]], i256* %[[T026]])
//CHECK-NEXT:   %[[T027:[0-9a-zA-Z_.]+]] = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T028:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 3
//CHECK-NEXT:   %[[T029:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 31
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T027]], [0 x i256]* %[[ARG]], i256* %[[T028]], i256* %[[T029]])
//CHECK-NEXT:   %[[T030:[0-9a-zA-Z_.]+]] = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T031:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 4
//CHECK-NEXT:   %[[T032:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 20
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T030]], [0 x i256]* %[[ARG]], i256* %[[T031]], i256* %[[T032]])
//CHECK-NEXT:   %[[T033:[0-9a-zA-Z_.]+]] = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T034:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 5
//CHECK-NEXT:   %[[T035:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 25
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T033]], [0 x i256]* %[[ARG]], i256* %[[T034]], i256* %[[T035]])
//CHECK-NEXT:   %[[T036:[0-9a-zA-Z_.]+]] = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T037:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 6
//CHECK-NEXT:   %[[T038:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 30
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T036]], [0 x i256]* %[[ARG]], i256* %[[T037]], i256* %[[T038]])
//CHECK-NEXT:   %[[T039:[0-9a-zA-Z_.]+]] = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T040:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 7
//CHECK-NEXT:   %[[T041:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 19
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T039]], [0 x i256]* %[[ARG]], i256* %[[T040]], i256* %[[T041]])
//CHECK-NEXT:   %[[T042:[0-9a-zA-Z_.]+]] = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T043:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 8
//CHECK-NEXT:   %[[T044:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 24
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T042]], [0 x i256]* %[[ARG]], i256* %[[T043]], i256* %[[T044]])
//CHECK-NEXT:   %[[T045:[0-9a-zA-Z_.]+]] = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T046:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 9
//CHECK-NEXT:   %[[T047:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 29
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T045]], [0 x i256]* %[[ARG]], i256* %[[T046]], i256* %[[T047]])
//CHECK-NEXT:   %[[T048:[0-9a-zA-Z_.]+]] = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T049:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 10
//CHECK-NEXT:   %[[T050:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 18
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T048]], [0 x i256]* %[[ARG]], i256* %[[T049]], i256* %[[T050]])
//CHECK-NEXT:   %[[T051:[0-9a-zA-Z_.]+]] = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T052:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 11
//CHECK-NEXT:   %[[T053:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 23
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T051]], [0 x i256]* %[[ARG]], i256* %[[T052]], i256* %[[T053]])
//CHECK-NEXT:   %[[T054:[0-9a-zA-Z_.]+]] = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T055:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 12
//CHECK-NEXT:   %[[T056:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 28
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T054]], [0 x i256]* %[[ARG]], i256* %[[T055]], i256* %[[T056]])
//CHECK-NEXT:   %[[T057:[0-9a-zA-Z_.]+]] = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T058:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 13
//CHECK-NEXT:   %[[T059:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 17
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T057]], [0 x i256]* %[[ARG]], i256* %[[T058]], i256* %[[T059]])
//CHECK-NEXT:   %[[T060:[0-9a-zA-Z_.]+]] = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T061:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 14
//CHECK-NEXT:   %[[T062:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 22
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T060]], [0 x i256]* %[[ARG]], i256* %[[T061]], i256* %[[T062]])
//CHECK-NEXT:   %[[T063:[0-9a-zA-Z_.]+]] = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T064:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 15
//CHECK-NEXT:   %[[T065:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 27
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T063]], [0 x i256]* %[[ARG]], i256* %[[T064]], i256* %[[T065]])
//CHECK-NEXT:   br label %prologue
