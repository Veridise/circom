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

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]], i256* %fix_[[X3:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9]+]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr i256, i256* %fix_[[X2]], i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr i256, i256* %fix_[[X3]], i32 0
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %call.fr_mul = call i256 @fr_mul(i256 %1, i256 %3)
//CHECK-NEXT:   %4 = getelementptr i256, i256* %fix_[[X1]], i32 0
//CHECK-NEXT:   store i256 %call.fr_mul, i256* %4, align 4
//CHECK-NEXT:   %5 = load i256, i256* %4, align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %call.fr_mul, i256 %5, i1* %constraint)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %7 = load i256, i256* %6, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %7, i256 1)
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 %call.fr_add, i256* %8, align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]], i256* %fix_[[X3:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2:[0-9]+]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr i256, i256* %fix_[[X2]], i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr i256, i256* %fix_[[X3]], i32 0
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %call.fr_mul = call i256 @fr_mul(i256 %1, i256 %3)
//CHECK-NEXT:   %4 = getelementptr i256, i256* %fix_[[X1]], i32 0
//CHECK-NEXT:   store i256 %call.fr_mul, i256* %4, align 4
//CHECK-NEXT:   %5 = load i256, i256* %4, align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %call.fr_mul, i256 %5, i1* %constraint)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %7 = load i256, i256* %6, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %7, i256 1)
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 %call.fr_add, i256* %8, align 4
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
//CHECK-NEXT:   %1 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 4, i256* %1, align 4
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
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 4
//CHECK-NEXT:   %7 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 8
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %4, [0 x i256]* %0, i256* %5, i256* %6, i256* %7)
//CHECK-NEXT:   %8 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %10 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 5
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 9
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %8, [0 x i256]* %0, i256* %9, i256* %10, i256* %11)
//CHECK-NEXT:   %12 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %13 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   %14 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 6
//CHECK-NEXT:   %15 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 10
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %12, [0 x i256]* %0, i256* %13, i256* %14, i256* %15)
//CHECK-NEXT:   %16 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %17 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   %18 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 7
//CHECK-NEXT:   %19 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 11
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %16, [0 x i256]* %0, i256* %17, i256* %18, i256* %19)
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
//CHECK-NEXT:   %7 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 4
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %4, [0 x i256]* %0, i256* %5, i256* %6, i256* %7)
//CHECK-NEXT:   %8 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %10 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 5
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %8, [0 x i256]* %0, i256* %9, i256* %10, i256* %11)
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
//CHECK-NEXT:   %1 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 2, i256* %1, align 4
//CHECK-NEXT:   br label %create_cmp2
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp2:
//CHECK-NEXT:   %2 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0
//CHECK-NEXT:   call void @A_0_build({ [0 x i256]*, i32 }* %2)
//CHECK-NEXT:   br label %create_cmp3
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp3:
//CHECK-NEXT:   %3 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1
//CHECK-NEXT:   call void @A_1_build({ [0 x i256]*, i32 }* %3)
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %4 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %4, align 4
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %5 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %5, align 4
//CHECK-NEXT:   br label %unrolled_loop6
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop6:
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 2
//CHECK-NEXT:   %7 = load i256, i256* %6, align 4
//CHECK-NEXT:   %8 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %9 = load [0 x i256]*, [0 x i256]** %8, align 8
//CHECK-NEXT:   %10 = getelementptr [0 x i256], [0 x i256]* %9, i32 0, i32 4
//CHECK-NEXT:   store i256 %7, i256* %10, align 4
//CHECK-NEXT:   %11 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %load.subcmp.counter = load i32, i32* %11, align 4
//CHECK-NEXT:   %decrement.counter = sub i32 %load.subcmp.counter, 1
//CHECK-NEXT:   store i32 %decrement.counter, i32* %11, align 4
//CHECK-NEXT:   %12 = load i256, i256* %10, align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %7, i256 %12, i1* %constraint)
//CHECK-NEXT:   %13 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 6
//CHECK-NEXT:   %14 = load i256, i256* %13, align 4
//CHECK-NEXT:   %15 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %16 = load [0 x i256]*, [0 x i256]** %15, align 8
//CHECK-NEXT:   %17 = getelementptr [0 x i256], [0 x i256]* %16, i32 0, i32 8
//CHECK-NEXT:   store i256 %14, i256* %17, align 4
//CHECK-NEXT:   %18 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %load.subcmp.counter1 = load i32, i32* %18, align 4
//CHECK-NEXT:   %decrement.counter2 = sub i32 %load.subcmp.counter1, 1
//CHECK-NEXT:   store i32 %decrement.counter2, i32* %18, align 4
//CHECK-NEXT:   %19 = load i256, i256* %17, align 4
//CHECK-NEXT:   %constraint3 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %14, i256 %19, i1* %constraint3)
//CHECK-NEXT:   %20 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 1, i256* %20, align 4
//CHECK-NEXT:   %21 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 3
//CHECK-NEXT:   %22 = load i256, i256* %21, align 4
//CHECK-NEXT:   %23 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %24 = load [0 x i256]*, [0 x i256]** %23, align 8
//CHECK-NEXT:   %25 = getelementptr [0 x i256], [0 x i256]* %24, i32 0, i32 5
//CHECK-NEXT:   store i256 %22, i256* %25, align 4
//CHECK-NEXT:   %26 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %load.subcmp.counter4 = load i32, i32* %26, align 4
//CHECK-NEXT:   %decrement.counter5 = sub i32 %load.subcmp.counter4, 1
//CHECK-NEXT:   store i32 %decrement.counter5, i32* %26, align 4
//CHECK-NEXT:   %27 = load i256, i256* %25, align 4
//CHECK-NEXT:   %constraint6 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %22, i256 %27, i1* %constraint6)
//CHECK-NEXT:   %28 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 7
//CHECK-NEXT:   %29 = load i256, i256* %28, align 4
//CHECK-NEXT:   %30 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %31 = load [0 x i256]*, [0 x i256]** %30, align 8
//CHECK-NEXT:   %32 = getelementptr [0 x i256], [0 x i256]* %31, i32 0, i32 9
//CHECK-NEXT:   store i256 %29, i256* %32, align 4
//CHECK-NEXT:   %33 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %load.subcmp.counter7 = load i32, i32* %33, align 4
//CHECK-NEXT:   %decrement.counter8 = sub i32 %load.subcmp.counter7, 1
//CHECK-NEXT:   store i32 %decrement.counter8, i32* %33, align 4
//CHECK-NEXT:   %34 = load i256, i256* %32, align 4
//CHECK-NEXT:   %constraint9 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %29, i256 %34, i1* %constraint9)
//CHECK-NEXT:   %35 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 2, i256* %35, align 4
//CHECK-NEXT:   %36 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 4
//CHECK-NEXT:   %37 = load i256, i256* %36, align 4
//CHECK-NEXT:   %38 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %39 = load [0 x i256]*, [0 x i256]** %38, align 8
//CHECK-NEXT:   %40 = getelementptr [0 x i256], [0 x i256]* %39, i32 0, i32 6
//CHECK-NEXT:   store i256 %37, i256* %40, align 4
//CHECK-NEXT:   %41 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %load.subcmp.counter10 = load i32, i32* %41, align 4
//CHECK-NEXT:   %decrement.counter11 = sub i32 %load.subcmp.counter10, 1
//CHECK-NEXT:   store i32 %decrement.counter11, i32* %41, align 4
//CHECK-NEXT:   %42 = load i256, i256* %40, align 4
//CHECK-NEXT:   %constraint12 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %37, i256 %42, i1* %constraint12)
//CHECK-NEXT:   %43 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 8
//CHECK-NEXT:   %44 = load i256, i256* %43, align 4
//CHECK-NEXT:   %45 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %46 = load [0 x i256]*, [0 x i256]** %45, align 8
//CHECK-NEXT:   %47 = getelementptr [0 x i256], [0 x i256]* %46, i32 0, i32 10
//CHECK-NEXT:   store i256 %44, i256* %47, align 4
//CHECK-NEXT:   %48 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %load.subcmp.counter13 = load i32, i32* %48, align 4
//CHECK-NEXT:   %decrement.counter14 = sub i32 %load.subcmp.counter13, 1
//CHECK-NEXT:   store i32 %decrement.counter14, i32* %48, align 4
//CHECK-NEXT:   %49 = load i256, i256* %47, align 4
//CHECK-NEXT:   %constraint15 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %44, i256 %49, i1* %constraint15)
//CHECK-NEXT:   %50 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 3, i256* %50, align 4
//CHECK-NEXT:   %51 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 5
//CHECK-NEXT:   %52 = load i256, i256* %51, align 4
//CHECK-NEXT:   %53 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %54 = load [0 x i256]*, [0 x i256]** %53, align 8
//CHECK-NEXT:   %55 = getelementptr [0 x i256], [0 x i256]* %54, i32 0, i32 7
//CHECK-NEXT:   store i256 %52, i256* %55, align 4
//CHECK-NEXT:   %56 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %load.subcmp.counter16 = load i32, i32* %56, align 4
//CHECK-NEXT:   %decrement.counter17 = sub i32 %load.subcmp.counter16, 1
//CHECK-NEXT:   store i32 %decrement.counter17, i32* %56, align 4
//CHECK-NEXT:   %57 = load i256, i256* %55, align 4
//CHECK-NEXT:   %constraint18 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %52, i256 %57, i1* %constraint18)
//CHECK-NEXT:   %58 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 9
//CHECK-NEXT:   %59 = load i256, i256* %58, align 4
//CHECK-NEXT:   %60 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %61 = load [0 x i256]*, [0 x i256]** %60, align 8
//CHECK-NEXT:   %62 = getelementptr [0 x i256], [0 x i256]* %61, i32 0, i32 11
//CHECK-NEXT:   store i256 %59, i256* %62, align 4
//CHECK-NEXT:   %63 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %load.subcmp.counter19 = load i32, i32* %63, align 4
//CHECK-NEXT:   %decrement.counter20 = sub i32 %load.subcmp.counter19, 1
//CHECK-NEXT:   store i32 %decrement.counter20, i32* %63, align 4
//CHECK-NEXT:   %64 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %65 = load [0 x i256]*, [0 x i256]** %64, align 8
//CHECK-NEXT:   call void @A_0_run([0 x i256]* %65)
//CHECK-NEXT:   %66 = load i256, i256* %62, align 4
//CHECK-NEXT:   %constraint21 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %59, i256 %66, i1* %constraint21)
//CHECK-NEXT:   %67 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 4, i256* %67, align 4
//CHECK-NEXT:   br label %store7
//CHECK-EMPTY: 
//CHECK-NEXT: store7:
//CHECK-NEXT:   %68 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %68, align 4
//CHECK-NEXT:   br label %unrolled_loop8
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop8:
//CHECK-NEXT:   %69 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %70 = load [0 x i256]*, [0 x i256]** %69, align 8
//CHECK-NEXT:   %71 = getelementptr [0 x i256], [0 x i256]* %70, i32 0, i32 0
//CHECK-NEXT:   %72 = load i256, i256* %71, align 4
//CHECK-NEXT:   %73 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %74 = load [0 x i256]*, [0 x i256]** %73, align 8
//CHECK-NEXT:   %75 = getelementptr [0 x i256], [0 x i256]* %74, i32 0, i32 2
//CHECK-NEXT:   store i256 %72, i256* %75, align 4
//CHECK-NEXT:   %76 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %load.subcmp.counter22 = load i32, i32* %76, align 4
//CHECK-NEXT:   %decrement.counter23 = sub i32 %load.subcmp.counter22, 1
//CHECK-NEXT:   store i32 %decrement.counter23, i32* %76, align 4
//CHECK-NEXT:   %77 = load i256, i256* %75, align 4
//CHECK-NEXT:   %constraint24 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %72, i256 %77, i1* %constraint24)
//CHECK-NEXT:   %78 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %79 = load [0 x i256]*, [0 x i256]** %78, align 8
//CHECK-NEXT:   %80 = getelementptr [0 x i256], [0 x i256]* %79, i32 0, i32 2
//CHECK-NEXT:   %81 = load i256, i256* %80, align 4
//CHECK-NEXT:   %82 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %83 = load [0 x i256]*, [0 x i256]** %82, align 8
//CHECK-NEXT:   %84 = getelementptr [0 x i256], [0 x i256]* %83, i32 0, i32 4
//CHECK-NEXT:   store i256 %81, i256* %84, align 4
//CHECK-NEXT:   %85 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %load.subcmp.counter25 = load i32, i32* %85, align 4
//CHECK-NEXT:   %decrement.counter26 = sub i32 %load.subcmp.counter25, 1
//CHECK-NEXT:   store i32 %decrement.counter26, i32* %85, align 4
//CHECK-NEXT:   %86 = load i256, i256* %84, align 4
//CHECK-NEXT:   %constraint27 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %81, i256 %86, i1* %constraint27)
//CHECK-NEXT:   %87 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 1, i256* %87, align 4
//CHECK-NEXT:   %88 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %89 = load [0 x i256]*, [0 x i256]** %88, align 8
//CHECK-NEXT:   %90 = getelementptr [0 x i256], [0 x i256]* %89, i32 0, i32 1
//CHECK-NEXT:   %91 = load i256, i256* %90, align 4
//CHECK-NEXT:   %92 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %93 = load [0 x i256]*, [0 x i256]** %92, align 8
//CHECK-NEXT:   %94 = getelementptr [0 x i256], [0 x i256]* %93, i32 0, i32 3
//CHECK-NEXT:   store i256 %91, i256* %94, align 4
//CHECK-NEXT:   %95 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %load.subcmp.counter28 = load i32, i32* %95, align 4
//CHECK-NEXT:   %decrement.counter29 = sub i32 %load.subcmp.counter28, 1
//CHECK-NEXT:   store i32 %decrement.counter29, i32* %95, align 4
//CHECK-NEXT:   %96 = load i256, i256* %94, align 4
//CHECK-NEXT:   %constraint30 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %91, i256 %96, i1* %constraint30)
//CHECK-NEXT:   %97 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %98 = load [0 x i256]*, [0 x i256]** %97, align 8
//CHECK-NEXT:   %99 = getelementptr [0 x i256], [0 x i256]* %98, i32 0, i32 3
//CHECK-NEXT:   %100 = load i256, i256* %99, align 4
//CHECK-NEXT:   %101 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %102 = load [0 x i256]*, [0 x i256]** %101, align 8
//CHECK-NEXT:   %103 = getelementptr [0 x i256], [0 x i256]* %102, i32 0, i32 5
//CHECK-NEXT:   store i256 %100, i256* %103, align 4
//CHECK-NEXT:   %104 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %load.subcmp.counter31 = load i32, i32* %104, align 4
//CHECK-NEXT:   %decrement.counter32 = sub i32 %load.subcmp.counter31, 1
//CHECK-NEXT:   store i32 %decrement.counter32, i32* %104, align 4
//CHECK-NEXT:   %105 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %106 = load [0 x i256]*, [0 x i256]** %105, align 8
//CHECK-NEXT:   call void @A_1_run([0 x i256]* %106)
//CHECK-NEXT:   %107 = load i256, i256* %103, align 4
//CHECK-NEXT:   %constraint33 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %100, i256 %107, i1* %constraint33)
//CHECK-NEXT:   %108 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 2, i256* %108, align 4
//CHECK-NEXT:   br label %store9
//CHECK-EMPTY: 
//CHECK-NEXT: store9:
//CHECK-NEXT:   %109 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %109, align 4
//CHECK-NEXT:   br label %unrolled_loop10
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop10:
//CHECK-NEXT:   %110 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %111 = load [0 x i256]*, [0 x i256]** %110, align 8
//CHECK-NEXT:   %112 = getelementptr [0 x i256], [0 x i256]* %111, i32 0, i32 0
//CHECK-NEXT:   %113 = load i256, i256* %112, align 4
//CHECK-NEXT:   %114 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %113, i256* %114, align 4
//CHECK-NEXT:   %115 = load i256, i256* %114, align 4
//CHECK-NEXT:   %constraint34 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %113, i256 %115, i1* %constraint34)
//CHECK-NEXT:   %116 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 1, i256* %116, align 4
//CHECK-NEXT:   %117 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %118 = load [0 x i256]*, [0 x i256]** %117, align 8
//CHECK-NEXT:   %119 = getelementptr [0 x i256], [0 x i256]* %118, i32 0, i32 1
//CHECK-NEXT:   %120 = load i256, i256* %119, align 4
//CHECK-NEXT:   %121 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:   store i256 %120, i256* %121, align 4
//CHECK-NEXT:   %122 = load i256, i256* %121, align 4
//CHECK-NEXT:   %constraint35 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %120, i256 %122, i1* %constraint35)
//CHECK-NEXT:   %123 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 2, i256* %123, align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
