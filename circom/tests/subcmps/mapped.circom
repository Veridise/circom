pragma circom 2.0.0;

// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template A(n) {
	signal input a[n];
	signal input b[n];
	signal output c[n];

	var i;
	for (i = 0; i < n; i++) {
		c[i] <== a[i] * b[i];
	}
}

template B(n) {
	signal input a[n * 4];
	signal output b[n];

	component as[2];

	as[0] = A(n * 2);
	var i;
	for (i = 0; i < n * 2; i++) {
		as[0].a[i] <== a[i];
		as[0].b[i] <== a[i + n * 2];
	}

	as[1] = A(n);
	for(i = 0; i < n; i++) {
		as[1].a[i] <== as[0].c[i];
		as[1].b[i] <== as[0].c[i + n];
	}

	for (i = 0; i < n; i++) {
		b[i] <== as[1].c[i];
	}
}

component main = B(2);

// NOTE: The loop in template A is the only that is extracted for now
//  because mapped locations currently block loop body extraction.
//
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %sig_[[X1:[0-9]+]], i256* %sig_[[X2:[0-9]+]], i256* %sig_[[X3:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9]+]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %sig_[[X1]], i32 0
//CHECK-NEXT:   %[[T000:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %sig_[[X2]], i32 0
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T000]], align 4
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %sig_[[X3]], i32 0
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T002]], align 4
//CHECK-NEXT:   %[[C001:[0-9a-zA-Z_.]+]] = call i256 @fr_mul(i256 %[[T001]], i256 %[[T003]])
//CHECK-NEXT:   store i256 %[[C001]], i256* %[[T004]], align 4
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T004]], align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[C001]], i256 %[[T005]], i1* %constraint)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T008:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T006:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T007:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T006]], align 4
//CHECK-NEXT:   %[[C002:[0-9a-zA-Z_.]+]] = call i256 @fr_add(i256 %[[T007]], i256 1)
//CHECK-NEXT:   store i256 %[[C002]], i256* %[[T008]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @A_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [2 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 4, i256* %[[T001]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T002]], align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T003]], align 4
//CHECK-NEXT:   br label %unrolled_loop4
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop4:
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_.]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   %[[T006:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 4
//CHECK-NEXT:   %[[T007:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 8
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T004]], [0 x i256]* %0, i256* %[[T005]], i256* %[[T006]], i256* %[[T007]])
//CHECK-NEXT:   %[[T008:[0-9a-zA-Z_.]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T009:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %[[T010:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 5
//CHECK-NEXT:   %[[T011:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 9
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T008]], [0 x i256]* %0, i256* %[[T009]], i256* %[[T010]], i256* %[[T011]])
//CHECK-NEXT:   %[[T012:[0-9a-zA-Z_.]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T013:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   %[[T014:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 6
//CHECK-NEXT:   %[[T015:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 10
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T012]], [0 x i256]* %0, i256* %[[T013]], i256* %[[T014]], i256* %[[T015]])
//CHECK-NEXT:   %[[T016:[0-9a-zA-Z_.]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T017:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   %[[T018:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 7
//CHECK-NEXT:   %[[T019:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 11
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T016]], [0 x i256]* %0, i256* %[[T017]], i256* %[[T018]], i256* %[[T019]])
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @A_1_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [2 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 2, i256* %[[T001]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T002]], align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T003]], align 4
//CHECK-NEXT:   br label %unrolled_loop4
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop4:
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_.]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   %[[T006:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   %[[T007:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 4
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T004]], [0 x i256]* %0, i256* %[[T005]], i256* %[[T006]], i256* %[[T007]])
//CHECK-NEXT:   %[[T008:[0-9a-zA-Z_.]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T009:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %[[T010:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   %[[T011:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 5
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T008]], [0 x i256]* %0, i256* %[[T009]], i256* %[[T010]], i256* %[[T011]])
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @B_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [2 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [2 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 2, i256* %[[T001]], align 4
//CHECK-NEXT:   br label %create_cmp2
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp2:
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0
//CHECK-NEXT:   call void @A_0_build({ [0 x i256]*, i32 }* %[[T002]])
//CHECK-NEXT:   br label %create_cmp3
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp3:
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1
//CHECK-NEXT:   call void @A_1_build({ [0 x i256]*, i32 }* %[[T003]])
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T004]], align 4
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T005]], align 4
//CHECK-NEXT:   br label %unrolled_loop6
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop6:
//CHECK-NEXT:   %[[T008:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T009:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T008]], align 8
//CHECK-NEXT:   %[[T010:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T009]], i32 0, i32 4
//CHECK-NEXT:   %[[T006:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 2
//CHECK-NEXT:   %[[T007:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T006]], align 4
//CHECK-NEXT:   store i256 %[[T007]], i256* %[[T010]], align 4
//CHECK-NEXT:   %[[T011:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %load.subcmp.counter = load i32, i32* %[[T011]], align 4
//CHECK-NEXT:   %decrement.counter = sub i32 %load.subcmp.counter, 1
//CHECK-NEXT:   store i32 %decrement.counter, i32* %[[T011]], align 4
//CHECK-NEXT:   %[[T012:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T010]], align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T007]], i256 %[[T012]], i1* %constraint)
//CHECK-NEXT:   %[[T015:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T016:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T015]], align 8
//CHECK-NEXT:   %[[T017:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T016]], i32 0, i32 8
//CHECK-NEXT:   %[[T013:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 6
//CHECK-NEXT:   %[[T014:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T013]], align 4
//CHECK-NEXT:   store i256 %[[T014]], i256* %[[T017]], align 4
//CHECK-NEXT:   %[[T018:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %load.subcmp.counter1 = load i32, i32* %[[T018]], align 4
//CHECK-NEXT:   %decrement.counter2 = sub i32 %load.subcmp.counter1, 1
//CHECK-NEXT:   store i32 %decrement.counter2, i32* %[[T018]], align 4
//CHECK-NEXT:   %[[T019:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T017]], align 4
//CHECK-NEXT:   %constraint3 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T014]], i256 %[[T019]], i1* %constraint3)
//CHECK-NEXT:   %[[T020:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 1, i256* %[[T020]], align 4
//CHECK-NEXT:   %[[T023:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T024:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T023]], align 8
//CHECK-NEXT:   %[[T025:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T024]], i32 0, i32 5
//CHECK-NEXT:   %[[T021:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 3
//CHECK-NEXT:   %[[T022:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T021]], align 4
//CHECK-NEXT:   store i256 %[[T022]], i256* %[[T025]], align 4
//CHECK-NEXT:   %[[T026:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %load.subcmp.counter4 = load i32, i32* %[[T026]], align 4
//CHECK-NEXT:   %decrement.counter5 = sub i32 %load.subcmp.counter4, 1
//CHECK-NEXT:   store i32 %decrement.counter5, i32* %[[T026]], align 4
//CHECK-NEXT:   %[[T027:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T025]], align 4
//CHECK-NEXT:   %constraint6 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T022]], i256 %[[T027]], i1* %constraint6)
//CHECK-NEXT:   %[[T030:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T031:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T030]], align 8
//CHECK-NEXT:   %[[T032:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T031]], i32 0, i32 9
//CHECK-NEXT:   %[[T028:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 7
//CHECK-NEXT:   %[[T029:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T028]], align 4
//CHECK-NEXT:   store i256 %[[T029]], i256* %[[T032]], align 4
//CHECK-NEXT:   %[[T033:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %load.subcmp.counter7 = load i32, i32* %[[T033]], align 4
//CHECK-NEXT:   %decrement.counter8 = sub i32 %load.subcmp.counter7, 1
//CHECK-NEXT:   store i32 %decrement.counter8, i32* %[[T033]], align 4
//CHECK-NEXT:   %[[T034:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T032]], align 4
//CHECK-NEXT:   %constraint9 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T029]], i256 %[[T034]], i1* %constraint9)
//CHECK-NEXT:   %[[T035:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 2, i256* %[[T035]], align 4
//CHECK-NEXT:   %[[T038:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T039:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T038]], align 8
//CHECK-NEXT:   %[[T040:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T039]], i32 0, i32 6
//CHECK-NEXT:   %[[T036:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 4
//CHECK-NEXT:   %[[T037:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T036]], align 4
//CHECK-NEXT:   store i256 %[[T037]], i256* %[[T040]], align 4
//CHECK-NEXT:   %[[T041:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %load.subcmp.counter10 = load i32, i32* %[[T041]], align 4
//CHECK-NEXT:   %decrement.counter11 = sub i32 %load.subcmp.counter10, 1
//CHECK-NEXT:   store i32 %decrement.counter11, i32* %[[T041]], align 4
//CHECK-NEXT:   %[[T042:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T040]], align 4
//CHECK-NEXT:   %constraint12 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T037]], i256 %[[T042]], i1* %constraint12)
//CHECK-NEXT:   %[[T045:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T046:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T045]], align 8
//CHECK-NEXT:   %[[T047:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T046]], i32 0, i32 10
//CHECK-NEXT:   %[[T043:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 8
//CHECK-NEXT:   %[[T044:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T043]], align 4
//CHECK-NEXT:   store i256 %[[T044]], i256* %[[T047]], align 4
//CHECK-NEXT:   %[[T048:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %load.subcmp.counter13 = load i32, i32* %[[T048]], align 4
//CHECK-NEXT:   %decrement.counter14 = sub i32 %load.subcmp.counter13, 1
//CHECK-NEXT:   store i32 %decrement.counter14, i32* %[[T048]], align 4
//CHECK-NEXT:   %[[T049:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T047]], align 4
//CHECK-NEXT:   %constraint15 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T044]], i256 %[[T049]], i1* %constraint15)
//CHECK-NEXT:   %[[T050:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 3, i256* %[[T050]], align 4
//CHECK-NEXT:   %[[T053:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T054:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T053]], align 8
//CHECK-NEXT:   %[[T055:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T054]], i32 0, i32 7
//CHECK-NEXT:   %[[T051:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 5
//CHECK-NEXT:   %[[T052:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T051]], align 4
//CHECK-NEXT:   store i256 %[[T052]], i256* %[[T055]], align 4
//CHECK-NEXT:   %[[T056:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %load.subcmp.counter16 = load i32, i32* %[[T056]], align 4
//CHECK-NEXT:   %decrement.counter17 = sub i32 %load.subcmp.counter16, 1
//CHECK-NEXT:   store i32 %decrement.counter17, i32* %[[T056]], align 4
//CHECK-NEXT:   %[[T057:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T055]], align 4
//CHECK-NEXT:   %constraint18 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T052]], i256 %[[T057]], i1* %constraint18)
//CHECK-NEXT:   %[[T060:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T061:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T060]], align 8
//CHECK-NEXT:   %[[T062:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T061]], i32 0, i32 11
//CHECK-NEXT:   %[[T058:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 9
//CHECK-NEXT:   %[[T059:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T058]], align 4
//CHECK-NEXT:   store i256 %[[T059]], i256* %[[T062]], align 4
//CHECK-NEXT:   %[[T063:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %load.subcmp.counter19 = load i32, i32* %[[T063]], align 4
//CHECK-NEXT:   %decrement.counter20 = sub i32 %load.subcmp.counter19, 1
//CHECK-NEXT:   store i32 %decrement.counter20, i32* %[[T063]], align 4
//CHECK-NEXT:   %[[T064:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T065:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T064]], align 8
//CHECK-NEXT:   call void @A_0_run([0 x i256]* %[[T065]])
//CHECK-NEXT:   %[[T066:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T062]], align 4
//CHECK-NEXT:   %constraint21 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T059]], i256 %[[T066]], i1* %constraint21)
//CHECK-NEXT:   %[[T067:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 4, i256* %[[T067]], align 4
//CHECK-NEXT:   br label %store7
//CHECK-EMPTY: 
//CHECK-NEXT: store7:
//CHECK-NEXT:   %[[T068:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T068]], align 4
//CHECK-NEXT:   br label %unrolled_loop8
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop8:
//CHECK-NEXT:   %[[T073:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T074:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T073]], align 8
//CHECK-NEXT:   %[[T075:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T074]], i32 0, i32 2
//CHECK-NEXT:   %[[T069:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T070:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T069]], align 8
//CHECK-NEXT:   %[[T071:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T070]], i32 0, i32 0
//CHECK-NEXT:   %[[T072:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T071]], align 4
//CHECK-NEXT:   store i256 %[[T072]], i256* %[[T075]], align 4
//CHECK-NEXT:   %[[T076:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %load.subcmp.counter22 = load i32, i32* %[[T076]], align 4
//CHECK-NEXT:   %decrement.counter23 = sub i32 %load.subcmp.counter22, 1
//CHECK-NEXT:   store i32 %decrement.counter23, i32* %[[T076]], align 4
//CHECK-NEXT:   %[[T077:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T075]], align 4
//CHECK-NEXT:   %constraint24 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T072]], i256 %[[T077]], i1* %constraint24)
//CHECK-NEXT:   %[[T082:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T083:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T082]], align 8
//CHECK-NEXT:   %[[T084:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T083]], i32 0, i32 4
//CHECK-NEXT:   %[[T078:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T079:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T078]], align 8
//CHECK-NEXT:   %[[T080:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T079]], i32 0, i32 2
//CHECK-NEXT:   %[[T081:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T080]], align 4
//CHECK-NEXT:   store i256 %[[T081]], i256* %[[T084]], align 4
//CHECK-NEXT:   %[[T085:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %load.subcmp.counter25 = load i32, i32* %[[T085]], align 4
//CHECK-NEXT:   %decrement.counter26 = sub i32 %load.subcmp.counter25, 1
//CHECK-NEXT:   store i32 %decrement.counter26, i32* %[[T085]], align 4
//CHECK-NEXT:   %[[T086:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T084]], align 4
//CHECK-NEXT:   %constraint27 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T081]], i256 %[[T086]], i1* %constraint27)
//CHECK-NEXT:   %[[T087:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 1, i256* %[[T087]], align 4
//CHECK-NEXT:   %[[T092:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T093:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T092]], align 8
//CHECK-NEXT:   %[[T094:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T093]], i32 0, i32 3
//CHECK-NEXT:   %[[T088:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T089:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T088]], align 8
//CHECK-NEXT:   %[[T090:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T089]], i32 0, i32 1
//CHECK-NEXT:   %[[T091:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T090]], align 4
//CHECK-NEXT:   store i256 %[[T091]], i256* %[[T094]], align 4
//CHECK-NEXT:   %[[T095:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %load.subcmp.counter28 = load i32, i32* %[[T095]], align 4
//CHECK-NEXT:   %decrement.counter29 = sub i32 %load.subcmp.counter28, 1
//CHECK-NEXT:   store i32 %decrement.counter29, i32* %[[T095]], align 4
//CHECK-NEXT:   %[[T096:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T094]], align 4
//CHECK-NEXT:   %constraint30 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T091]], i256 %[[T096]], i1* %constraint30)
//CHECK-NEXT:   %[[T101:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T102:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T101]], align 8
//CHECK-NEXT:   %[[T103:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T102]], i32 0, i32 5
//CHECK-NEXT:   %[[T097:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T098:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T097]], align 8
//CHECK-NEXT:   %[[T099:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T098]], i32 0, i32 3
//CHECK-NEXT:   %[[T100:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T099]], align 4
//CHECK-NEXT:   store i256 %[[T100]], i256* %[[T103]], align 4
//CHECK-NEXT:   %[[T104:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %load.subcmp.counter31 = load i32, i32* %[[T104]], align 4
//CHECK-NEXT:   %decrement.counter32 = sub i32 %load.subcmp.counter31, 1
//CHECK-NEXT:   store i32 %decrement.counter32, i32* %[[T104]], align 4
//CHECK-NEXT:   %[[T105:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T106:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T105]], align 8
//CHECK-NEXT:   call void @A_1_run([0 x i256]* %[[T106]])
//CHECK-NEXT:   %[[T107:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T103]], align 4
//CHECK-NEXT:   %constraint33 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T100]], i256 %[[T107]], i1* %constraint33)
//CHECK-NEXT:   %[[T108:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 2, i256* %[[T108]], align 4
//CHECK-NEXT:   br label %store9
//CHECK-EMPTY: 
//CHECK-NEXT: store9:
//CHECK-NEXT:   %[[T109:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T109]], align 4
//CHECK-NEXT:   br label %unrolled_loop10
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop10:
//CHECK-NEXT:   %[[T114:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   %[[T110:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T111:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T110]], align 8
//CHECK-NEXT:   %[[T112:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T111]], i32 0, i32 0
//CHECK-NEXT:   %[[T113:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T112]], align 4
//CHECK-NEXT:   store i256 %[[T113]], i256* %[[T114]], align 4
//CHECK-NEXT:   %[[T115:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T114]], align 4
//CHECK-NEXT:   %constraint34 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T113]], i256 %[[T115]], i1* %constraint34)
//CHECK-NEXT:   %[[T116:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 1, i256* %[[T116]], align 4
//CHECK-NEXT:   %[[T121:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:   %[[T117:[0-9a-zA-Z_.]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T118:[0-9a-zA-Z_.]+]] = load [0 x i256]*, [0 x i256]** %[[T117]], align 8
//CHECK-NEXT:   %[[T119:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T118]], i32 0, i32 1
//CHECK-NEXT:   %[[T120:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T119]], align 4
//CHECK-NEXT:   store i256 %[[T120]], i256* %[[T121]], align 4
//CHECK-NEXT:   %[[T122:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T121]], align 4
//CHECK-NEXT:   %constraint35 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T120]], i256 %[[T122]], i1* %constraint35)
//CHECK-NEXT:   %[[T123:[0-9a-zA-Z_.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 2, i256* %[[T123]], align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
