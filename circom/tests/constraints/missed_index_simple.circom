pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// 3 signals, 0 lvars, 0 subcmps
template Mult() {
    signal input in[2];
    signal output out;
}

// 4 signals, 3 lvars, 2 subcmps
// lvars = [N, i, j]
template Good(N) {
    signal input inp[N][2];
    component c[N];

    for (var i = 0; i < N; i++) {
        c[i] = Mult();
        for (var j = 0; j < 2; j++) {
            c[i].in[j] <== inp[i][j];
        }

        c[i].out === 77;
    }
}

component main = Good(2);

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9a-zA-Z_\.]+\.F}}([0 x i256]* %lvars, [0 x i256]* %signals, 
//CHECK-SAME: i256* %subsig_[[X1:[0-9]+]], i256* %sig_[[X2:[0-9]+]], [0 x i256]* %sub_[[X1]], i256* %subc_[[X1]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9a-zA-Z_\.]+\.F]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subsig_[[X1]], i32 0
//CHECK-NEXT:   %[[T000:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_[[X2]], i32 0
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T000]], align 4
//CHECK-NEXT:   store i256 %[[T001]], i256* %[[T002]], align 4
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T002]], align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T001]], i256 %[[T003]], i1* %constraint)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subc_[[X1]], i32 0
//CHECK-NEXT:   store i256 1, i256* %[[T005]], align 4
//CHECK-NEXT:   br label %fold_false3
//CHECK-EMPTY: 
//CHECK-NEXT: fold_false3:
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %[[T008:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 1, i256* %[[T008]], align 4
//CHECK-NEXT:   br label %return5
//CHECK-EMPTY: 
//CHECK-NEXT: return5:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9a-zA-Z_\.]+\.T}}([0 x i256]* %lvars, [0 x i256]* %signals, 
//CHECK-SAME: i256* %subsig_[[X1:[0-9]+]], i256* %sig_[[X2:[0-9]+]], [0 x i256]* %sub_[[X1]], i256* %subc_[[X1]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2:[0-9a-zA-Z_\.]+\.T]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subsig_[[X1]], i32 0
//CHECK-NEXT:   %[[T000:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_[[X2]], i32 0
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T000]], align 4
//CHECK-NEXT:   store i256 %[[T001]], i256* %[[T002]], align 4
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T002]], align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T001]], i256 %[[T003]], i1* %constraint)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subc_[[X1]], i32 0
//CHECK-NEXT:   store i256 0, i256* %[[T005]], align 4
//CHECK-NEXT:   br label %fold_true3
//CHECK-EMPTY: 
//CHECK-NEXT: fold_true3:
//CHECK-NEXT:   call void @Mult_0_run([0 x i256]* %sub_[[X1]])
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %[[T008:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 2, i256* %[[T008]], align 4
//CHECK-NEXT:   br label %return5
//CHECK-EMPTY: 
//CHECK-NEXT: return5:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @Good_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARENA:[0-9a-zA-Z_\.]+]]){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [3 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [2 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_\.]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 2, i256* %[[T001]], align 4
//CHECK-NEXT:   br label %create_cmp2
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp2:
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0
//CHECK-NEXT:   call void @Mult_0_build({ [0 x i256]*, i32 }* %[[T002]])
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1
//CHECK-NEXT:   call void @Mult_0_build({ [0 x i256]*, i32 }* %[[T003]])
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_\.]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T004]], align 4
//CHECK-NEXT:   br label %unrolled_loop4
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop4:
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_\.]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 0, i256* %[[T005]], align 4
//CHECK-NEXT:   %[[T006:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T007:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T008:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T007]], align 8
//CHECK-NEXT:   %[[T009:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T008]], i32 0
//CHECK-NEXT:   %[[T010:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T009]], i32 0, i256 1
//CHECK-NEXT:   %[[T011:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARENA]], i32 0, i256 0
//CHECK-NEXT:   %[[T012:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T013:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T012]], align 8
//CHECK-NEXT:   %[[T014:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T013]], i32 0
//CHECK-NEXT:   %[[T015:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %[[T016:[0-9a-zA-Z_\.]+]] = bitcast i32* %[[T015]] to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T006]], [0 x i256]* %[[ARENA]], i256* %[[T010]], i256* %[[T011]], [0 x i256]* %[[T014]], i256* %[[T016]])
//CHECK-NEXT:   %[[T017:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T018:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T019:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T018]], align 8
//CHECK-NEXT:   %[[T020:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T019]], i32 0
//CHECK-NEXT:   %[[T021:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T020]], i32 0, i256 2
//CHECK-NEXT:   %[[T022:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARENA]], i32 0, i256 1
//CHECK-NEXT:   %[[T023:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T024:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T023]], align 8
//CHECK-NEXT:   %[[T025:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T024]], i32 0
//CHECK-NEXT:   %[[T026:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %[[T027:[0-9a-zA-Z_\.]+]] = bitcast i32* %[[T026]] to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T017]], [0 x i256]* %[[ARENA]], i256* %[[T021]], i256* %[[T022]], [0 x i256]* %[[T025]], i256* %[[T027]])
//CHECK-NEXT:   %[[T028:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T029:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T028]], align 8
//CHECK-NEXT:   %[[T030:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T029]], i32 0, i32 0
//CHECK-NEXT:   %[[T031:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T030]], align 4
//CHECK-NEXT:   %call.fr_eq = call i1 @fr_eq(i256 %[[T031]], i256 77)
//CHECK-NEXT:   call void @__assert(i1 %call.fr_eq)
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_value(i1 %call.fr_eq, i1* %constraint)
//CHECK-NEXT:   %[[T032:[0-9a-zA-Z_\.]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 1, i256* %[[T032]], align 4
//CHECK-NEXT:   %[[T033:[0-9a-zA-Z_\.]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 0, i256* %[[T033]], align 4
//CHECK-NEXT:   %[[T034:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T035:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T036:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T035]], align 8
//CHECK-NEXT:   %[[T037:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T036]], i32 0
//CHECK-NEXT:   %[[T038:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T037]], i32 0, i256 1
//CHECK-NEXT:   %[[T039:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARENA]], i32 0, i256 2
//CHECK-NEXT:   %[[T040:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T041:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T040]], align 8
//CHECK-NEXT:   %[[T042:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T041]], i32 0
//CHECK-NEXT:   %[[T043:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %[[T044:[0-9a-zA-Z_\.]+]] = bitcast i32* %[[T043]] to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T034]], [0 x i256]* %[[ARENA]], i256* %[[T038]], i256* %[[T039]], [0 x i256]* %[[T042]], i256* %[[T044]])
//CHECK-NEXT:   %[[T045:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T046:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T047:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T046]], align 8
//CHECK-NEXT:   %[[T048:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T047]], i32 0
//CHECK-NEXT:   %[[T049:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T048]], i32 0, i256 2
//CHECK-NEXT:   %[[T050:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARENA]], i32 0, i256 3
//CHECK-NEXT:   %[[T051:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T052:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T051]], align 8
//CHECK-NEXT:   %[[T053:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T052]], i32 0
//CHECK-NEXT:   %[[T054:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %[[T055:[0-9a-zA-Z_\.]+]] = bitcast i32* %[[T054]] to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T045]], [0 x i256]* %[[ARENA]], i256* %[[T049]], i256* %[[T050]], [0 x i256]* %[[T053]], i256* %[[T055]])
//CHECK-NEXT:   %[[T056:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T057:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T056]], align 8
//CHECK-NEXT:   %[[T058:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T057]], i32 0, i32 0
//CHECK-NEXT:   %[[T059:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T058]], align 4
//CHECK-NEXT:   %call.fr_eq22 = call i1 @fr_eq(i256 %[[T059]], i256 77)
//CHECK-NEXT:   call void @__assert(i1 %call.fr_eq22)
//CHECK-NEXT:   %constraint23 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_value(i1 %call.fr_eq22, i1* %constraint23)
//CHECK-NEXT:   %[[T060:[0-9a-zA-Z_\.]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 2, i256* %[[T060]], align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
