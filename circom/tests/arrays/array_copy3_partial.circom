pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// Parital vector copy version of `array_copy3_loop.circom` test. The outer dimension is traversed
//  explicitly but the inner dimension is treated as a vector copy. Output is identical.
template Array3(n) {
    signal input inp[n][n];
    signal output out[n][n];

    for (var i = 0; i < n; i++) {
        out[i] <== inp[i];
    }
}

component main = Array3(5);

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals, i256* %sig_0, i256* %sig_1){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9]+]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr i256, i256* %sig_0, i32 0
//CHECK-NEXT:   %1 = getelementptr i256, i256* %sig_1, i32 0
//CHECK-NEXT:   %copy_src_0 = getelementptr i256, i256* %1, i32 0
//CHECK-NEXT:   %copy_dst_0 = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %copy_val_0 = load i256, i256* %copy_src_0, align 4
//CHECK-NEXT:   store i256 %copy_val_0, i256* %copy_dst_0, align 4
//CHECK-NEXT:   %copy_val_01 = load i256, i256* %copy_src_0, align 4
//CHECK-NEXT:   %2 = load i256, i256* %copy_dst_0, align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_01, i256 %2, i1* %constraint)
//CHECK-NEXT:   %copy_src_1 = getelementptr i256, i256* %1, i32 1
//CHECK-NEXT:   %copy_dst_1 = getelementptr i256, i256* %0, i32 1
//CHECK-NEXT:   %copy_val_1 = load i256, i256* %copy_src_1, align 4
//CHECK-NEXT:   store i256 %copy_val_1, i256* %copy_dst_1, align 4
//CHECK-NEXT:   %copy_val_12 = load i256, i256* %copy_src_1, align 4
//CHECK-NEXT:   %3 = load i256, i256* %copy_dst_1, align 4
//CHECK-NEXT:   %constraint3 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_12, i256 %3, i1* %constraint3)
//CHECK-NEXT:   %copy_src_2 = getelementptr i256, i256* %1, i32 2
//CHECK-NEXT:   %copy_dst_2 = getelementptr i256, i256* %0, i32 2
//CHECK-NEXT:   %copy_val_2 = load i256, i256* %copy_src_2, align 4
//CHECK-NEXT:   store i256 %copy_val_2, i256* %copy_dst_2, align 4
//CHECK-NEXT:   %copy_val_24 = load i256, i256* %copy_src_2, align 4
//CHECK-NEXT:   %4 = load i256, i256* %copy_dst_2, align 4
//CHECK-NEXT:   %constraint5 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_24, i256 %4, i1* %constraint5)
//CHECK-NEXT:   %copy_src_3 = getelementptr i256, i256* %1, i32 3
//CHECK-NEXT:   %copy_dst_3 = getelementptr i256, i256* %0, i32 3
//CHECK-NEXT:   %copy_val_3 = load i256, i256* %copy_src_3, align 4
//CHECK-NEXT:   store i256 %copy_val_3, i256* %copy_dst_3, align 4
//CHECK-NEXT:   %copy_val_36 = load i256, i256* %copy_src_3, align 4
//CHECK-NEXT:   %5 = load i256, i256* %copy_dst_3, align 4
//CHECK-NEXT:   %constraint7 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_36, i256 %5, i1* %constraint7)
//CHECK-NEXT:   %copy_src_4 = getelementptr i256, i256* %1, i32 4
//CHECK-NEXT:   %copy_dst_4 = getelementptr i256, i256* %0, i32 4
//CHECK-NEXT:   %copy_val_4 = load i256, i256* %copy_src_4, align 4
//CHECK-NEXT:   store i256 %copy_val_4, i256* %copy_dst_4, align 4
//CHECK-NEXT:   %copy_val_48 = load i256, i256* %copy_src_4, align 4
//CHECK-NEXT:   %6 = load i256, i256* %copy_dst_4, align 4
//CHECK-NEXT:   %constraint9 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_48, i256 %6, i1* %constraint9)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %7 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %9 = load i256, i256* %8, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %9, i256 1)
//CHECK-NEXT:   store i256 %call.fr_add, i256* %7, align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @Array3_0_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9a-zA-Z_\.]+]]){{.*}} {
//CHECK:      unrolled_loop3:
//CHECK-NEXT:   %3 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 25
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %3, [0 x i256]* %0, i256* %4, i256* %5)
//CHECK-NEXT:   %6 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %7 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 5
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 30
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %6, [0 x i256]* %0, i256* %7, i256* %8)
//CHECK-NEXT:   %9 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %10 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 10
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 35
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %9, [0 x i256]* %0, i256* %10, i256* %11)
//CHECK-NEXT:   %12 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %13 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 15
//CHECK-NEXT:   %14 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 40
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %12, [0 x i256]* %0, i256* %13, i256* %14)
//CHECK-NEXT:   %15 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %16 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 20
//CHECK-NEXT:   %17 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 45
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %15, [0 x i256]* %0, i256* %16, i256* %17)
//CHECK-NEXT:   br label %prologue
