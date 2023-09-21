pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template IsZero() {
    signal input in;        // subcmp signal 1
    signal output out;      // subcmp signal 0

    signal inv;

    inv <-- in != 0 ? 1 / in : 0;

    out <== -in * inv + 1;
    in * out === 0;
}

// Simple circuit that returns what signals are equal to 0
template SubCmps1(n) {
    signal input ins[n];
    signal output outs[n];

    component zeros[n];
    var i;
    for (i = 0; i < n; i++) {
        zeros[i] = IsZero();
        zeros[i].in <== ins[i];
        outs[i] <== zeros[i].out;
    }
}

component main = SubCmps1(3);

// %0 (i.e. signal arena) = [ outs[0], outs[1], outs[2], ins[0], ins[1], ins[2] ]
// %lvars =  [ n, i ]
// %subcmps = [ IsZero[0]{signals=[out,in,inv]}, IsZero[1]{SAME} ]
//
//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %[[X1:subfix_[0-9]+]], i256* %[[X2:fix_[0-9]+]], i256* %[[X3:fix_[0-9]+]], i256* %[[X4:subfix_[0-9]+]],
//CHECK-SAME: [0 x i256]* %[[X5:sub_[0-9]+]], i256* %[[X6:subc_[0-9]+]], [0 x i256]* %[[X7:sub_[0-9]+]], i256* %[[X8:subc_[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr i256, i256* %[[X2]], i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr i256, i256* %[[X1]], i32 0
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %1, i256 %3, i1* %constraint)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %[[X5]], i32 0
//CHECK-NEXT:   call void @IsZero_0_run([0 x i256]* %[[X5]])
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %5 = getelementptr i256, i256* %[[X4]], i32 0
//CHECK-NEXT:   %6 = load i256, i256* %5, align 4
//CHECK-NEXT:   %7 = getelementptr i256, i256* %[[X3]], i32 0
//CHECK-NEXT:   store i256 %6, i256* %7, align 4
//CHECK-NEXT:   %8 = load i256, i256* %7, align 4
//CHECK-NEXT:   %constraint1 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %6, i256 %8, i1* %constraint1)
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %10 = load i256, i256* %9, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %10, i256 1)
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 %call.fr_add, i256* %11, align 4
//CHECK-NEXT:   br label %return5
//CHECK-EMPTY: 
//CHECK-NEXT: return5:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @SubCmps1_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK:      unrolled_loop5:
//CHECK-NEXT:   %7 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %8 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %9 = load [0 x i256]*, [0 x i256]** %8, align 8
//CHECK-NEXT:   %10 = getelementptr [0 x i256], [0 x i256]* %9, i32 0
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %10, i32 0, i256 1
//CHECK-NEXT:   %12 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   %13 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   %14 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %15 = load [0 x i256]*, [0 x i256]** %14, align 8
//CHECK-NEXT:   %16 = getelementptr [0 x i256], [0 x i256]* %15, i32 0
//CHECK-NEXT:   %17 = getelementptr [0 x i256], [0 x i256]* %16, i32 0, i256 0
//CHECK-NEXT:   %18 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %19 = load [0 x i256]*, [0 x i256]** %18, align 8
//CHECK-NEXT:   %20 = getelementptr [0 x i256], [0 x i256]* %19, i32 0
//CHECK-NEXT:   %21 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %22 = bitcast i32* %21 to i256*
//CHECK-NEXT:   %23 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %24 = load [0 x i256]*, [0 x i256]** %23, align 8
//CHECK-NEXT:   %25 = getelementptr [0 x i256], [0 x i256]* %24, i32 0
//CHECK-NEXT:   %26 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %27 = bitcast i32* %26 to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID]]([0 x i256]* %7, [0 x i256]* %0, i256* %11, i256* %12, i256* %13, i256* %17, [0 x i256]* %20, i256* %22, [0 x i256]* %25, i256* %27)
//CHECK-NEXT:   %28 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %29 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %30 = load [0 x i256]*, [0 x i256]** %29, align 8
//CHECK-NEXT:   %31 = getelementptr [0 x i256], [0 x i256]* %30, i32 0
//CHECK-NEXT:   %32 = getelementptr [0 x i256], [0 x i256]* %31, i32 0, i256 1
//CHECK-NEXT:   %33 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 4
//CHECK-NEXT:   %34 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %35 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %36 = load [0 x i256]*, [0 x i256]** %35, align 8
//CHECK-NEXT:   %37 = getelementptr [0 x i256], [0 x i256]* %36, i32 0
//CHECK-NEXT:   %38 = getelementptr [0 x i256], [0 x i256]* %37, i32 0, i256 0
//CHECK-NEXT:   %39 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %40 = load [0 x i256]*, [0 x i256]** %39, align 8
//CHECK-NEXT:   %41 = getelementptr [0 x i256], [0 x i256]* %40, i32 0
//CHECK-NEXT:   %42 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %43 = bitcast i32* %42 to i256*
//CHECK-NEXT:   %44 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %45 = load [0 x i256]*, [0 x i256]** %44, align 8
//CHECK-NEXT:   %46 = getelementptr [0 x i256], [0 x i256]* %45, i32 0
//CHECK-NEXT:   %47 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %48 = bitcast i32* %47 to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID]]([0 x i256]* %28, [0 x i256]* %0, i256* %32, i256* %33, i256* %34, i256* %38, [0 x i256]* %41, i256* %43, [0 x i256]* %46, i256* %48)
//CHECK-NEXT:   %49 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %50 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %51 = load [0 x i256]*, [0 x i256]** %50, align 8
//CHECK-NEXT:   %52 = getelementptr [0 x i256], [0 x i256]* %51, i32 0
//CHECK-NEXT:   %53 = getelementptr [0 x i256], [0 x i256]* %52, i32 0, i256 1
//CHECK-NEXT:   %54 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 5
//CHECK-NEXT:   %55 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   %56 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %57 = load [0 x i256]*, [0 x i256]** %56, align 8
//CHECK-NEXT:   %58 = getelementptr [0 x i256], [0 x i256]* %57, i32 0
//CHECK-NEXT:   %59 = getelementptr [0 x i256], [0 x i256]* %58, i32 0, i256 0
//CHECK-NEXT:   %60 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %61 = load [0 x i256]*, [0 x i256]** %60, align 8
//CHECK-NEXT:   %62 = getelementptr [0 x i256], [0 x i256]* %61, i32 0
//CHECK-NEXT:   %63 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 1
//CHECK-NEXT:   %64 = bitcast i32* %63 to i256*
//CHECK-NEXT:   %65 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %66 = load [0 x i256]*, [0 x i256]** %65, align 8
//CHECK-NEXT:   %67 = getelementptr [0 x i256], [0 x i256]* %66, i32 0
//CHECK-NEXT:   %68 = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 1
//CHECK-NEXT:   %69 = bitcast i32* %68 to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID]]([0 x i256]* %49, [0 x i256]* %0, i256* %53, i256* %54, i256* %55, i256* %59, [0 x i256]* %62, i256* %64, [0 x i256]* %67, i256* %69)
//CHECK-NEXT:   br label %prologue
