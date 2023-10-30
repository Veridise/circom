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

//CHECK-LABEL: define void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals, i256* %fix_0, i256* %fix_1){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9]+]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr i256, i256* %fix_1, i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %call.fr_mul = call i256 @fr_mul(i256 %1, i256 2)
//CHECK-NEXT:   %2 = getelementptr i256, i256* %fix_0, i32 0
//CHECK-NEXT:   store i256 %call.fr_mul, i256* %2, align 4
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %call.fr_mul, i256 %3, i1* %constraint)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %5 = load i256, i256* %4, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %5, i256 1)
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 %call.fr_add, i256* %6, align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals, i256* %fix_0, i256* %fix_1){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2:[0-9]+]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr i256, i256* %fix_1, i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %call.fr_mul = call i256 @fr_mul(i256 %1, i256 2)
//CHECK-NEXT:   %2 = getelementptr i256, i256* %fix_0, i32 0
//CHECK-NEXT:   store i256 %call.fr_mul, i256* %2, align 4
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %call.fr_mul, i256 %3, i1* %constraint)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %5 = load i256, i256* %4, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %5, i256 1)
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 %call.fr_add, i256* %6, align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @A_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [2 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 2, i256* %1, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %2 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %2, align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %3 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %3, align 4
//CHECK-NEXT:   br label %unrolled_loop4
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop4:
//CHECK-NEXT:   %4 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %4, [0 x i256]* %0, i256* %5, i256* %6)
//CHECK-NEXT:   %7 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %7, [0 x i256]* %0, i256* %8, i256* %9)
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @A_1_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [2 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 3, i256* %1, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %2 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %2, align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %3 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %3, align 4
//CHECK-NEXT:   br label %unrolled_loop4
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop4:
//CHECK-NEXT:   %4 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %4, [0 x i256]* %0, i256* %5, i256* %6)
//CHECK-NEXT:   %7 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 4
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %7, [0 x i256]* %0, i256* %8, i256* %9)
//CHECK-NEXT:   %10 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   %12 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 5
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %10, [0 x i256]* %0, i256* %11, i256* %12)
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @B_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [5 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [4 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 2, i256* %1, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %2 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 3, i256* %2, align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %3 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 2, i256* %3, align 4
//CHECK-NEXT:   br label %create_cmp4
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp4:
//CHECK-NEXT:   %4 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0
//CHECK-NEXT:   call void @A_0_build({ [0 x i256]*, i32 }* %4)
//CHECK-NEXT:   br label %create_cmp5
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp5:
//CHECK-NEXT:   %5 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1
//CHECK-NEXT:   call void @A_0_build({ [0 x i256]*, i32 }* %5)
//CHECK-NEXT:   br label %create_cmp6
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp6:
//CHECK-NEXT:   %6 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2
//CHECK-NEXT:   call void @A_1_build({ [0 x i256]*, i32 }* %6)
//CHECK-NEXT:   br label %create_cmp7
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp7:
//CHECK-NEXT:   %7 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 3
//CHECK-NEXT:   call void @A_1_build({ [0 x i256]*, i32 }* %7)
//CHECK-NEXT:   br label %store8
//CHECK-EMPTY: 
//CHECK-NEXT: store8:
//CHECK-NEXT:   %8 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 0, i256* %8, align 4
//CHECK-NEXT:   br label %store9
//CHECK-EMPTY: 
//CHECK-NEXT: store9:
//CHECK-NEXT:   %9 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %9, align 4
//CHECK-NEXT:   br label %store10
//CHECK-EMPTY: 
//CHECK-NEXT: store10:
//CHECK-NEXT:   %10 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %10, align 4
//CHECK-NEXT:   br label %unrolled_loop11
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop11:
//CHECK-NEXT:   %11 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %11, align 4
//CHECK-NEXT:   %12 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %12, align 4
//CHECK-NEXT:   br label %store12
//CHECK-EMPTY: 
//CHECK-NEXT: store12:
//CHECK-NEXT:   %13 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 0, i256* %13, align 4
//CHECK-NEXT:   br label %unrolled_loop13
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop13:
//CHECK-NEXT:   %14 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %14, align 4
//CHECK-NEXT:   %15 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 10
//CHECK-NEXT:   %16 = load i256, i256* %15, align 4
//CHECK-NEXT:   %17 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %18 = load [0 x i256]*, [0 x i256]** %17, align 8
//CHECK-NEXT:   %19 = getelementptr [0 x i256], [0 x i256]* %18, i32 0, i32 2
//CHECK-NEXT:   store i256 %16, i256* %19, align 4
//CHECK-NEXT:   %20 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %load.subcmp.counter = load i32, i32* %20, align 4
//CHECK-NEXT:   %decrement.counter = sub i32 %load.subcmp.counter, 1
//CHECK-NEXT:   store i32 %decrement.counter, i32* %20, align 4
//CHECK-NEXT:   %21 = load i256, i256* %19, align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %16, i256 %21, i1* %constraint)
//CHECK-NEXT:   %22 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %22, align 4
//CHECK-NEXT:   %23 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 11
//CHECK-NEXT:   %24 = load i256, i256* %23, align 4
//CHECK-NEXT:   %25 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %26 = load [0 x i256]*, [0 x i256]** %25, align 8
//CHECK-NEXT:   %27 = getelementptr [0 x i256], [0 x i256]* %26, i32 0, i32 2
//CHECK-NEXT:   store i256 %24, i256* %27, align 4
//CHECK-NEXT:   %28 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %load.subcmp.counter1 = load i32, i32* %28, align 4
//CHECK-NEXT:   %decrement.counter2 = sub i32 %load.subcmp.counter1, 1
//CHECK-NEXT:   store i32 %decrement.counter2, i32* %28, align 4
//CHECK-NEXT:   %29 = load i256, i256* %27, align 4
//CHECK-NEXT:   %constraint3 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %24, i256 %29, i1* %constraint3)
//CHECK-NEXT:   %30 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %30, align 4
//CHECK-NEXT:   %31 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 1, i256* %31, align 4
//CHECK-NEXT:   %32 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %32, align 4
//CHECK-NEXT:   %33 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 12
//CHECK-NEXT:   %34 = load i256, i256* %33, align 4
//CHECK-NEXT:   %35 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %36 = load [0 x i256]*, [0 x i256]** %35, align 8
//CHECK-NEXT:   %37 = getelementptr [0 x i256], [0 x i256]* %36, i32 0, i32 3
//CHECK-NEXT:   store i256 %34, i256* %37, align 4
//CHECK-NEXT:   %38 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %load.subcmp.counter4 = load i32, i32* %38, align 4
//CHECK-NEXT:   %decrement.counter5 = sub i32 %load.subcmp.counter4, 1
//CHECK-NEXT:   store i32 %decrement.counter5, i32* %38, align 4
//CHECK-NEXT:   %39 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %40 = load [0 x i256]*, [0 x i256]** %39, align 8
//CHECK-NEXT:   call void @A_0_run([0 x i256]* %40)
//CHECK-NEXT:   %41 = load i256, i256* %37, align 4
//CHECK-NEXT:   %constraint6 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %34, i256 %41, i1* %constraint6)
//CHECK-NEXT:   %42 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %42, align 4
//CHECK-NEXT:   %43 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 13
//CHECK-NEXT:   %44 = load i256, i256* %43, align 4
//CHECK-NEXT:   %45 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %46 = load [0 x i256]*, [0 x i256]** %45, align 8
//CHECK-NEXT:   %47 = getelementptr [0 x i256], [0 x i256]* %46, i32 0, i32 3
//CHECK-NEXT:   store i256 %44, i256* %47, align 4
//CHECK-NEXT:   %48 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %load.subcmp.counter7 = load i32, i32* %48, align 4
//CHECK-NEXT:   %decrement.counter8 = sub i32 %load.subcmp.counter7, 1
//CHECK-NEXT:   store i32 %decrement.counter8, i32* %48, align 4
//CHECK-NEXT:   %49 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %50 = load [0 x i256]*, [0 x i256]** %49, align 8
//CHECK-NEXT:   call void @A_0_run([0 x i256]* %50)
//CHECK-NEXT:   %51 = load i256, i256* %47, align 4
//CHECK-NEXT:   %constraint9 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %44, i256 %51, i1* %constraint9)
//CHECK-NEXT:   %52 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %52, align 4
//CHECK-NEXT:   %53 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 2, i256* %53, align 4
//CHECK-NEXT:   br label %store14
//CHECK-EMPTY: 
//CHECK-NEXT: store14:
//CHECK-NEXT:   %54 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %54, align 4
//CHECK-NEXT:   br label %unrolled_loop15
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop15:
//CHECK-NEXT:   %55 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %55, align 4
//CHECK-NEXT:   %56 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %56, align 4
//CHECK-NEXT:   br label %store16
//CHECK-EMPTY: 
//CHECK-NEXT: store16:
//CHECK-NEXT:   %57 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 0, i256* %57, align 4
//CHECK-NEXT:   br label %unrolled_loop17
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop17:
//CHECK-NEXT:   %58 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %58, align 4
//CHECK-NEXT:   %59 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 14
//CHECK-NEXT:   %60 = load i256, i256* %59, align 4
//CHECK-NEXT:   %61 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %62 = load [0 x i256]*, [0 x i256]** %61, align 8
//CHECK-NEXT:   %63 = getelementptr [0 x i256], [0 x i256]* %62, i32 0, i32 3
//CHECK-NEXT:   store i256 %60, i256* %63, align 4
//CHECK-NEXT:   %64 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 1
//CHECK-NEXT:   %load.subcmp.counter10 = load i32, i32* %64, align 4
//CHECK-NEXT:   %decrement.counter11 = sub i32 %load.subcmp.counter10, 1
//CHECK-NEXT:   store i32 %decrement.counter11, i32* %64, align 4
//CHECK-NEXT:   %65 = load i256, i256* %63, align 4
//CHECK-NEXT:   %constraint12 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %60, i256 %65, i1* %constraint12)
//CHECK-NEXT:   %66 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %66, align 4
//CHECK-NEXT:   %67 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 15
//CHECK-NEXT:   %68 = load i256, i256* %67, align 4
//CHECK-NEXT:   %69 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 3, i32 0
//CHECK-NEXT:   %70 = load [0 x i256]*, [0 x i256]** %69, align 8
//CHECK-NEXT:   %71 = getelementptr [0 x i256], [0 x i256]* %70, i32 0, i32 3
//CHECK-NEXT:   store i256 %68, i256* %71, align 4
//CHECK-NEXT:   %72 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 3, i32 1
//CHECK-NEXT:   %load.subcmp.counter13 = load i32, i32* %72, align 4
//CHECK-NEXT:   %decrement.counter14 = sub i32 %load.subcmp.counter13, 1
//CHECK-NEXT:   store i32 %decrement.counter14, i32* %72, align 4
//CHECK-NEXT:   %73 = load i256, i256* %71, align 4
//CHECK-NEXT:   %constraint15 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %68, i256 %73, i1* %constraint15)
//CHECK-NEXT:   %74 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %74, align 4
//CHECK-NEXT:   %75 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 1, i256* %75, align 4
//CHECK-NEXT:   %76 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %76, align 4
//CHECK-NEXT:   %77 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 16
//CHECK-NEXT:   %78 = load i256, i256* %77, align 4
//CHECK-NEXT:   %79 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %80 = load [0 x i256]*, [0 x i256]** %79, align 8
//CHECK-NEXT:   %81 = getelementptr [0 x i256], [0 x i256]* %80, i32 0, i32 4
//CHECK-NEXT:   store i256 %78, i256* %81, align 4
//CHECK-NEXT:   %82 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 1
//CHECK-NEXT:   %load.subcmp.counter16 = load i32, i32* %82, align 4
//CHECK-NEXT:   %decrement.counter17 = sub i32 %load.subcmp.counter16, 1
//CHECK-NEXT:   store i32 %decrement.counter17, i32* %82, align 4
//CHECK-NEXT:   %83 = load i256, i256* %81, align 4
//CHECK-NEXT:   %constraint18 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %78, i256 %83, i1* %constraint18)
//CHECK-NEXT:   %84 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %84, align 4
//CHECK-NEXT:   %85 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 17
//CHECK-NEXT:   %86 = load i256, i256* %85, align 4
//CHECK-NEXT:   %87 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 3, i32 0
//CHECK-NEXT:   %88 = load [0 x i256]*, [0 x i256]** %87, align 8
//CHECK-NEXT:   %89 = getelementptr [0 x i256], [0 x i256]* %88, i32 0, i32 4
//CHECK-NEXT:   store i256 %86, i256* %89, align 4
//CHECK-NEXT:   %90 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 3, i32 1
//CHECK-NEXT:   %load.subcmp.counter19 = load i32, i32* %90, align 4
//CHECK-NEXT:   %decrement.counter20 = sub i32 %load.subcmp.counter19, 1
//CHECK-NEXT:   store i32 %decrement.counter20, i32* %90, align 4
//CHECK-NEXT:   %91 = load i256, i256* %89, align 4
//CHECK-NEXT:   %constraint21 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %86, i256 %91, i1* %constraint21)
//CHECK-NEXT:   %92 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %92, align 4
//CHECK-NEXT:   %93 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 2, i256* %93, align 4
//CHECK-NEXT:   %94 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %94, align 4
//CHECK-NEXT:   %95 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 18
//CHECK-NEXT:   %96 = load i256, i256* %95, align 4
//CHECK-NEXT:   %97 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %98 = load [0 x i256]*, [0 x i256]** %97, align 8
//CHECK-NEXT:   %99 = getelementptr [0 x i256], [0 x i256]* %98, i32 0, i32 5
//CHECK-NEXT:   store i256 %96, i256* %99, align 4
//CHECK-NEXT:   %100 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 1
//CHECK-NEXT:   %load.subcmp.counter22 = load i32, i32* %100, align 4
//CHECK-NEXT:   %decrement.counter23 = sub i32 %load.subcmp.counter22, 1
//CHECK-NEXT:   store i32 %decrement.counter23, i32* %100, align 4
//CHECK-NEXT:   %101 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %102 = load [0 x i256]*, [0 x i256]** %101, align 8
//CHECK-NEXT:   call void @A_1_run([0 x i256]* %102)
//CHECK-NEXT:   %103 = load i256, i256* %99, align 4
//CHECK-NEXT:   %constraint24 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %96, i256 %103, i1* %constraint24)
//CHECK-NEXT:   %104 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %104, align 4
//CHECK-NEXT:   %105 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 19
//CHECK-NEXT:   %106 = load i256, i256* %105, align 4
//CHECK-NEXT:   %107 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 3, i32 0
//CHECK-NEXT:   %108 = load [0 x i256]*, [0 x i256]** %107, align 8
//CHECK-NEXT:   %109 = getelementptr [0 x i256], [0 x i256]* %108, i32 0, i32 5
//CHECK-NEXT:   store i256 %106, i256* %109, align 4
//CHECK-NEXT:   %110 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 3, i32 1
//CHECK-NEXT:   %load.subcmp.counter25 = load i32, i32* %110, align 4
//CHECK-NEXT:   %decrement.counter26 = sub i32 %load.subcmp.counter25, 1
//CHECK-NEXT:   store i32 %decrement.counter26, i32* %110, align 4
//CHECK-NEXT:   %111 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 3, i32 0
//CHECK-NEXT:   %112 = load [0 x i256]*, [0 x i256]** %111, align 8
//CHECK-NEXT:   call void @A_1_run([0 x i256]* %112)
//CHECK-NEXT:   %113 = load i256, i256* %109, align 4
//CHECK-NEXT:   %constraint27 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %106, i256 %113, i1* %constraint27)
//CHECK-NEXT:   %114 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %114, align 4
//CHECK-NEXT:   %115 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 3, i256* %115, align 4
//CHECK-NEXT:   br label %store18
//CHECK-EMPTY: 
//CHECK-NEXT: store18:
//CHECK-NEXT:   %116 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 0, i256* %116, align 4
//CHECK-NEXT:   br label %unrolled_loop19
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop19:
//CHECK-NEXT:   %117 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %117, align 4
//CHECK-NEXT:   %118 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %119 = load [0 x i256]*, [0 x i256]** %118, align 8
//CHECK-NEXT:   %120 = getelementptr [0 x i256], [0 x i256]* %119, i32 0, i32 0
//CHECK-NEXT:   %121 = load i256, i256* %120, align 4
//CHECK-NEXT:   %122 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %121, i256* %122, align 4
//CHECK-NEXT:   %123 = load i256, i256* %122, align 4
//CHECK-NEXT:   %constraint28 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %121, i256 %123, i1* %constraint28)
//CHECK-NEXT:   %124 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %124, align 4
//CHECK-NEXT:   %125 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %126 = load [0 x i256]*, [0 x i256]** %125, align 8
//CHECK-NEXT:   %127 = getelementptr [0 x i256], [0 x i256]* %126, i32 0, i32 0
//CHECK-NEXT:   %128 = load i256, i256* %127, align 4
//CHECK-NEXT:   %129 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:   store i256 %128, i256* %129, align 4
//CHECK-NEXT:   %130 = load i256, i256* %129, align 4
//CHECK-NEXT:   %constraint29 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %128, i256 %130, i1* %constraint29)
//CHECK-NEXT:   %131 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %131, align 4
//CHECK-NEXT:   %132 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 1, i256* %132, align 4
//CHECK-NEXT:   %133 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %133, align 4
//CHECK-NEXT:   %134 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %135 = load [0 x i256]*, [0 x i256]** %134, align 8
//CHECK-NEXT:   %136 = getelementptr [0 x i256], [0 x i256]* %135, i32 0, i32 1
//CHECK-NEXT:   %137 = load i256, i256* %136, align 4
//CHECK-NEXT:   %138 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 2
//CHECK-NEXT:   store i256 %137, i256* %138, align 4
//CHECK-NEXT:   %139 = load i256, i256* %138, align 4
//CHECK-NEXT:   %constraint30 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %137, i256 %139, i1* %constraint30)
//CHECK-NEXT:   %140 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %140, align 4
//CHECK-NEXT:   %141 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %142 = load [0 x i256]*, [0 x i256]** %141, align 8
//CHECK-NEXT:   %143 = getelementptr [0 x i256], [0 x i256]* %142, i32 0, i32 1
//CHECK-NEXT:   %144 = load i256, i256* %143, align 4
//CHECK-NEXT:   %145 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 3
//CHECK-NEXT:   store i256 %144, i256* %145, align 4
//CHECK-NEXT:   %146 = load i256, i256* %145, align 4
//CHECK-NEXT:   %constraint31 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %144, i256 %146, i1* %constraint31)
//CHECK-NEXT:   %147 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %147, align 4
//CHECK-NEXT:   %148 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 2, i256* %148, align 4
//CHECK-NEXT:   br label %store20
//CHECK-EMPTY: 
//CHECK-NEXT: store20:
//CHECK-NEXT:   %149 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 0, i256* %149, align 4
//CHECK-NEXT:   br label %unrolled_loop21
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop21:
//CHECK-NEXT:   %150 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %150, align 4
//CHECK-NEXT:   %151 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %152 = load [0 x i256]*, [0 x i256]** %151, align 8
//CHECK-NEXT:   %153 = getelementptr [0 x i256], [0 x i256]* %152, i32 0, i32 0
//CHECK-NEXT:   %154 = load i256, i256* %153, align 4
//CHECK-NEXT:   %155 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 4
//CHECK-NEXT:   store i256 %154, i256* %155, align 4
//CHECK-NEXT:   %156 = load i256, i256* %155, align 4
//CHECK-NEXT:   %constraint32 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %154, i256 %156, i1* %constraint32)
//CHECK-NEXT:   %157 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %157, align 4
//CHECK-NEXT:   %158 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 3, i32 0
//CHECK-NEXT:   %159 = load [0 x i256]*, [0 x i256]** %158, align 8
//CHECK-NEXT:   %160 = getelementptr [0 x i256], [0 x i256]* %159, i32 0, i32 0
//CHECK-NEXT:   %161 = load i256, i256* %160, align 4
//CHECK-NEXT:   %162 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 5
//CHECK-NEXT:   store i256 %161, i256* %162, align 4
//CHECK-NEXT:   %163 = load i256, i256* %162, align 4
//CHECK-NEXT:   %constraint33 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %161, i256 %163, i1* %constraint33)
//CHECK-NEXT:   %164 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %164, align 4
//CHECK-NEXT:   %165 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 1, i256* %165, align 4
//CHECK-NEXT:   %166 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %166, align 4
//CHECK-NEXT:   %167 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %168 = load [0 x i256]*, [0 x i256]** %167, align 8
//CHECK-NEXT:   %169 = getelementptr [0 x i256], [0 x i256]* %168, i32 0, i32 1
//CHECK-NEXT:   %170 = load i256, i256* %169, align 4
//CHECK-NEXT:   %171 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 6
//CHECK-NEXT:   store i256 %170, i256* %171, align 4
//CHECK-NEXT:   %172 = load i256, i256* %171, align 4
//CHECK-NEXT:   %constraint34 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %170, i256 %172, i1* %constraint34)
//CHECK-NEXT:   %173 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %173, align 4
//CHECK-NEXT:   %174 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 3, i32 0
//CHECK-NEXT:   %175 = load [0 x i256]*, [0 x i256]** %174, align 8
//CHECK-NEXT:   %176 = getelementptr [0 x i256], [0 x i256]* %175, i32 0, i32 1
//CHECK-NEXT:   %177 = load i256, i256* %176, align 4
//CHECK-NEXT:   %178 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 7
//CHECK-NEXT:   store i256 %177, i256* %178, align 4
//CHECK-NEXT:   %179 = load i256, i256* %178, align 4
//CHECK-NEXT:   %constraint35 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %177, i256 %179, i1* %constraint35)
//CHECK-NEXT:   %180 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %180, align 4
//CHECK-NEXT:   %181 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 2, i256* %181, align 4
//CHECK-NEXT:   %182 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %182, align 4
//CHECK-NEXT:   %183 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %184 = load [0 x i256]*, [0 x i256]** %183, align 8
//CHECK-NEXT:   %185 = getelementptr [0 x i256], [0 x i256]* %184, i32 0, i32 2
//CHECK-NEXT:   %186 = load i256, i256* %185, align 4
//CHECK-NEXT:   %187 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 8
//CHECK-NEXT:   store i256 %186, i256* %187, align 4
//CHECK-NEXT:   %188 = load i256, i256* %187, align 4
//CHECK-NEXT:   %constraint36 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %186, i256 %188, i1* %constraint36)
//CHECK-NEXT:   %189 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %189, align 4
//CHECK-NEXT:   %190 = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 3, i32 0
//CHECK-NEXT:   %191 = load [0 x i256]*, [0 x i256]** %190, align 8
//CHECK-NEXT:   %192 = getelementptr [0 x i256], [0 x i256]* %191, i32 0, i32 2
//CHECK-NEXT:   %193 = load i256, i256* %192, align 4
//CHECK-NEXT:   %194 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 9
//CHECK-NEXT:   store i256 %193, i256* %194, align 4
//CHECK-NEXT:   %195 = load i256, i256* %194, align 4
//CHECK-NEXT:   %constraint37 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %193, i256 %195, i1* %constraint37)
//CHECK-NEXT:   %196 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %196, align 4
//CHECK-NEXT:   %197 = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 3, i256* %197, align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
