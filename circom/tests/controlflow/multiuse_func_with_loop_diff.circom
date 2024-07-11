pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// %0 = [ s[0], s[1], s[2], s[3], s[4], s[5], s[6], s[7], s[8], s[9], n, sum, i ]
function f(s, n) {
    var sum = 0;
    for (var i = 0; i < n; i++) {
        sum += s[i];
    }
    return sum;
}

template MultiUse() {
    signal input inp[10];
    signal output outp[3];

    outp[0] <-- f(inp, 2);
    outp[1] <-- f(inp, 5);
    outp[2] <-- f(inp, 9);
}

component main = MultiUse();

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9a-zA-Z_\.]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %var_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 11
//CHECK-NEXT:   %1 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 11
//CHECK-NEXT:   %2 = load i256, i256* %1, align 4
//CHECK-NEXT:   %3 = getelementptr i256, i256* %var_0, i32 0
//CHECK-NEXT:   %4 = load i256, i256* %3, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %2, i256 %4)
//CHECK-NEXT:   store i256 %call.fr_add, i256* %0, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 12
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 12
//CHECK-NEXT:   %7 = load i256, i256* %6, align 4
//CHECK-NEXT:   %call.fr_add1 = call i256 @fr_add(i256 %7, i256 1)
//CHECK-NEXT:   store i256 %call.fr_add1, i256* %5, align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} i256 @f_0.2(i256* %0){{.*}} {
//CHECK-NEXT: f_0.2:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr i256, i256* %0, i32 11
//CHECK-NEXT:   store i256 0, i256* %1, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %2 = getelementptr i256, i256* %0, i32 12
//CHECK-NEXT:   store i256 0, i256* %2, align 4
//CHECK-NEXT:   br label %unrolled_loop3
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop3:
//CHECK-NEXT:   %3 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %4 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %4, i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %3, [0 x i256]* null, i256* %5)
//CHECK-NEXT:   %6 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %7 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %7, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %6, [0 x i256]* null, i256* %8)
//CHECK-NEXT:   br label %return4
//CHECK-EMPTY: 
//CHECK-NEXT: return4:
//CHECK-NEXT:   %9 = getelementptr i256, i256* %0, i32 11
//CHECK-NEXT:   %10 = load i256, i256* %9, align 4
//CHECK-NEXT:   ret i256 %10
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} i256 @f_0.5(i256* %0){{.*}} {
//CHECK-NEXT: f_0.5:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr i256, i256* %0, i32 11
//CHECK-NEXT:   store i256 0, i256* %1, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %2 = getelementptr i256, i256* %0, i32 12
//CHECK-NEXT:   store i256 0, i256* %2, align 4
//CHECK-NEXT:   br label %unrolled_loop3
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop3:
//CHECK-NEXT:   %3 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %4 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %4, i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %3, [0 x i256]* null, i256* %5)
//CHECK-NEXT:   %6 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %7 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %7, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %6, [0 x i256]* null, i256* %8)
//CHECK-NEXT:   %9 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %10 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %10, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %9, [0 x i256]* null, i256* %11)
//CHECK-NEXT:   %12 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %13 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %14 = getelementptr [0 x i256], [0 x i256]* %13, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %12, [0 x i256]* null, i256* %14)
//CHECK-NEXT:   %15 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %16 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %17 = getelementptr [0 x i256], [0 x i256]* %16, i32 0, i256 4
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %15, [0 x i256]* null, i256* %17)
//CHECK-NEXT:   br label %return4
//CHECK-EMPTY: 
//CHECK-NEXT: return4:
//CHECK-NEXT:   %18 = getelementptr i256, i256* %0, i32 11
//CHECK-NEXT:   %19 = load i256, i256* %18, align 4
//CHECK-NEXT:   ret i256 %19
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} i256 @f_0.9(i256* %0){{.*}} {
//CHECK-NEXT: f_0.9:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr i256, i256* %0, i32 11
//CHECK-NEXT:   store i256 0, i256* %1, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %2 = getelementptr i256, i256* %0, i32 12
//CHECK-NEXT:   store i256 0, i256* %2, align 4
//CHECK-NEXT:   br label %unrolled_loop3
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop3:
//CHECK-NEXT:   %3 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %4 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %4, i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %3, [0 x i256]* null, i256* %5)
//CHECK-NEXT:   %6 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %7 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %7, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %6, [0 x i256]* null, i256* %8)
//CHECK-NEXT:   %9 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %10 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %10, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %9, [0 x i256]* null, i256* %11)
//CHECK-NEXT:   %12 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %13 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %14 = getelementptr [0 x i256], [0 x i256]* %13, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %12, [0 x i256]* null, i256* %14)
//CHECK-NEXT:   %15 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %16 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %17 = getelementptr [0 x i256], [0 x i256]* %16, i32 0, i256 4
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %15, [0 x i256]* null, i256* %17)
//CHECK-NEXT:   %18 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %19 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %20 = getelementptr [0 x i256], [0 x i256]* %19, i32 0, i256 5
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %18, [0 x i256]* null, i256* %20)
//CHECK-NEXT:   %21 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %22 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %23 = getelementptr [0 x i256], [0 x i256]* %22, i32 0, i256 6
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %21, [0 x i256]* null, i256* %23)
//CHECK-NEXT:   %24 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %25 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %26 = getelementptr [0 x i256], [0 x i256]* %25, i32 0, i256 7
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %24, [0 x i256]* null, i256* %26)
//CHECK-NEXT:   %27 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %28 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %29 = getelementptr [0 x i256], [0 x i256]* %28, i32 0, i256 8
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %27, [0 x i256]* null, i256* %29)
//CHECK-NEXT:   br label %return4
//CHECK-EMPTY: 
//CHECK-NEXT: return4:
//CHECK-NEXT:   %30 = getelementptr i256, i256* %0, i32 11
//CHECK-NEXT:   %31 = load i256, i256* %30, align 4
//CHECK-NEXT:   ret i256 %31
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @MultiUse_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [0 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY: 
//CHECK-NEXT: call1:
//CHECK-NEXT:   %f_0.2_arena = alloca [13 x i256], align 8
//CHECK-NEXT:   %1 = getelementptr [13 x i256], [13 x i256]* %f_0.2_arena, i32 0, i32 0
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 3
//CHECK-NEXT:   %copy_src_0 = getelementptr i256, i256* %2, i32 0
//CHECK-NEXT:   %copy_dst_0 = getelementptr i256, i256* %1, i32 0
//CHECK-NEXT:   %copy_val_0 = load i256, i256* %copy_src_0, align 4
//CHECK-NEXT:   store i256 %copy_val_0, i256* %copy_dst_0, align 4
//CHECK-NEXT:   %copy_src_1 = getelementptr i256, i256* %2, i32 1
//CHECK-NEXT:   %copy_dst_1 = getelementptr i256, i256* %1, i32 1
//CHECK-NEXT:   %copy_val_1 = load i256, i256* %copy_src_1, align 4
//CHECK-NEXT:   store i256 %copy_val_1, i256* %copy_dst_1, align 4
//CHECK-NEXT:   %copy_src_2 = getelementptr i256, i256* %2, i32 2
//CHECK-NEXT:   %copy_dst_2 = getelementptr i256, i256* %1, i32 2
//CHECK-NEXT:   %copy_val_2 = load i256, i256* %copy_src_2, align 4
//CHECK-NEXT:   store i256 %copy_val_2, i256* %copy_dst_2, align 4
//CHECK-NEXT:   %copy_src_3 = getelementptr i256, i256* %2, i32 3
//CHECK-NEXT:   %copy_dst_3 = getelementptr i256, i256* %1, i32 3
//CHECK-NEXT:   %copy_val_3 = load i256, i256* %copy_src_3, align 4
//CHECK-NEXT:   store i256 %copy_val_3, i256* %copy_dst_3, align 4
//CHECK-NEXT:   %copy_src_4 = getelementptr i256, i256* %2, i32 4
//CHECK-NEXT:   %copy_dst_4 = getelementptr i256, i256* %1, i32 4
//CHECK-NEXT:   %copy_val_4 = load i256, i256* %copy_src_4, align 4
//CHECK-NEXT:   store i256 %copy_val_4, i256* %copy_dst_4, align 4
//CHECK-NEXT:   %copy_src_5 = getelementptr i256, i256* %2, i32 5
//CHECK-NEXT:   %copy_dst_5 = getelementptr i256, i256* %1, i32 5
//CHECK-NEXT:   %copy_val_5 = load i256, i256* %copy_src_5, align 4
//CHECK-NEXT:   store i256 %copy_val_5, i256* %copy_dst_5, align 4
//CHECK-NEXT:   %copy_src_6 = getelementptr i256, i256* %2, i32 6
//CHECK-NEXT:   %copy_dst_6 = getelementptr i256, i256* %1, i32 6
//CHECK-NEXT:   %copy_val_6 = load i256, i256* %copy_src_6, align 4
//CHECK-NEXT:   store i256 %copy_val_6, i256* %copy_dst_6, align 4
//CHECK-NEXT:   %copy_src_7 = getelementptr i256, i256* %2, i32 7
//CHECK-NEXT:   %copy_dst_7 = getelementptr i256, i256* %1, i32 7
//CHECK-NEXT:   %copy_val_7 = load i256, i256* %copy_src_7, align 4
//CHECK-NEXT:   store i256 %copy_val_7, i256* %copy_dst_7, align 4
//CHECK-NEXT:   %copy_src_8 = getelementptr i256, i256* %2, i32 8
//CHECK-NEXT:   %copy_dst_8 = getelementptr i256, i256* %1, i32 8
//CHECK-NEXT:   %copy_val_8 = load i256, i256* %copy_src_8, align 4
//CHECK-NEXT:   store i256 %copy_val_8, i256* %copy_dst_8, align 4
//CHECK-NEXT:   %copy_src_9 = getelementptr i256, i256* %2, i32 9
//CHECK-NEXT:   %copy_dst_9 = getelementptr i256, i256* %1, i32 9
//CHECK-NEXT:   %copy_val_9 = load i256, i256* %copy_src_9, align 4
//CHECK-NEXT:   store i256 %copy_val_9, i256* %copy_dst_9, align 4
//CHECK-NEXT:   %3 = getelementptr [13 x i256], [13 x i256]* %f_0.2_arena, i32 0, i32 10
//CHECK-NEXT:   store i256 2, i256* %3, align 4
//CHECK-NEXT:   %4 = bitcast [13 x i256]* %f_0.2_arena to i256*
//CHECK-NEXT:   %call.f_0.2 = call i256 @f_0.2(i256* %4)
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %call.f_0.2, i256* %5, align 4
//CHECK-NEXT:   br label %call2
//CHECK-EMPTY: 
//CHECK-NEXT: call2:
//CHECK-NEXT:   %f_0.5_arena = alloca [13 x i256], align 8
//CHECK-NEXT:   %6 = getelementptr [13 x i256], [13 x i256]* %f_0.5_arena, i32 0, i32 0
//CHECK-NEXT:   %7 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 3
//CHECK-NEXT:   %copy_src_01 = getelementptr i256, i256* %7, i32 0
//CHECK-NEXT:   %copy_dst_02 = getelementptr i256, i256* %6, i32 0
//CHECK-NEXT:   %copy_val_03 = load i256, i256* %copy_src_01, align 4
//CHECK-NEXT:   store i256 %copy_val_03, i256* %copy_dst_02, align 4
//CHECK-NEXT:   %copy_src_14 = getelementptr i256, i256* %7, i32 1
//CHECK-NEXT:   %copy_dst_15 = getelementptr i256, i256* %6, i32 1
//CHECK-NEXT:   %copy_val_16 = load i256, i256* %copy_src_14, align 4
//CHECK-NEXT:   store i256 %copy_val_16, i256* %copy_dst_15, align 4
//CHECK-NEXT:   %copy_src_27 = getelementptr i256, i256* %7, i32 2
//CHECK-NEXT:   %copy_dst_28 = getelementptr i256, i256* %6, i32 2
//CHECK-NEXT:   %copy_val_29 = load i256, i256* %copy_src_27, align 4
//CHECK-NEXT:   store i256 %copy_val_29, i256* %copy_dst_28, align 4
//CHECK-NEXT:   %copy_src_310 = getelementptr i256, i256* %7, i32 3
//CHECK-NEXT:   %copy_dst_311 = getelementptr i256, i256* %6, i32 3
//CHECK-NEXT:   %copy_val_312 = load i256, i256* %copy_src_310, align 4
//CHECK-NEXT:   store i256 %copy_val_312, i256* %copy_dst_311, align 4
//CHECK-NEXT:   %copy_src_413 = getelementptr i256, i256* %7, i32 4
//CHECK-NEXT:   %copy_dst_414 = getelementptr i256, i256* %6, i32 4
//CHECK-NEXT:   %copy_val_415 = load i256, i256* %copy_src_413, align 4
//CHECK-NEXT:   store i256 %copy_val_415, i256* %copy_dst_414, align 4
//CHECK-NEXT:   %copy_src_516 = getelementptr i256, i256* %7, i32 5
//CHECK-NEXT:   %copy_dst_517 = getelementptr i256, i256* %6, i32 5
//CHECK-NEXT:   %copy_val_518 = load i256, i256* %copy_src_516, align 4
//CHECK-NEXT:   store i256 %copy_val_518, i256* %copy_dst_517, align 4
//CHECK-NEXT:   %copy_src_619 = getelementptr i256, i256* %7, i32 6
//CHECK-NEXT:   %copy_dst_620 = getelementptr i256, i256* %6, i32 6
//CHECK-NEXT:   %copy_val_621 = load i256, i256* %copy_src_619, align 4
//CHECK-NEXT:   store i256 %copy_val_621, i256* %copy_dst_620, align 4
//CHECK-NEXT:   %copy_src_722 = getelementptr i256, i256* %7, i32 7
//CHECK-NEXT:   %copy_dst_723 = getelementptr i256, i256* %6, i32 7
//CHECK-NEXT:   %copy_val_724 = load i256, i256* %copy_src_722, align 4
//CHECK-NEXT:   store i256 %copy_val_724, i256* %copy_dst_723, align 4
//CHECK-NEXT:   %copy_src_825 = getelementptr i256, i256* %7, i32 8
//CHECK-NEXT:   %copy_dst_826 = getelementptr i256, i256* %6, i32 8
//CHECK-NEXT:   %copy_val_827 = load i256, i256* %copy_src_825, align 4
//CHECK-NEXT:   store i256 %copy_val_827, i256* %copy_dst_826, align 4
//CHECK-NEXT:   %copy_src_928 = getelementptr i256, i256* %7, i32 9
//CHECK-NEXT:   %copy_dst_929 = getelementptr i256, i256* %6, i32 9
//CHECK-NEXT:   %copy_val_930 = load i256, i256* %copy_src_928, align 4
//CHECK-NEXT:   store i256 %copy_val_930, i256* %copy_dst_929, align 4
//CHECK-NEXT:   %8 = getelementptr [13 x i256], [13 x i256]* %f_0.5_arena, i32 0, i32 10
//CHECK-NEXT:   store i256 5, i256* %8, align 4
//CHECK-NEXT:   %9 = bitcast [13 x i256]* %f_0.5_arena to i256*
//CHECK-NEXT:   %call.f_0.5 = call i256 @f_0.5(i256* %9)
//CHECK-NEXT:   %10 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:   store i256 %call.f_0.5, i256* %10, align 4
//CHECK-NEXT:   br label %call3
//CHECK-EMPTY: 
//CHECK-NEXT: call3:
//CHECK-NEXT:   %f_0.9_arena = alloca [13 x i256], align 8
//CHECK-NEXT:   %11 = getelementptr [13 x i256], [13 x i256]* %f_0.9_arena, i32 0, i32 0
//CHECK-NEXT:   %12 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 3
//CHECK-NEXT:   %copy_src_031 = getelementptr i256, i256* %12, i32 0
//CHECK-NEXT:   %copy_dst_032 = getelementptr i256, i256* %11, i32 0
//CHECK-NEXT:   %copy_val_033 = load i256, i256* %copy_src_031, align 4
//CHECK-NEXT:   store i256 %copy_val_033, i256* %copy_dst_032, align 4
//CHECK-NEXT:   %copy_src_134 = getelementptr i256, i256* %12, i32 1
//CHECK-NEXT:   %copy_dst_135 = getelementptr i256, i256* %11, i32 1
//CHECK-NEXT:   %copy_val_136 = load i256, i256* %copy_src_134, align 4
//CHECK-NEXT:   store i256 %copy_val_136, i256* %copy_dst_135, align 4
//CHECK-NEXT:   %copy_src_237 = getelementptr i256, i256* %12, i32 2
//CHECK-NEXT:   %copy_dst_238 = getelementptr i256, i256* %11, i32 2
//CHECK-NEXT:   %copy_val_239 = load i256, i256* %copy_src_237, align 4
//CHECK-NEXT:   store i256 %copy_val_239, i256* %copy_dst_238, align 4
//CHECK-NEXT:   %copy_src_340 = getelementptr i256, i256* %12, i32 3
//CHECK-NEXT:   %copy_dst_341 = getelementptr i256, i256* %11, i32 3
//CHECK-NEXT:   %copy_val_342 = load i256, i256* %copy_src_340, align 4
//CHECK-NEXT:   store i256 %copy_val_342, i256* %copy_dst_341, align 4
//CHECK-NEXT:   %copy_src_443 = getelementptr i256, i256* %12, i32 4
//CHECK-NEXT:   %copy_dst_444 = getelementptr i256, i256* %11, i32 4
//CHECK-NEXT:   %copy_val_445 = load i256, i256* %copy_src_443, align 4
//CHECK-NEXT:   store i256 %copy_val_445, i256* %copy_dst_444, align 4
//CHECK-NEXT:   %copy_src_546 = getelementptr i256, i256* %12, i32 5
//CHECK-NEXT:   %copy_dst_547 = getelementptr i256, i256* %11, i32 5
//CHECK-NEXT:   %copy_val_548 = load i256, i256* %copy_src_546, align 4
//CHECK-NEXT:   store i256 %copy_val_548, i256* %copy_dst_547, align 4
//CHECK-NEXT:   %copy_src_649 = getelementptr i256, i256* %12, i32 6
//CHECK-NEXT:   %copy_dst_650 = getelementptr i256, i256* %11, i32 6
//CHECK-NEXT:   %copy_val_651 = load i256, i256* %copy_src_649, align 4
//CHECK-NEXT:   store i256 %copy_val_651, i256* %copy_dst_650, align 4
//CHECK-NEXT:   %copy_src_752 = getelementptr i256, i256* %12, i32 7
//CHECK-NEXT:   %copy_dst_753 = getelementptr i256, i256* %11, i32 7
//CHECK-NEXT:   %copy_val_754 = load i256, i256* %copy_src_752, align 4
//CHECK-NEXT:   store i256 %copy_val_754, i256* %copy_dst_753, align 4
//CHECK-NEXT:   %copy_src_855 = getelementptr i256, i256* %12, i32 8
//CHECK-NEXT:   %copy_dst_856 = getelementptr i256, i256* %11, i32 8
//CHECK-NEXT:   %copy_val_857 = load i256, i256* %copy_src_855, align 4
//CHECK-NEXT:   store i256 %copy_val_857, i256* %copy_dst_856, align 4
//CHECK-NEXT:   %copy_src_958 = getelementptr i256, i256* %12, i32 9
//CHECK-NEXT:   %copy_dst_959 = getelementptr i256, i256* %11, i32 9
//CHECK-NEXT:   %copy_val_960 = load i256, i256* %copy_src_958, align 4
//CHECK-NEXT:   store i256 %copy_val_960, i256* %copy_dst_959, align 4
//CHECK-NEXT:   %13 = getelementptr [13 x i256], [13 x i256]* %f_0.9_arena, i32 0, i32 10
//CHECK-NEXT:   store i256 9, i256* %13, align 4
//CHECK-NEXT:   %14 = bitcast [13 x i256]* %f_0.9_arena to i256*
//CHECK-NEXT:   %call.f_0.9 = call i256 @f_0.9(i256* %14)
//CHECK-NEXT:   %15 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 2
//CHECK-NEXT:   store i256 %call.f_0.9, i256* %15, align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
