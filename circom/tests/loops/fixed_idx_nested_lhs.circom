pragma circom 2.0.0;

// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template FixIdxNested() {
    var arr[9] = [8, 7, 6, 5, 4, 3, 2, 1, 0];
    signal out[9];
    for (var i = 0; i < 9; i++) {
        out[arr[i]] <-- arr[i];
    }
}

component main = FixIdxNested();

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %fix_0, i256* %fix_1){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr i256, i256* %fix_1, i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr i256, i256* %fix_0, i32 0
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 9
//CHECK-NEXT:   %4 = load i256, i256* %3, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %4, i256 1)
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 9
//CHECK-NEXT:   store i256 %call.fr_add, i256* %5, align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }

//CHECK-LABEL: define{{.*}} void @FixIdxNested_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [10 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY:
//CHECK:      unrolled_loop11:
//CHECK-NEXT:   %11 = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %12 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 8
//CHECK-NEXT:   %13 = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %14 = getelementptr [0 x i256], [0 x i256]* %13, i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %11, [0 x i256]* %0, i256* %12, i256* %14)
//CHECK-NEXT:   %15 = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %16 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 7
//CHECK-NEXT:   %17 = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %18 = getelementptr [0 x i256], [0 x i256]* %17, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %15, [0 x i256]* %0, i256* %16, i256* %18)
//CHECK-NEXT:   %19 = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %20 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 6
//CHECK-NEXT:   %21 = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %22 = getelementptr [0 x i256], [0 x i256]* %21, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %19, [0 x i256]* %0, i256* %20, i256* %22)
//CHECK-NEXT:   %23 = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %24 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 5
//CHECK-NEXT:   %25 = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %26 = getelementptr [0 x i256], [0 x i256]* %25, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %23, [0 x i256]* %0, i256* %24, i256* %26)
//CHECK-NEXT:   %27 = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %28 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 4
//CHECK-NEXT:   %29 = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %30 = getelementptr [0 x i256], [0 x i256]* %29, i32 0, i256 4
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %27, [0 x i256]* %0, i256* %28, i256* %30)
//CHECK-NEXT:   %31 = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %32 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   %33 = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %34 = getelementptr [0 x i256], [0 x i256]* %33, i32 0, i256 5
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %31, [0 x i256]* %0, i256* %32, i256* %34)
//CHECK-NEXT:   %35 = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %36 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   %37 = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %38 = getelementptr [0 x i256], [0 x i256]* %37, i32 0, i256 6
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %35, [0 x i256]* %0, i256* %36, i256* %38)
//CHECK-NEXT:   %39 = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %40 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %41 = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %42 = getelementptr [0 x i256], [0 x i256]* %41, i32 0, i256 7
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %39, [0 x i256]* %0, i256* %40, i256* %42)
//CHECK-NEXT:   %43 = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %44 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   %45 = bitcast [10 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %46 = getelementptr [0 x i256], [0 x i256]* %45, i32 0, i256 8
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %43, [0 x i256]* %0, i256* %44, i256* %46)
//CHECK-NEXT:   br label %prologue
