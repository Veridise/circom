pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// Like SubCmps1 but simpler (no constraints and fewer operations)
template IsZero() {
    signal input in;
    signal output out;
    out <-- -in;
}

template SubCmps0B(n) {
    signal input ins[n];
    signal output outs[n];
    var temp;
    component zeros[n];
    for (var i = 0; i < n; i++) {
        zeros[i] = IsZero();
        zeros[i].in <-- ins[i];     //load(fix)+store(subcmp)
        outs[i] <-- zeros[i].out;   //load(subcmp)+store(fix)
        temp = zeros[i].out;
                                    //increment iteration variable
    }
}

component main = SubCmps0B(2);

//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %subfix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]], i256* %fix_[[X3:[0-9]+]],
//CHECK-SAME: i256* %subfix_[[X4:[0-9]+]], i256* %subfix_[[X5:[0-9]+]], [0 x i256]* %sub_[[X1]], i256* %subc_[[X1]], [0 x i256]* %sub_[[X5]], i256* %subc_[[X5]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr i256, i256* %fix_[[X2]], i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr i256, i256* %subfix_[[X1]], i32 0
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %sub_[[X1]], i32 0
//CHECK-NEXT:   call void @IsZero_0_run([0 x i256]* %sub_[[X1]])
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %4 = getelementptr i256, i256* %subfix_[[X4]], i32 0
//CHECK-NEXT:   %5 = load i256, i256* %4, align 4
//CHECK-NEXT:   %6 = getelementptr i256, i256* %fix_[[X3]], i32 0
//CHECK-NEXT:   store i256 %5, i256* %6, align 4
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %7 = getelementptr i256, i256* %subfix_[[X5]], i32 0
//CHECK-NEXT:   %8 = load i256, i256* %7, align 4
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 %8, i256* %9, align 4
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %10 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %11 = load i256, i256* %10, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %11, i256 1)
//CHECK-NEXT:   %12 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 %call.fr_add, i256* %12, align 4
//CHECK-NEXT:   br label %return6
//CHECK-EMPTY: 
//CHECK-NEXT: return6:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @IsZero_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [0 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:   %2 = load i256, i256* %1, align 4
//CHECK-NEXT:   %call.fr_neg = call i256 @fr_neg(i256 %2)
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %call.fr_neg, i256* %3, align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @SubCmps0B_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [3 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [2 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 2, i256* %1, align 4
//CHECK-NEXT:   br label %create_cmp2
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp2:
//CHECK-NEXT:   %2 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0
//CHECK-NEXT:   call void @IsZero_0_build({ [0 x i256]*, i32 }* %2)
//CHECK-NEXT:   %3 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1
//CHECK-NEXT:   call void @IsZero_0_build({ [0 x i256]*, i32 }* %3)
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %4 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %4, align 4
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %5 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 0, i256* %5, align 4
//CHECK-NEXT:   br label %unrolled_loop5
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop5:
//CHECK-NEXT:   %6 = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %7 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %8 = load [0 x i256]*, [0 x i256]** %7, align 8
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %8, i32 0
//CHECK-NEXT:   %10 = getelementptr [0 x i256], [0 x i256]* %9, i32 0, i256 1
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   %12 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   %13 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %14 = load [0 x i256]*, [0 x i256]** %13, align 8
//CHECK-NEXT:   %15 = getelementptr [0 x i256], [0 x i256]* %14, i32 0
//CHECK-NEXT:   %16 = getelementptr [0 x i256], [0 x i256]* %15, i32 0, i256 0
//CHECK-NEXT:   %17 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %18 = load [0 x i256]*, [0 x i256]** %17, align 8
//CHECK-NEXT:   %19 = getelementptr [0 x i256], [0 x i256]* %18, i32 0
//CHECK-NEXT:   %20 = getelementptr [0 x i256], [0 x i256]* %19, i32 0, i256 0
//CHECK-NEXT:   %21 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %22 = load [0 x i256]*, [0 x i256]** %21, align 8
//CHECK-NEXT:   %23 = getelementptr [0 x i256], [0 x i256]* %22, i32 0
//CHECK-NEXT:   %24 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %25 = bitcast i32* %24 to i256*
//CHECK-NEXT:   %26 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %27 = load [0 x i256]*, [0 x i256]** %26, align 8
//CHECK-NEXT:   %28 = getelementptr [0 x i256], [0 x i256]* %27, i32 0
//CHECK-NEXT:   %29 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %30 = bitcast i32* %29 to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %6, [0 x i256]* %0, i256* %10, i256* %11, i256* %12, i256* %16, i256* %20, [0 x i256]* %23, i256* %25, [0 x i256]* %28, i256* %30)
//CHECK-NEXT:   %31 = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %32 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %33 = load [0 x i256]*, [0 x i256]** %32, align 8
//CHECK-NEXT:   %34 = getelementptr [0 x i256], [0 x i256]* %33, i32 0
//CHECK-NEXT:   %35 = getelementptr [0 x i256], [0 x i256]* %34, i32 0, i256 1
//CHECK-NEXT:   %36 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   %37 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %38 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %39 = load [0 x i256]*, [0 x i256]** %38, align 8
//CHECK-NEXT:   %40 = getelementptr [0 x i256], [0 x i256]* %39, i32 0
//CHECK-NEXT:   %41 = getelementptr [0 x i256], [0 x i256]* %40, i32 0, i256 0
//CHECK-NEXT:   %42 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %43 = load [0 x i256]*, [0 x i256]** %42, align 8
//CHECK-NEXT:   %44 = getelementptr [0 x i256], [0 x i256]* %43, i32 0
//CHECK-NEXT:   %45 = getelementptr [0 x i256], [0 x i256]* %44, i32 0, i256 0
//CHECK-NEXT:   %46 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %47 = load [0 x i256]*, [0 x i256]** %46, align 8
//CHECK-NEXT:   %48 = getelementptr [0 x i256], [0 x i256]* %47, i32 0
//CHECK-NEXT:   %49 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %50 = bitcast i32* %49 to i256*
//CHECK-NEXT:   %51 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %52 = load [0 x i256]*, [0 x i256]** %51, align 8
//CHECK-NEXT:   %53 = getelementptr [0 x i256], [0 x i256]* %52, i32 0
//CHECK-NEXT:   %54 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %55 = bitcast i32* %54 to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %31, [0 x i256]* %0, i256* %35, i256* %36, i256* %37, i256* %41, i256* %45, [0 x i256]* %48, i256* %50, [0 x i256]* %53, i256* %55)
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
