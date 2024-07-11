pragma circom 2.0.6;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template Sum(n) {
    signal input inp[n];
    signal output outp;

    var s = 0;

    for (var i = 0; i < n; i++) {
        s += inp[i];
    }

    outp <== s;
}

function nop(i) {
    return i;
}

template Caller() {
    signal input inp[4];
    signal output outp;

    component s = Sum(4);

    for (var i = 0; i < 4; i++) {
        s.inp[i] <== nop(inp[i]);
    }

    outp <== s.outp;
}

component main = Caller();

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9a-zA-Z_\.]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %sig_[[X1:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9a-zA-Z_\.]+]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T000:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T000]], align 4
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_[[X1]], i32 0
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T002]], align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %[[T001]], i256 %[[T003]])
//CHECK-NEXT:   store i256 %call.fr_add, i256* %[[T004]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T007:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[T006:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T005]], align 4
//CHECK-NEXT:   %call.fr_add1 = call i256 @fr_add(i256 %[[T006]], i256 1)
//CHECK-NEXT:   store i256 %call.fr_add1, i256* %[[T007]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9a-zA-Z_\.]+\.F}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %subsig_[[X1:[0-9]+]], i256* %sig_[[X2:[0-9]+]], [0 x i256]* %sub_[[X3:[0-9]+]], i256* %subc_[[X4:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2:[0-9a-zA-Z_\.]+\.F]]:
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY: 
//CHECK-NEXT: call1:
//CHECK-NEXT:   %nop_0_arena = alloca [1 x i256], align 8
//CHECK-NEXT:   %[[T000:[0-9a-zA-Z_\.]+]] = getelementptr [1 x i256], [1 x i256]* %nop_0_arena, i32 0, i32 0
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_[[X2]], i32 0
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T001]], align 4
//CHECK-NEXT:   store i256 %[[T002]], i256* %[[T000]], align 4
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_\.]+]] = bitcast [1 x i256]* %nop_0_arena to i256*
//CHECK-NEXT:   %call.nop_0 = call i256 @nop_0(i256* %[[T003]])
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subsig_[[X1]], i32 0
//CHECK-NEXT:   store i256 %call.nop_0, i256* %[[T004]], align 4
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T004]], align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %call.nop_0, i256 %[[T005]], i1* %constraint)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T007:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subc_[[X4]], i32 0
//CHECK-NEXT:   %[[T006:[0-9a-zA-Z_\.]+]] = load i256, i256* %subc_[[X4]], align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %[[T006]], i256 1)
//CHECK-NEXT:   store i256 %call.fr_sub, i256* %[[T007]], align 4
//CHECK-NEXT:   br label %fold_false3
//CHECK-EMPTY: 
//CHECK-NEXT: fold_false3:
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %[[T010:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   %[[T008:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   %[[T009:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T008]], align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %[[T009]], i256 1)
//CHECK-NEXT:   store i256 %call.fr_add, i256* %[[T010]], align 4
//CHECK-NEXT:   br label %return5
//CHECK-EMPTY: 
//CHECK-NEXT: return5:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9a-zA-Z_\.]+\.T}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %subsig_[[X1:[0-9]+]], i256* %sig_[[X2:[0-9]+]], [0 x i256]* %sub_[[X3:[0-9]+]], i256* %subc_[[X4:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_3:[0-9a-zA-Z_\.]+\.T]]:
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY: 
//CHECK-NEXT: call1:
//CHECK-NEXT:   %nop_0_arena = alloca [1 x i256], align 8
//CHECK-NEXT:   %[[T000:[0-9a-zA-Z_\.]+]] = getelementptr [1 x i256], [1 x i256]* %nop_0_arena, i32 0, i32 0
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_[[X2]], i32 0
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T001]], align 4
//CHECK-NEXT:   store i256 %[[T002]], i256* %[[T000]], align 4
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_\.]+]] = bitcast [1 x i256]* %nop_0_arena to i256*
//CHECK-NEXT:   %call.nop_0 = call i256 @nop_0(i256* %[[T003]])
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subsig_[[X1]], i32 0
//CHECK-NEXT:   store i256 %call.nop_0, i256* %[[T004]], align 4
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T004]], align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %call.nop_0, i256 %[[T005]], i1* %constraint)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T007:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subc_[[X4]], i32 0
//CHECK-NEXT:   %[[T006:[0-9a-zA-Z_\.]+]] = load i256, i256* %subc_[[X4]], align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %[[T006]], i256 1)
//CHECK-NEXT:   store i256 %call.fr_sub, i256* %[[T007]], align 4
//CHECK-NEXT:   br label %fold_true3
//CHECK-EMPTY: 
//CHECK-NEXT: fold_true3:
//CHECK-NEXT:   call void @Sum_0_run([0 x i256]* %sub_[[X3]])
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %[[T010:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   %[[T008:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   %[[T009:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T008]], align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %[[T009]], i256 1)
//CHECK-NEXT:   store i256 %call.fr_add, i256* %[[T010]], align 4
//CHECK-NEXT:   br label %return5
//CHECK-EMPTY: 
//CHECK-NEXT: return5:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @Sum_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [3 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_\.]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 4, i256* %[[T001]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_\.]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T002]], align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_\.]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 0, i256* %[[T003]], align 4
//CHECK-NEXT:   br label %unrolled_loop4
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop4:
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T004]], [0 x i256]* %0, i256* %[[T005]])
//CHECK-NEXT:   %[[T006:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T007:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T006]], [0 x i256]* %0, i256* %[[T007]])
//CHECK-NEXT:   %[[T008:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T009:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T008]], [0 x i256]* %0, i256* %[[T009]])
//CHECK-NEXT:   %[[T010:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T011:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 4
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T010]], [0 x i256]* %0, i256* %[[T011]])
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %[[T014:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   %[[T012:[0-9a-zA-Z_\.]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T013:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T012]], align 4
//CHECK-NEXT:   store i256 %[[T013]], i256* %[[T014]], align 4
//CHECK-NEXT:   %[[T015:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T014]], align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T013]], i256 %[[T015]], i1* %constraint)
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
// 
//CHECK-LABEL: define{{.*}} void @Caller_1_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [1 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [1 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %create_cmp1
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp1:
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_\.]+]] = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0
//CHECK-NEXT:   call void @Sum_0_build({ [0 x i256]*, i32 }* %[[T001]])
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_\.]+]] = getelementptr [1 x i256], [1 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 0, i256* %[[T002]], align 4
//CHECK-NEXT:   br label %unrolled_loop3
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop3:
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_\.]+]] = bitcast [1 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_\.]+]] = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T004]], align 8
//CHECK-NEXT:   %[[T006:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T005]], i32 0
//CHECK-NEXT:   %[[T007:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T006]], i32 0, i256 1
//CHECK-NEXT:   %[[T008:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %[[T009:[0-9a-zA-Z_\.]+]] = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T010:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T009]], align 8
//CHECK-NEXT:   %[[T011:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T010]], i32 0
//CHECK-NEXT:   %[[T012:[0-9a-zA-Z_\.]+]] = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %[[T013:[0-9a-zA-Z_\.]+]] = bitcast i32* %[[T012]] to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T003]], [0 x i256]* %0, i256* %[[T007]], i256* %[[T008]], [0 x i256]* %[[T011]], i256* %[[T013]])
//CHECK-NEXT:   %[[T014:[0-9a-zA-Z_\.]+]] = bitcast [1 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T015:[0-9a-zA-Z_\.]+]] = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T016:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T015]], align 8
//CHECK-NEXT:   %[[T017:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T016]], i32 0
//CHECK-NEXT:   %[[T018:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T017]], i32 0, i256 2
//CHECK-NEXT:   %[[T019:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   %[[T020:[0-9a-zA-Z_\.]+]] = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T021:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T020]], align 8
//CHECK-NEXT:   %[[T022:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T021]], i32 0
//CHECK-NEXT:   %[[T023:[0-9a-zA-Z_\.]+]] = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %[[T024:[0-9a-zA-Z_\.]+]] = bitcast i32* %[[T023]] to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T014]], [0 x i256]* %0, i256* %[[T018]], i256* %[[T019]], [0 x i256]* %[[T022]], i256* %[[T024]])
//CHECK-NEXT:   %[[T025:[0-9a-zA-Z_\.]+]] = bitcast [1 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T026:[0-9a-zA-Z_\.]+]] = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T027:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T026]], align 8
//CHECK-NEXT:   %[[T028:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T027]], i32 0
//CHECK-NEXT:   %[[T029:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T028]], i32 0, i256 3
//CHECK-NEXT:   %[[T030:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   %[[T031:[0-9a-zA-Z_\.]+]] = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T032:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T031]], align 8
//CHECK-NEXT:   %[[T033:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T032]], i32 0
//CHECK-NEXT:   %[[T034:[0-9a-zA-Z_\.]+]] = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %[[T035:[0-9a-zA-Z_\.]+]] = bitcast i32* %[[T034]] to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T025]], [0 x i256]* %0, i256* %[[T029]], i256* %[[T030]], [0 x i256]* %[[T033]], i256* %[[T035]])
//CHECK-NEXT:   %[[T036:[0-9a-zA-Z_\.]+]] = bitcast [1 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T037:[0-9a-zA-Z_\.]+]] = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T038:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T037]], align 8
//CHECK-NEXT:   %[[T039:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T038]], i32 0
//CHECK-NEXT:   %[[T040:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T039]], i32 0, i256 4
//CHECK-NEXT:   %[[T041:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 4
//CHECK-NEXT:   %[[T042:[0-9a-zA-Z_\.]+]] = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T043:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T042]], align 8
//CHECK-NEXT:   %[[T044:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T043]], i32 0
//CHECK-NEXT:   %[[T045:[0-9a-zA-Z_\.]+]] = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %[[T046:[0-9a-zA-Z_\.]+]] = bitcast i32* %[[T045]] to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_3]]([0 x i256]* %[[T036]], [0 x i256]* %0, i256* %[[T040]], i256* %[[T041]], [0 x i256]* %[[T044]], i256* %[[T046]])
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %[[T051:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   %[[T047:[0-9a-zA-Z_\.]+]] = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T048:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T047]], align 8
//CHECK-NEXT:   %[[T049:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T048]], i32 0, i32 0
//CHECK-NEXT:   %[[T050:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T049]], align 4
//CHECK-NEXT:   store i256 %[[T050]], i256* %[[T051]], align 4
//CHECK-NEXT:   %[[T052:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T051]], align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T050]], i256 %[[T052]], i1* %constraint)
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
