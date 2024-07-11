pragma circom 2.0.0;

// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template A(n) {
	signal input a[n];
	signal output c[n];

	var i;
	for (i = 0; i < n; i++) {
		c[i] <== a[i] * 2;
	}
}

template B(n, m, j) {
	signal input a[n][j];
	signal output b[n][j];
	signal input c[m][j];
	signal output d[m][j];

	component as[2][j];

	var i;
	var k;
	for (k = 0; k < j; k++) {
		as[0][k] = A(n);
	}	
	for (i = 0; i < n; i++) {
		for (k = 0; k < j; k++) {
			as[0][k].a[i] <== a[i][k];
		}
	}

		
	for (k = 0; k < j; k++) {
		as[1][k] = A(m);
	}
	for(i = 0; i < m; i++) {
		for (k = 0; k < j; k++) {
			as[1][k].a[i] <== c[i][k];
		}
	}

	for (i = 0; i < n; i++) {
		for (k = 0; k < j; k++) {
			b[i][k] <== as[0][k].c[i];
		}
	}

	for (i = 0; i < m; i++) {
		for (k = 0; k < j; k++) {
			d[i][k] <== as[1][k].c[i];
		}
	}
}

component main = B(2, 3, 2);

// NOTE: The loop in template A is the only that that is extracted for
//  now becauseMapped locations currently block body extraction.
//
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9a-zA-Z_\.]+}}([0 x i256]* %lvars, [0 x i256]* %signals, i256* %sig_0, i256* %sig_1){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9a-zA-Z_\.]+]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_0, i32 0
//CHECK-NEXT:   %[[T000:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_1, i32 0
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T000]], align 4
//CHECK-NEXT:   %[[C001:[0-9a-zA-Z_\.]+]] = call i256 @fr_mul(i256 %[[T001]], i256 2)
//CHECK-NEXT:   store i256 %[[C001]], i256* %[[T002]], align 4
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T002]], align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[C001]], i256 %[[T003]], i1* %constraint)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T006:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T004]], align 4
//CHECK-NEXT:   %[[C002:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T005]], i256 1)
//CHECK-NEXT:   store i256 %[[C002]], i256* %[[T006]], align 4
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
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_\.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 2, i256* %[[T001]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_\.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T002]], align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_\.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T003]], align 4
//CHECK-NEXT:   br label %unrolled_loop4
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop4:
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_\.]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   %[[T006:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T004]], [0 x i256]* %0, i256* %[[T005]], i256* %[[T006]])
//CHECK-NEXT:   %[[T007:[0-9a-zA-Z_\.]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T008:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %[[T009:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T007]], [0 x i256]* %0, i256* %[[T008]], i256* %[[T009]])
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
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_\.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 3, i256* %[[T001]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_\.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T002]], align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_\.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T003]], align 4
//CHECK-NEXT:   br label %unrolled_loop4
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop4:
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_\.]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   %[[T006:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T004]], [0 x i256]* %0, i256* %[[T005]], i256* %[[T006]])
//CHECK-NEXT:   %[[T007:[0-9a-zA-Z_\.]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T008:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %[[T009:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 4
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T007]], [0 x i256]* %0, i256* %[[T008]], i256* %[[T009]])
//CHECK-NEXT:   %[[T010:[0-9a-zA-Z_\.]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T011:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   %[[T012:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 5
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T010]], [0 x i256]* %0, i256* %[[T011]], i256* %[[T012]])
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @B_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [5 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [4 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T001:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 2, i256* %[[T001]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T002:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 3, i256* %[[T002]], align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T003:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 2, i256* %[[T003]], align 4
//CHECK-NEXT:   br label %create_cmp4
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp4:
//CHECK-NEXT:   %[[T004:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0
//CHECK-NEXT:   call void @A_0_build({ [0 x i256]*, i32 }* %[[T004]])
//CHECK-NEXT:   br label %create_cmp5
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp5:
//CHECK-NEXT:   %[[T005:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1
//CHECK-NEXT:   call void @A_0_build({ [0 x i256]*, i32 }* %[[T005]])
//CHECK-NEXT:   br label %create_cmp6
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp6:
//CHECK-NEXT:   %[[T006:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2
//CHECK-NEXT:   call void @A_1_build({ [0 x i256]*, i32 }* %[[T006]])
//CHECK-NEXT:   br label %create_cmp7
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp7:
//CHECK-NEXT:   %[[T007:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 3
//CHECK-NEXT:   call void @A_1_build({ [0 x i256]*, i32 }* %[[T007]])
//CHECK-NEXT:   br label %store8
//CHECK-EMPTY: 
//CHECK-NEXT: store8:
//CHECK-NEXT:   %[[T008:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 0, i256* %[[T008]], align 4
//CHECK-NEXT:   br label %store9
//CHECK-EMPTY: 
//CHECK-NEXT: store9:
//CHECK-NEXT:   %[[T009:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %[[T009]], align 4
//CHECK-NEXT:   br label %store10
//CHECK-EMPTY: 
//CHECK-NEXT: store10:
//CHECK-NEXT:   %[[T010:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %[[T010]], align 4
//CHECK-NEXT:   br label %unrolled_loop11
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop11:
//CHECK-NEXT:   %[[T011:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %[[T011]], align 4
//CHECK-NEXT:   %[[T012:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %[[T012]], align 4
//CHECK-NEXT:   br label %store12
//CHECK-EMPTY: 
//CHECK-NEXT: store12:
//CHECK-NEXT:   %[[T013:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 0, i256* %[[T013]], align 4
//CHECK-NEXT:   br label %unrolled_loop13
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop13:
//CHECK-NEXT:   %[[T014:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %[[T014]], align 4
//CHECK-NEXT:   %[[T017:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T018:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T017]], align 8
//CHECK-NEXT:   %[[T019:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T018]], i32 0, i32 2
//CHECK-NEXT:   %[[T015:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 10
//CHECK-NEXT:   %[[T016:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T015]], align 4
//CHECK-NEXT:   store i256 %[[T016]], i256* %[[T019]], align 4
//CHECK-NEXT:   %[[T021:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T019]], align 4
//CHECK-NEXT:   %[[CN01:constraint[0-9]*]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T016]], i256 %[[T021]], i1* %[[CN01]])
//CHECK-NEXT:   %[[T020:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %[[CR01:.*.counter[0-9]*]] = load i32, i32* %[[T020]], align 4
//CHECK-NEXT:   %[[CR02:.*.counter[0-9]*]] = sub i32 %[[CR01]], 1
//CHECK-NEXT:   store i32 %[[CR02]], i32* %[[T020]], align 4
//CHECK-NEXT:   %[[T022:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %[[T022]], align 4
//CHECK-NEXT:   %[[T025:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T026:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T025]], align 8
//CHECK-NEXT:   %[[T027:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T026]], i32 0, i32 2
//CHECK-NEXT:   %[[T023:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 11
//CHECK-NEXT:   %[[T024:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T023]], align 4
//CHECK-NEXT:   store i256 %[[T024]], i256* %[[T027]], align 4
//CHECK-NEXT:   %[[T029:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T027]], align 4
//CHECK-NEXT:   %[[CN02:constraint[0-9]*]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T024]], i256 %[[T029]], i1* %[[CN02]])
//CHECK-NEXT:   %[[T028:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %[[CR03:.*.counter[0-9]*]] = load i32, i32* %[[T028]], align 4
//CHECK-NEXT:   %[[CR04:.*.counter[0-9]*]] = sub i32 %[[CR03]], 1
//CHECK-NEXT:   store i32 %[[CR04]], i32* %[[T028]], align 4
//CHECK-NEXT:   %[[T030:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %[[T030]], align 4
//CHECK-NEXT:   %[[T031:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 1, i256* %[[T031]], align 4
//CHECK-NEXT:   %[[T032:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %[[T032]], align 4
//CHECK-NEXT:   %[[T035:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T036:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T035]], align 8
//CHECK-NEXT:   %[[T037:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T036]], i32 0, i32 3
//CHECK-NEXT:   %[[T033:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 12
//CHECK-NEXT:   %[[T034:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T033]], align 4
//CHECK-NEXT:   store i256 %[[T034]], i256* %[[T037]], align 4
//CHECK-NEXT:   %[[T041:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T037]], align 4
//CHECK-NEXT:   %[[CN03:constraint[0-9]*]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T034]], i256 %[[T041]], i1* %[[CN03]])
//CHECK-NEXT:   %[[T038:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %[[CR05:.*.counter[0-9]*]] = load i32, i32* %[[T038]], align 4
//CHECK-NEXT:   %[[CR06:.*.counter[0-9]*]] = sub i32 %[[CR05]], 1
//CHECK-NEXT:   store i32 %[[CR06]], i32* %[[T038]], align 4
//CHECK-NEXT:   %[[T039:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T040:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T039]], align 8
//CHECK-NEXT:   call void @A_0_run([0 x i256]* %[[T040]])
//CHECK-NEXT:   %[[T042:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %[[T042]], align 4
//CHECK-NEXT:   %[[T045:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T046:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T045]], align 8
//CHECK-NEXT:   %[[T047:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T046]], i32 0, i32 3
//CHECK-NEXT:   %[[T043:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 13
//CHECK-NEXT:   %[[T044:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T043]], align 4
//CHECK-NEXT:   store i256 %[[T044]], i256* %[[T047]], align 4
//CHECK-NEXT:   %[[T051:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T047]], align 4
//CHECK-NEXT:   %[[CN04:constraint[0-9]*]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T044]], i256 %[[T051]], i1* %[[CN04]])
//CHECK-NEXT:   %[[T048:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %[[CR07:.*.counter[0-9]*]] = load i32, i32* %[[T048]], align 4
//CHECK-NEXT:   %[[CR08:.*.counter[0-9]*]] = sub i32 %[[CR07]], 1
//CHECK-NEXT:   store i32 %[[CR08]], i32* %[[T048]], align 4
//CHECK-NEXT:   %[[T049:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T050:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T049]], align 8
//CHECK-NEXT:   call void @A_0_run([0 x i256]* %[[T050]])
//CHECK-NEXT:   %[[T052:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %[[T052]], align 4
//CHECK-NEXT:   %[[T053:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 2, i256* %[[T053]], align 4
//CHECK-NEXT:   br label %store14
//CHECK-EMPTY: 
//CHECK-NEXT: store14:
//CHECK-NEXT:   %[[T054:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %[[T054]], align 4
//CHECK-NEXT:   br label %unrolled_loop15
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop15:
//CHECK-NEXT:   %[[T055:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %[[T055]], align 4
//CHECK-NEXT:   %[[T056:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %[[T056]], align 4
//CHECK-NEXT:   br label %store16
//CHECK-EMPTY: 
//CHECK-NEXT: store16:
//CHECK-NEXT:   %[[T057:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 0, i256* %[[T057]], align 4
//CHECK-NEXT:   br label %unrolled_loop17
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop17:
//CHECK-NEXT:   %[[T058:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %[[T058]], align 4
//CHECK-NEXT:   %[[T061:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %[[T062:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T061]], align 8
//CHECK-NEXT:   %[[T063:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T062]], i32 0, i32 3
//CHECK-NEXT:   %[[T059:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 14
//CHECK-NEXT:   %[[T060:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T059]], align 4
//CHECK-NEXT:   store i256 %[[T060]], i256* %[[T063]], align 4
//CHECK-NEXT:   %[[T065:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T063]], align 4
//CHECK-NEXT:   %[[CN05:constraint[0-9]*]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T060]], i256 %[[T065]], i1* %[[CN05]])
//CHECK-NEXT:   %[[T064:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 1
//CHECK-NEXT:   %[[CR09:.*.counter[0-9]*]] = load i32, i32* %[[T064]], align 4
//CHECK-NEXT:   %[[CR10:.*.counter[0-9]*]] = sub i32 %[[CR09]], 1
//CHECK-NEXT:   store i32 %[[CR10]], i32* %[[T064]], align 4
//CHECK-NEXT:   %[[T066:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %[[T066]], align 4
//CHECK-NEXT:   %[[T069:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 3, i32 0
//CHECK-NEXT:   %[[T070:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T069]], align 8
//CHECK-NEXT:   %[[T071:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T070]], i32 0, i32 3
//CHECK-NEXT:   %[[T067:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 15
//CHECK-NEXT:   %[[T068:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T067]], align 4
//CHECK-NEXT:   store i256 %[[T068]], i256* %[[T071]], align 4
//CHECK-NEXT:   %[[T073:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T071]], align 4
//CHECK-NEXT:   %[[CN06:constraint[0-9]*]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T068]], i256 %[[T073]], i1* %[[CN06]])
//CHECK-NEXT:   %[[T072:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 3, i32 1
//CHECK-NEXT:   %[[CR11:.*.counter[0-9]*]] = load i32, i32* %[[T072]], align 4
//CHECK-NEXT:   %[[CR12:.*.counter[0-9]*]] = sub i32 %[[CR11]], 1
//CHECK-NEXT:   store i32 %[[CR12]], i32* %[[T072]], align 4
//CHECK-NEXT:   %[[T074:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %[[T074]], align 4
//CHECK-NEXT:   %[[T075:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 1, i256* %[[T075]], align 4
//CHECK-NEXT:   %[[T076:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %[[T076]], align 4
//CHECK-NEXT:   %[[T079:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %[[T080:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T079]], align 8
//CHECK-NEXT:   %[[T081:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T080]], i32 0, i32 4
//CHECK-NEXT:   %[[T077:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 16
//CHECK-NEXT:   %[[T078:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T077]], align 4
//CHECK-NEXT:   store i256 %[[T078]], i256* %[[T081]], align 4
//CHECK-NEXT:   %[[T083:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T081]], align 4
//CHECK-NEXT:   %[[CN07:constraint[0-9]*]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T078]], i256 %[[T083]], i1* %[[CN07]])
//CHECK-NEXT:   %[[T082:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 1
//CHECK-NEXT:   %[[CR13:.*.counter[0-9]*]] = load i32, i32* %[[T082]], align 4
//CHECK-NEXT:   %[[CR14:.*.counter[0-9]*]] = sub i32 %[[CR13]], 1
//CHECK-NEXT:   store i32 %[[CR14]], i32* %[[T082]], align 4
//CHECK-NEXT:   %[[T084:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %[[T084]], align 4
//CHECK-NEXT:   %[[T087:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 3, i32 0
//CHECK-NEXT:   %[[T088:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T087]], align 8
//CHECK-NEXT:   %[[T089:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T088]], i32 0, i32 4
//CHECK-NEXT:   %[[T085:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 17
//CHECK-NEXT:   %[[T086:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T085]], align 4
//CHECK-NEXT:   store i256 %[[T086]], i256* %[[T089]], align 4
//CHECK-NEXT:   %[[T091:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T089]], align 4
//CHECK-NEXT:   %[[CN08:constraint[0-9]*]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T086]], i256 %[[T091]], i1* %[[CN08]])
//CHECK-NEXT:   %[[T090:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 3, i32 1
//CHECK-NEXT:   %[[CR15:.*.counter[0-9]*]] = load i32, i32* %[[T090]], align 4
//CHECK-NEXT:   %[[CR16:.*.counter[0-9]*]] = sub i32 %[[CR15]], 1
//CHECK-NEXT:   store i32 %[[CR16]], i32* %[[T090]], align 4
//CHECK-NEXT:   %[[T092:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %[[T092]], align 4
//CHECK-NEXT:   %[[T093:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 2, i256* %[[T093]], align 4
//CHECK-NEXT:   %[[T094:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %[[T094]], align 4
//CHECK-NEXT:   %[[T097:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %[[T098:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T097]], align 8
//CHECK-NEXT:   %[[T099:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T098]], i32 0, i32 5
//CHECK-NEXT:   %[[T095:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 18
//CHECK-NEXT:   %[[T096:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T095]], align 4
//CHECK-NEXT:   store i256 %[[T096]], i256* %[[T099]], align 4
//CHECK-NEXT:   %[[T103:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T099]], align 4
//CHECK-NEXT:   %[[CN09:constraint[0-9]*]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T096]], i256 %[[T103]], i1* %[[CN09]])
//CHECK-NEXT:   %[[T100:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 1
//CHECK-NEXT:   %[[CR17:.*.counter[0-9]*]] = load i32, i32* %[[T100]], align 4
//CHECK-NEXT:   %[[CR18:.*.counter[0-9]*]] = sub i32 %[[CR17]], 1
//CHECK-NEXT:   store i32 %[[CR18]], i32* %[[T100]], align 4
//CHECK-NEXT:   %[[T101:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %[[T102:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T101]], align 8
//CHECK-NEXT:   call void @A_1_run([0 x i256]* %[[T102]])
//CHECK-NEXT:   %[[T104:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %[[T104]], align 4
//CHECK-NEXT:   %[[T107:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 3, i32 0
//CHECK-NEXT:   %[[T108:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T107]], align 8
//CHECK-NEXT:   %[[T109:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T108]], i32 0, i32 5
//CHECK-NEXT:   %[[T105:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 19
//CHECK-NEXT:   %[[T106:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T105]], align 4
//CHECK-NEXT:   store i256 %[[T106]], i256* %[[T109]], align 4
//CHECK-NEXT:   %[[T113:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T109]], align 4
//CHECK-NEXT:   %[[CN10:constraint[0-9]*]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T106]], i256 %[[T113]], i1* %[[CN10]])
//CHECK-NEXT:   %[[T110:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 3, i32 1
//CHECK-NEXT:   %[[CR19:.*.counter[0-9]*]] = load i32, i32* %[[T110]], align 4
//CHECK-NEXT:   %[[CR20:.*.counter[0-9]*]] = sub i32 %[[CR19]], 1
//CHECK-NEXT:   store i32 %[[CR20]], i32* %[[T110]], align 4
//CHECK-NEXT:   %[[T111:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 3, i32 0
//CHECK-NEXT:   %[[T112:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T111]], align 8
//CHECK-NEXT:   call void @A_1_run([0 x i256]* %[[T112]])
//CHECK-NEXT:   %[[T114:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %[[T114]], align 4
//CHECK-NEXT:   %[[T115:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 3, i256* %[[T115]], align 4
//CHECK-NEXT:   br label %store18
//CHECK-EMPTY: 
//CHECK-NEXT: store18:
//CHECK-NEXT:   %[[T116:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 0, i256* %[[T116]], align 4
//CHECK-NEXT:   br label %unrolled_loop19
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop19:
//CHECK-NEXT:   %[[T117:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %[[T117]], align 4
//CHECK-NEXT:   %[[T122:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   %[[T118:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T119:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T118]], align 8
//CHECK-NEXT:   %[[T120:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T119]], i32 0, i32 0
//CHECK-NEXT:   %[[T121:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T120]], align 4
//CHECK-NEXT:   store i256 %[[T121]], i256* %[[T122]], align 4
//CHECK-NEXT:   %[[T123:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T122]], align 4
//CHECK-NEXT:   %[[CN11:constraint[0-9]*]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T121]], i256 %[[T123]], i1* %[[CN11]])
//CHECK-NEXT:   %[[T124:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %[[T124]], align 4
//CHECK-NEXT:   %[[T129:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:   %[[T125:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T126:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T125]], align 8
//CHECK-NEXT:   %[[T127:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T126]], i32 0, i32 0
//CHECK-NEXT:   %[[T128:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T127]], align 4
//CHECK-NEXT:   store i256 %[[T128]], i256* %[[T129]], align 4
//CHECK-NEXT:   %[[T130:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T129]], align 4
//CHECK-NEXT:   %[[CN12:constraint[0-9]*]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T128]], i256 %[[T130]], i1* %[[CN12]])
//CHECK-NEXT:   %[[T131:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %[[T131]], align 4
//CHECK-NEXT:   %[[T132:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 1, i256* %[[T132]], align 4
//CHECK-NEXT:   %[[T133:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %[[T133]], align 4
//CHECK-NEXT:   %[[T138:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 2
//CHECK-NEXT:   %[[T134:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T135:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T134]], align 8
//CHECK-NEXT:   %[[T136:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T135]], i32 0, i32 1
//CHECK-NEXT:   %[[T137:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T136]], align 4
//CHECK-NEXT:   store i256 %[[T137]], i256* %[[T138]], align 4
//CHECK-NEXT:   %[[T139:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T138]], align 4
//CHECK-NEXT:   %[[CN13:constraint[0-9]*]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T137]], i256 %[[T139]], i1* %[[CN13]])
//CHECK-NEXT:   %[[T140:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %[[T140]], align 4
//CHECK-NEXT:   %[[T145:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 3
//CHECK-NEXT:   %[[T141:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T142:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T141]], align 8
//CHECK-NEXT:   %[[T143:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T142]], i32 0, i32 1
//CHECK-NEXT:   %[[T144:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T143]], align 4
//CHECK-NEXT:   store i256 %[[T144]], i256* %[[T145]], align 4
//CHECK-NEXT:   %[[T146:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T145]], align 4
//CHECK-NEXT:   %[[CN14:constraint[0-9]*]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T144]], i256 %[[T146]], i1* %[[CN14]])
//CHECK-NEXT:   %[[T147:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %[[T147]], align 4
//CHECK-NEXT:   %[[T148:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 2, i256* %[[T148]], align 4
//CHECK-NEXT:   br label %store20
//CHECK-EMPTY: 
//CHECK-NEXT: store20:
//CHECK-NEXT:   %[[T149:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 0, i256* %[[T149]], align 4
//CHECK-NEXT:   br label %unrolled_loop21
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop21:
//CHECK-NEXT:   %[[T150:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %[[T150]], align 4
//CHECK-NEXT:   %[[T155:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 4
//CHECK-NEXT:   %[[T151:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %[[T152:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T151]], align 8
//CHECK-NEXT:   %[[T153:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T152]], i32 0, i32 0
//CHECK-NEXT:   %[[T154:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T153]], align 4
//CHECK-NEXT:   store i256 %[[T154]], i256* %[[T155]], align 4
//CHECK-NEXT:   %[[T156:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T155]], align 4
//CHECK-NEXT:   %[[CN15:constraint[0-9]*]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T154]], i256 %[[T156]], i1* %[[CN15]])
//CHECK-NEXT:   %[[T157:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %[[T157]], align 4
//CHECK-NEXT:   %[[T162:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 5
//CHECK-NEXT:   %[[T158:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 3, i32 0
//CHECK-NEXT:   %[[T159:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T158]], align 8
//CHECK-NEXT:   %[[T160:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T159]], i32 0, i32 0
//CHECK-NEXT:   %[[T161:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T160]], align 4
//CHECK-NEXT:   store i256 %[[T161]], i256* %[[T162]], align 4
//CHECK-NEXT:   %[[T163:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T162]], align 4
//CHECK-NEXT:   %[[CN16:constraint[0-9]*]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T161]], i256 %[[T163]], i1* %[[CN16]])
//CHECK-NEXT:   %[[T164:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %[[T164]], align 4
//CHECK-NEXT:   %[[T165:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 1, i256* %[[T165]], align 4
//CHECK-NEXT:   %[[T166:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %[[T166]], align 4
//CHECK-NEXT:   %[[T171:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 6
//CHECK-NEXT:   %[[T167:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %[[T168:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T167]], align 8
//CHECK-NEXT:   %[[T169:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T168]], i32 0, i32 1
//CHECK-NEXT:   %[[T170:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T169]], align 4
//CHECK-NEXT:   store i256 %[[T170]], i256* %[[T171]], align 4
//CHECK-NEXT:   %[[T172:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T171]], align 4
//CHECK-NEXT:   %[[CN17:constraint[0-9]*]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T170]], i256 %[[T172]], i1* %[[CN17]])
//CHECK-NEXT:   %[[T173:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %[[T173]], align 4
//CHECK-NEXT:   %[[T178:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 7
//CHECK-NEXT:   %[[T174:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 3, i32 0
//CHECK-NEXT:   %[[T175:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T174]], align 8
//CHECK-NEXT:   %[[T176:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T175]], i32 0, i32 1
//CHECK-NEXT:   %[[T177:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T176]], align 4
//CHECK-NEXT:   store i256 %[[T177]], i256* %[[T178]], align 4
//CHECK-NEXT:   %[[T179:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T178]], align 4
//CHECK-NEXT:   %[[CN18:constraint[0-9]*]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T177]], i256 %[[T179]], i1* %[[CN18]])
//CHECK-NEXT:   %[[T180:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %[[T180]], align 4
//CHECK-NEXT:   %[[T181:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 2, i256* %[[T181]], align 4
//CHECK-NEXT:   %[[T182:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %[[T182]], align 4
//CHECK-NEXT:   %[[T187:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 8
//CHECK-NEXT:   %[[T183:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %[[T184:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T183]], align 8
//CHECK-NEXT:   %[[T185:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T184]], i32 0, i32 2
//CHECK-NEXT:   %[[T186:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T185]], align 4
//CHECK-NEXT:   store i256 %[[T186]], i256* %[[T187]], align 4
//CHECK-NEXT:   %[[T188:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T187]], align 4
//CHECK-NEXT:   %[[CN19:constraint[0-9]*]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T186]], i256 %[[T188]], i1* %[[CN19]])
//CHECK-NEXT:   %[[T189:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %[[T189]], align 4
//CHECK-NEXT:   %[[T194:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 9
//CHECK-NEXT:   %[[T190:[0-9a-zA-Z_\.]+]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 3, i32 0
//CHECK-NEXT:   %[[T191:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T190]], align 8
//CHECK-NEXT:   %[[T192:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T191]], i32 0, i32 2
//CHECK-NEXT:   %[[T193:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T192]], align 4
//CHECK-NEXT:   store i256 %[[T193]], i256* %[[T194]], align 4
//CHECK-NEXT:   %[[T195:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T194]], align 4
//CHECK-NEXT:   %[[CN20:constraint[0-9]*]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T193]], i256 %[[T195]], i1* %[[CN20]])
//CHECK-NEXT:   %[[T196:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %[[T196]], align 4
//CHECK-NEXT:   %[[T197:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 3, i256* %[[T197]], align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
