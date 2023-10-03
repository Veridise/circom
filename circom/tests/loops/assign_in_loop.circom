pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.* // panicked at 'not yet implemented', circuit_passes/src/passes/loop_unroll/loop_env_recorder.rs:149:44 (LocationRule::Mapped case)

template Inner(i) {
    signal input in;
    signal output out;
    
    out <-- (in >> i) & 1;
}

template Num2Bits(n) {
    signal input in;
    signal output out[n];
    
    component c[n];
    for (var i = 0; i < n; i++) {
    	c[i] = Inner(i);
    	c[i].in <-- in;
    	out[i] <-- c[i].out;
    }
}

component main = Num2Bits(3);

//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %subfix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]], i256* %subfix_[[X3:[0-9]+]],
//CHECK-SAME: [0 x i256]* %sub_[[X1]], i256* %subc_[[X1]], [0 x i256]* %sub_[[X3]], i256* %subc_[[X3]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 3
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr i256, i256* %subfix_[[X1]], i32 0
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %sub_[[X1]], i32 0
//CHECK-NEXT:   call void @Inner_?_run([0 x i256]* %sub_[[X1]])                 //TODO: which function to call depends on which iteration of the loop
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %4 = getelementptr i256, i256* %subfix_[[X3]], i32 0
//CHECK-NEXT:   %5 = load i256, i256* %4, align 4
//CHECK-NEXT:   %6 = getelementptr i256, i256* %fix_[[X2]], i32 0
//CHECK-NEXT:   store i256 %5, i256* %6, align 4
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %7 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %8 = load i256, i256* %7, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %8, i256 1)
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 %call.fr_add, i256* %9, align 4
//CHECK-NEXT:   br label %return5
//CHECK-EMPTY: 
//CHECK-NEXT: return5:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @Inner_0_build({ [0 x i256]*, i32 }* %0){{.*}} {
//
//CHECK-LABEL: define void @Inner_0_run([0 x i256]* %0){{.*}} {
//
//CHECK-LABEL: define void @Inner_1_build({ [0 x i256]*, i32 }* %0){{.*}} {
//
//CHECK-LABEL: define void @Inner_1_run([0 x i256]* %0){{.*}} {
//
//CHECK-LABEL: define void @Inner_2_build({ [0 x i256]*, i32 }* %0){{.*}} {
//
//CHECK-LABEL: define void @Inner_2_run([0 x i256]* %0){{.*}} {
//
//CHECK-LABEL: define void @Num2Bits_3_build({ [0 x i256]*, i32 }* %0){{.*}} {
//CHECK-NEXT: main:
//CHECK-NEXT:   %1 = alloca [4 x i256], align 8
//CHECK-NEXT:   %2 = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 1
//CHECK-NEXT:   store i32 1, i32* %2, align 4
//CHECK-NEXT:   %3 = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 0
//CHECK-NEXT:   %4 = bitcast [4 x i256]* %1 to [0 x i256]*
//CHECK-NEXT:   store [0 x i256]* %4, [0 x i256]** %3, align 8
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @Num2Bits_3_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [2 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [3 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 3, i256* %1, align 4
//CHECK-NEXT:   br label %create_cmp2
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp2:
//CHECK-NEXT:   %2 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0
//CHECK-NEXT:   call void @Inner_0_build({ [0 x i256]*, i32 }* %2)
//CHECK-NEXT:   br label %create_cmp3
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp3:
//CHECK-NEXT:   %3 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1
//CHECK-NEXT:   call void @Inner_1_build({ [0 x i256]*, i32 }* %3)
//CHECK-NEXT:   br label %create_cmp4
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp4:
//CHECK-NEXT:   %4 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2
//CHECK-NEXT:   call void @Inner_2_build({ [0 x i256]*, i32 }* %4)
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %5 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %5, align 4
//CHECK-NEXT:   br label %unrolled_loop6
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop6:
//CHECK-NEXT:   %6 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %7 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %8 = load [0 x i256]*, [0 x i256]** %7, align 8
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %8, i32 0
//CHECK-NEXT:   %10 = getelementptr [0 x i256], [0 x i256]* %9, i32 0, i256 1
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   %12 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %13 = load [0 x i256]*, [0 x i256]** %12, align 8
//CHECK-NEXT:   %14 = getelementptr [0 x i256], [0 x i256]* %13, i32 0
//CHECK-NEXT:   %15 = getelementptr [0 x i256], [0 x i256]* %14, i32 0, i256 0
//CHECK-NEXT:   %16 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %17 = load [0 x i256]*, [0 x i256]** %16, align 8
//CHECK-NEXT:   %18 = getelementptr [0 x i256], [0 x i256]* %17, i32 0
//CHECK-NEXT:   %19 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %20 = bitcast i32* %19 to i256*
//CHECK-NEXT:   %21 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %22 = load [0 x i256]*, [0 x i256]** %21, align 8
//CHECK-NEXT:   %23 = getelementptr [0 x i256], [0 x i256]* %22, i32 0
//CHECK-NEXT:   %24 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %25 = bitcast i32* %24 to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %6, [0 x i256]* %0, i256* %10, i256* %11, i256* %15, [0 x i256]* %18, i256* %20, [0 x i256]* %23, i256* %25)
//CHECK-NEXT:   %26 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %27 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %28 = load [0 x i256]*, [0 x i256]** %27, align 8
//CHECK-NEXT:   %29 = getelementptr [0 x i256], [0 x i256]* %28, i32 0
//CHECK-NEXT:   %30 = getelementptr [0 x i256], [0 x i256]* %29, i32 0, i256 1
//CHECK-NEXT:   %31 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %32 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %33 = load [0 x i256]*, [0 x i256]** %32, align 8
//CHECK-NEXT:   %34 = getelementptr [0 x i256], [0 x i256]* %33, i32 0
//CHECK-NEXT:   %35 = getelementptr [0 x i256], [0 x i256]* %34, i32 0, i256 0
//CHECK-NEXT:   %36 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %37 = load [0 x i256]*, [0 x i256]** %36, align 8
//CHECK-NEXT:   %38 = getelementptr [0 x i256], [0 x i256]* %37, i32 0
//CHECK-NEXT:   %39 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %40 = bitcast i32* %39 to i256*
//CHECK-NEXT:   %41 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %42 = load [0 x i256]*, [0 x i256]** %41, align 8
//CHECK-NEXT:   %43 = getelementptr [0 x i256], [0 x i256]* %42, i32 0
//CHECK-NEXT:   %44 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %45 = bitcast i32* %44 to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %26, [0 x i256]* %0, i256* %30, i256* %31, i256* %35, [0 x i256]* %38, i256* %40, [0 x i256]* %43, i256* %45)
//CHECK-NEXT:   %46 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %47 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %48 = load [0 x i256]*, [0 x i256]** %47, align 8
//CHECK-NEXT:   %49 = getelementptr [0 x i256], [0 x i256]* %48, i32 0
//CHECK-NEXT:   %50 = getelementptr [0 x i256], [0 x i256]* %49, i32 0, i256 1
//CHECK-NEXT:   %51 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   %52 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %53 = load [0 x i256]*, [0 x i256]** %52, align 8
//CHECK-NEXT:   %54 = getelementptr [0 x i256], [0 x i256]* %53, i32 0
//CHECK-NEXT:   %55 = getelementptr [0 x i256], [0 x i256]* %54, i32 0, i256 0
//CHECK-NEXT:   %56 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %57 = load [0 x i256]*, [0 x i256]** %56, align 8
//CHECK-NEXT:   %58 = getelementptr [0 x i256], [0 x i256]* %57, i32 0
//CHECK-NEXT:   %59 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 1
//CHECK-NEXT:   %60 = bitcast i32* %59 to i256*
//CHECK-NEXT:   %61 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %62 = load [0 x i256]*, [0 x i256]** %61, align 8
//CHECK-NEXT:   %63 = getelementptr [0 x i256], [0 x i256]* %62, i32 0
//CHECK-NEXT:   %64 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 1
//CHECK-NEXT:   %65 = bitcast i32* %64 to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %46, [0 x i256]* %0, i256* %50, i256* %51, i256* %55, [0 x i256]* %58, i256* %60, [0 x i256]* %63, i256* %65)
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
