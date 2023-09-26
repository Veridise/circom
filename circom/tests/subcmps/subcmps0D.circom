pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template Add() {
    signal input in1;
    signal input in2;
    signal output out;
    out <-- in1 + in2;
}

template SubCmps0D(n) {
    signal input ins[n];
    signal output outs[n];

    component a[n];
    for (var i = 0; i < n; i++) {
        a[i] = Add();
        a[i].in1 <-- ins[i];
        a[i].in2 <-- ins[i];
        outs[i] <-- a[i].out;
    }
}

component main = SubCmps0D(3);

//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %subfix_[[X0:[0-9]+]], i256* %fix_[[X1:[0-9]+]], i256* %subfix_[[X2:[0-9]+]], i256* %fix_[[X3:[0-9]+]],
//CHECK-SAME: i256* %fix_[[X4:[0-9]+]], i256* %subfix_[[X5:[0-9]+]], [0 x i256]* %sub_[[X2]], i256* %subc_[[X2]], [0 x i256]* %sub_[[X5]], i256* %subc_[[X5]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr i256, i256* %fix_[[X1]], i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr i256, i256* %subfix_[[X0]], i32 0
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %sub_[[X2]], i32 0
//CHECK-NEXT:   call void @Add_0_run([0 x i256]* %sub_[[X2]])
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %4 = getelementptr i256, i256* %fix_[[X3]], i32 0
//CHECK-NEXT:   %5 = load i256, i256* %4, align 4
//CHECK-NEXT:   %6 = getelementptr i256, i256* %subfix_[[X2]], i32 0
//CHECK-NEXT:   store i256 %5, i256* %6, align 4
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %7 = getelementptr [0 x i256], [0 x i256]* %sub_[[X2]], i32 0
//CHECK-NEXT:   call void @Add_0_run([0 x i256]* %sub_[[X2]])
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %8 = getelementptr i256, i256* %subfix_[[X5]], i32 0
//CHECK-NEXT:   %9 = load i256, i256* %8, align 4
//CHECK-NEXT:   %10 = getelementptr i256, i256* %fix_[[X4]], i32 0
//CHECK-NEXT:   store i256 %9, i256* %10, align 4
//CHECK-NEXT:   br label %store6
//CHECK-EMPTY: 
//CHECK-NEXT: store6:
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %12 = load i256, i256* %11, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %12, i256 1)
//CHECK-NEXT:   %13 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 %call.fr_add, i256* %13, align 4
//CHECK-NEXT:   br label %return7
//CHECK-EMPTY: 
//CHECK-NEXT: return7:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @Add_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [0 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:   %2 = load i256, i256* %1, align 4
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 2
//CHECK-NEXT:   %4 = load i256, i256* %3, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %2, i256 %4)
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %call.fr_add, i256* %5, align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @SubCmps0D_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
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
//CHECK-NEXT:   call void @Add_0_build({ [0 x i256]*, i32 }* %2)
//CHECK-NEXT:   %3 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1
//CHECK-NEXT:   call void @Add_0_build({ [0 x i256]*, i32 }* %3)
//CHECK-NEXT:   %4 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2
//CHECK-NEXT:   call void @Add_0_build({ [0 x i256]*, i32 }* %4)
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %5 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %5, align 4
//CHECK-NEXT:   br label %unrolled_loop4
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop4:
//CHECK-NEXT:   %6 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %7 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %8 = load [0 x i256]*, [0 x i256]** %7, align 8
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %8, i32 0
//CHECK-NEXT:   %10 = getelementptr [0 x i256], [0 x i256]* %9, i32 0, i256 1
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   %12 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %13 = load [0 x i256]*, [0 x i256]** %12, align 8
//CHECK-NEXT:   %14 = getelementptr [0 x i256], [0 x i256]* %13, i32 0
//CHECK-NEXT:   %15 = getelementptr [0 x i256], [0 x i256]* %14, i32 0, i256 2
//CHECK-NEXT:   %16 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   %17 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   %18 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %19 = load [0 x i256]*, [0 x i256]** %18, align 8
//CHECK-NEXT:   %20 = getelementptr [0 x i256], [0 x i256]* %19, i32 0
//CHECK-NEXT:   %21 = getelementptr [0 x i256], [0 x i256]* %20, i32 0, i256 0
//CHECK-NEXT:   %22 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %23 = load [0 x i256]*, [0 x i256]** %22, align 8
//CHECK-NEXT:   %24 = getelementptr [0 x i256], [0 x i256]* %23, i32 0
//CHECK-NEXT:   %25 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %26 = bitcast i32* %25 to i256*
//CHECK-NEXT:   %27 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %28 = load [0 x i256]*, [0 x i256]** %27, align 8
//CHECK-NEXT:   %29 = getelementptr [0 x i256], [0 x i256]* %28, i32 0
//CHECK-NEXT:   %30 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %31 = bitcast i32* %30 to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %6, [0 x i256]* %0, i256* %10, i256* %11, i256* %15, i256* %16, i256* %17, i256* %21, [0 x i256]* %24, i256* %26, [0 x i256]* %29, i256* %31)
//CHECK-NEXT:   %32 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %33 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %34 = load [0 x i256]*, [0 x i256]** %33, align 8
//CHECK-NEXT:   %35 = getelementptr [0 x i256], [0 x i256]* %34, i32 0
//CHECK-NEXT:   %36 = getelementptr [0 x i256], [0 x i256]* %35, i32 0, i256 1
//CHECK-NEXT:   %37 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 4
//CHECK-NEXT:   %38 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %39 = load [0 x i256]*, [0 x i256]** %38, align 8
//CHECK-NEXT:   %40 = getelementptr [0 x i256], [0 x i256]* %39, i32 0
//CHECK-NEXT:   %41 = getelementptr [0 x i256], [0 x i256]* %40, i32 0, i256 2
//CHECK-NEXT:   %42 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 4
//CHECK-NEXT:   %43 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %44 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %45 = load [0 x i256]*, [0 x i256]** %44, align 8
//CHECK-NEXT:   %46 = getelementptr [0 x i256], [0 x i256]* %45, i32 0
//CHECK-NEXT:   %47 = getelementptr [0 x i256], [0 x i256]* %46, i32 0, i256 0
//CHECK-NEXT:   %48 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %49 = load [0 x i256]*, [0 x i256]** %48, align 8
//CHECK-NEXT:   %50 = getelementptr [0 x i256], [0 x i256]* %49, i32 0
//CHECK-NEXT:   %51 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %52 = bitcast i32* %51 to i256*
//CHECK-NEXT:   %53 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %54 = load [0 x i256]*, [0 x i256]** %53, align 8
//CHECK-NEXT:   %55 = getelementptr [0 x i256], [0 x i256]* %54, i32 0
//CHECK-NEXT:   %56 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %57 = bitcast i32* %56 to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %32, [0 x i256]* %0, i256* %36, i256* %37, i256* %41, i256* %42, i256* %43, i256* %47, [0 x i256]* %50, i256* %52, [0 x i256]* %55, i256* %57)
//CHECK-NEXT:   %58 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %59 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %60 = load [0 x i256]*, [0 x i256]** %59, align 8
//CHECK-NEXT:   %61 = getelementptr [0 x i256], [0 x i256]* %60, i32 0
//CHECK-NEXT:   %62 = getelementptr [0 x i256], [0 x i256]* %61, i32 0, i256 1
//CHECK-NEXT:   %63 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 5
//CHECK-NEXT:   %64 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %65 = load [0 x i256]*, [0 x i256]** %64, align 8
//CHECK-NEXT:   %66 = getelementptr [0 x i256], [0 x i256]* %65, i32 0
//CHECK-NEXT:   %67 = getelementptr [0 x i256], [0 x i256]* %66, i32 0, i256 2
//CHECK-NEXT:   %68 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 5
//CHECK-NEXT:   %69 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   %70 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %71 = load [0 x i256]*, [0 x i256]** %70, align 8
//CHECK-NEXT:   %72 = getelementptr [0 x i256], [0 x i256]* %71, i32 0
//CHECK-NEXT:   %73 = getelementptr [0 x i256], [0 x i256]* %72, i32 0, i256 0
//CHECK-NEXT:   %74 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %75 = load [0 x i256]*, [0 x i256]** %74, align 8
//CHECK-NEXT:   %76 = getelementptr [0 x i256], [0 x i256]* %75, i32 0
//CHECK-NEXT:   %77 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 1
//CHECK-NEXT:   %78 = bitcast i32* %77 to i256*
//CHECK-NEXT:   %79 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %80 = load [0 x i256]*, [0 x i256]** %79, align 8
//CHECK-NEXT:   %81 = getelementptr [0 x i256], [0 x i256]* %80, i32 0
//CHECK-NEXT:   %82 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 1
//CHECK-NEXT:   %83 = bitcast i32* %82 to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %58, [0 x i256]* %0, i256* %62, i256* %63, i256* %67, i256* %68, i256* %69, i256* %73, [0 x i256]* %76, i256* %78, [0 x i256]* %81, i256* %83)
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
