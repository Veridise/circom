pragma circom 2.0.0;
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

template SubCmps4(n) {
    signal input inp[n*2];
    signal output outp[2];

    component a = Sum(n);
    component b = Sum(n);

    for (var i = 0; i < n*2; i++) {
        if (i % 2 == 0) {
            a.inp[i\2] <== inp[i];
        } else {
            b.inp[i\2] <== inp[i];
        }
    }
    outp[0] <-- a.outp;
    outp[1] <-- b.outp;
}

component main = SubCmps4(3);

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %sig_[[X1:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9]+]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T000:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T000]], align 4
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_0, i32 0
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
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+\.T\.F}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %subsig_[[X1:[0-9]+]], i256* %sig_[[X2:[0-9]+]], i256* %subsig_[[X3:[0-9]+]],
//CHECK-SAME:  i256* %sig_[[X4:[0-9]+]], [0 x i256]* %sub_[[X3]], i256* %subc_[[X3]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2:[0-9]+\.T\.F]]:
//CHECK-NEXT:   br label %fold_true1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_true1:
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subsig_[[X1]], i32 0
//CHECK-NEXT:   %[[T000:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_[[X2]], i32 0
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T000]], align 4
//CHECK-NEXT:   store i256 %[[T001]], i256* %[[T002]], align 4
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T002]], align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T001]], i256 %[[T003]], i1* %constraint)
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subc_[[X3]], i32 0
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_\.]+]] = load i256, i256* %subc_[[X3]], align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %[[T004]], i256 1)
//CHECK-NEXT:   store i256 %call.fr_sub, i256* %[[T005]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T008:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T006:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T007:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T006]], align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %[[T007]], i256 1)
//CHECK-NEXT:   store i256 %call.fr_add, i256* %[[T008]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+\.F\.F}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %subsig_[[X1:[0-9]+]], i256* %sig_[[X2:[0-9]+]], i256* %subsig_[[X3:[0-9]+]],
//CHECK-SAME:  i256* %sig_[[X4:[0-9]+]], [0 x i256]* %sub_[[X3]], i256* %subc_[[X3]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_3:[0-9]+\.F\.F]]:
//CHECK-NEXT:   br label %fold_false1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_false1:
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subsig_[[X3]], i32 0
//CHECK-NEXT:   %[[T000:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_[[X4]], i32 0
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T000]], align 4
//CHECK-NEXT:   store i256 %[[T001]], i256* %[[T002]], align 4
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T002]], align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T001]], i256 %[[T003]], i1* %constraint)
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subc_[[X3]], i32 0
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_\.]+]] = load i256, i256* %subc_[[X3]], align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %[[T004]], i256 1)
//CHECK-NEXT:   store i256 %call.fr_sub, i256* %[[T005]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T008:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T006:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T007:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T006]], align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %[[T007]], i256 1)
//CHECK-NEXT:   store i256 %call.fr_add, i256* %[[T008]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+\.T\.T}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %subsig_[[X1:[0-9]+]], i256* %sig_[[X2:[0-9]+]], i256* %subsig_[[X3:[0-9]+]],
//CHECK-SAME:  i256* %sig_[[X4:[0-9]+]], [0 x i256]* %sub_[[X3]], i256* %subc_[[X3]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_4:[0-9]+\.T\.T]]:
//CHECK-NEXT:   br label %fold_true1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_true1:
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subsig_[[X1]], i32 0
//CHECK-NEXT:   %[[T000:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_[[X2]], i32 0
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T000]], align 4
//CHECK-NEXT:   store i256 %[[T001]], i256* %[[T002]], align 4
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T002]], align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T001]], i256 %[[T003]], i1* %constraint)
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subc_[[X3]], i32 0
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_\.]+]] = load i256, i256* %subc_[[X3]], align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %[[T004]], i256 1)
//CHECK-NEXT:   store i256 %call.fr_sub, i256* %[[T005]], align 4
//CHECK-NEXT:   call void @Sum_0_run([0 x i256]* %sub_[[X3]])
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T008:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T006:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T007:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T006]], align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %[[T007]], i256 1)
//CHECK-NEXT:   store i256 %call.fr_add, i256* %[[T008]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+\.F\.T}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %subsig_[[X1:[0-9]+]], i256* %sig_[[X2:[0-9]+]], i256* %subsig_[[X3:[0-9]+]],
//CHECK-SAME:  i256* %sig_[[X4:[0-9]+]], [0 x i256]* %sub_[[X3]], i256* %subc_[[X3]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_5:[0-9]+\.F\.T]]:
//CHECK-NEXT:   br label %fold_false1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_false1:
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subsig_[[X3]], i32 0
//CHECK-NEXT:   %[[T000:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_[[X4]], i32 0
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T000]], align 4
//CHECK-NEXT:   store i256 %[[T001]], i256* %[[T002]], align 4
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T002]], align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T001]], i256 %[[T003]], i1* %constraint)
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subc_[[X3]], i32 0
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_\.]+]] = load i256, i256* %subc_[[X3]], align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %[[T004]], i256 1)
//CHECK-NEXT:   store i256 %call.fr_sub, i256* %[[T005]], align 4
//CHECK-NEXT:   call void @Sum_0_run([0 x i256]* %sub_[[X3]])
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T008:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T006:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T007:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T006]], align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %[[T007]], i256 1)
//CHECK-NEXT:   store i256 %call.fr_add, i256* %[[T008]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
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
//CHECK-NEXT:   store i256 3, i256* %[[T001]], align 4
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
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %[[T012:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   %[[T010:[0-9a-zA-Z_\.]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T011:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T010]], align 4
//CHECK-NEXT:   store i256 %[[T011]], i256* %[[T012]], align 4
//CHECK-NEXT:   %[[T013:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T012]], align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T011]], i256 %[[T013]], i1* %constraint)
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define dso_local void @SubCmps4_1_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [2 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [2 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_\.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 3, i256* %[[T001]], align 4
//CHECK-NEXT:   br label %create_cmp2
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp2:
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0
//CHECK-NEXT:   call void @Sum_0_build({ [0 x i256]*, i32 }* %[[T002]])
//CHECK-NEXT:   br label %create_cmp3
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp3:
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1
//CHECK-NEXT:   call void @Sum_0_build({ [0 x i256]*, i32 }* %[[T003]])
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_\.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T004]], align 4
//CHECK-NEXT:   br label %unrolled_loop5
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop5:
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_\.]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T006:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T007:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T006]], align 8
//CHECK-NEXT:   %[[T008:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T007]], i32 0
//CHECK-NEXT:   %[[T009:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T008]], i32 0, i256 1
//CHECK-NEXT:   %[[T010:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   %[[T011:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T012:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T011]], align 8
//CHECK-NEXT:   %[[T013:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T012]], i32 0
//CHECK-NEXT:   %[[T014:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %[[T015:[0-9a-zA-Z_\.]+]] = bitcast i32* %[[T014]] to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T005]], [0 x i256]* %0, i256* %[[T009]], i256* %[[T010]], i256* null, i256* null, [0 x i256]* %[[T013]], i256* %[[T015]])
//CHECK-NEXT:   %[[T016:[0-9a-zA-Z_\.]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T017:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T018:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T017]], align 8
//CHECK-NEXT:   %[[T019:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T018]], i32 0
//CHECK-NEXT:   %[[T020:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T019]], i32 0, i256 1
//CHECK-NEXT:   %[[T021:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   %[[T022:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T023:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T022]], align 8
//CHECK-NEXT:   %[[T024:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T023]], i32 0
//CHECK-NEXT:   %[[T025:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %[[T026:[0-9a-zA-Z_\.]+]] = bitcast i32* %[[T025]] to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_3]]([0 x i256]* %[[T016]], [0 x i256]* %0, i256* null, i256* null, i256* %[[T020]], i256* %[[T021]], [0 x i256]* %[[T024]], i256* %[[T026]])
//CHECK-NEXT:   %[[T027:[0-9a-zA-Z_\.]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T028:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T029:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T028]], align 8
//CHECK-NEXT:   %[[T030:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T029]], i32 0
//CHECK-NEXT:   %[[T031:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T030]], i32 0, i256 2
//CHECK-NEXT:   %[[T032:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 4
//CHECK-NEXT:   %[[T033:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T034:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T033]], align 8
//CHECK-NEXT:   %[[T035:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T034]], i32 0
//CHECK-NEXT:   %[[T036:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %[[T037:[0-9a-zA-Z_\.]+]] = bitcast i32* %[[T036]] to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T027]], [0 x i256]* %0, i256* %[[T031]], i256* %[[T032]], i256* null, i256* null, [0 x i256]* %[[T035]], i256* %[[T037]])
//CHECK-NEXT:   %[[T038:[0-9a-zA-Z_\.]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T039:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T040:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T039]], align 8
//CHECK-NEXT:   %[[T041:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T040]], i32 0
//CHECK-NEXT:   %[[T042:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T041]], i32 0, i256 2
//CHECK-NEXT:   %[[T043:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 5
//CHECK-NEXT:   %[[T044:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T045:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T044]], align 8
//CHECK-NEXT:   %[[T046:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T045]], i32 0
//CHECK-NEXT:   %[[T047:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %[[T048:[0-9a-zA-Z_\.]+]] = bitcast i32* %[[T047]] to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_3]]([0 x i256]* %[[T038]], [0 x i256]* %0, i256* null, i256* null, i256* %[[T042]], i256* %[[T043]], [0 x i256]* %[[T046]], i256* %[[T048]])
//CHECK-NEXT:   %[[T049:[0-9a-zA-Z_\.]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T050:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T051:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T050]], align 8
//CHECK-NEXT:   %[[T052:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T051]], i32 0
//CHECK-NEXT:   %[[T053:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T052]], i32 0, i256 3
//CHECK-NEXT:   %[[T054:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 6
//CHECK-NEXT:   %[[T055:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T056:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T055]], align 8
//CHECK-NEXT:   %[[T057:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T056]], i32 0
//CHECK-NEXT:   %[[T058:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %[[T059:[0-9a-zA-Z_\.]+]] = bitcast i32* %[[T058]] to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_4]]([0 x i256]* %[[T049]], [0 x i256]* %0, i256* %[[T053]], i256* %[[T054]], i256* null, i256* null, [0 x i256]* %[[T057]], i256* %[[T059]])
//CHECK-NEXT:   %[[T060:[0-9a-zA-Z_\.]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T061:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T062:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T061]], align 8
//CHECK-NEXT:   %[[T063:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T062]], i32 0
//CHECK-NEXT:   %[[T064:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T063]], i32 0, i256 3
//CHECK-NEXT:   %[[T065:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 7
//CHECK-NEXT:   %[[T066:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T067:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T066]], align 8
//CHECK-NEXT:   %[[T068:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T067]], i32 0
//CHECK-NEXT:   %[[T069:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %[[T070:[0-9a-zA-Z_\.]+]] = bitcast i32* %[[T069]] to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_5]]([0 x i256]* %[[T060]], [0 x i256]* %0, i256* null, i256* null, i256* %[[T064]], i256* %[[T065]], [0 x i256]* %[[T068]], i256* %[[T070]])
//CHECK-NEXT:   br label %store6
//CHECK-EMPTY: 
//CHECK-NEXT: store6:
//CHECK-NEXT:   %[[T075:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   %[[T071:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T072:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T071]], align 8
//CHECK-NEXT:   %[[T073:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T072]], i32 0, i32 0
//CHECK-NEXT:   %[[T074:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T073]], align 4
//CHECK-NEXT:   store i256 %[[T074]], i256* %[[T075]], align 4
//CHECK-NEXT:   br label %store7
//CHECK-EMPTY: 
//CHECK-NEXT: store7:
//CHECK-NEXT:   %[[T080:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:   %[[T076:[0-9a-zA-Z_\.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T077:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T076]], align 8
//CHECK-NEXT:   %[[T078:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T077]], i32 0, i32 0
//CHECK-NEXT:   %[[T079:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T078]], align 4
//CHECK-NEXT:   store i256 %[[T079]], i256* %[[T080]], align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
