pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// Vector copy version of `array_copy3_loop.circom` test. Output is very similar except the
//  vector version comes through the circom front-end as a flattened array which mean lvar
//  indexing is slightly different here. There is only one loop iteration variable instead
//  of two and the additional statements for updating index variables are not necessary.
template Array3(n) {
    signal input inp[n][n];
    signal output out[n][n];

    out <== inp;
}

component main = Array3(5);

//CHECK-LABEL: define{{.*}} void @Array3_0_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9a-zA-Z_\.]+]]){{.*}} {
//CHECK:      store2:
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 25
//CHECK-NEXT:   %copy_src_0 = getelementptr i256, i256* %3, i32 0
//CHECK-NEXT:   %copy_dst_0 = getelementptr i256, i256* %2, i32 0
//CHECK-NEXT:   %copy_val_0 = load i256, i256* %copy_src_0, align 4
//CHECK-NEXT:   store i256 %copy_val_0, i256* %copy_dst_0, align 4
//CHECK-NEXT:   %copy_val_01 = load i256, i256* %copy_src_0, align 4
//CHECK-NEXT:   %4 = load i256, i256* %copy_dst_0, align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_01, i256 %4, i1* %constraint)
//CHECK-NEXT:   %copy_src_1 = getelementptr i256, i256* %3, i32 1
//CHECK-NEXT:   %copy_dst_1 = getelementptr i256, i256* %2, i32 1
//CHECK-NEXT:   %copy_val_1 = load i256, i256* %copy_src_1, align 4
//CHECK-NEXT:   store i256 %copy_val_1, i256* %copy_dst_1, align 4
//CHECK-NEXT:   %copy_val_12 = load i256, i256* %copy_src_1, align 4
//CHECK-NEXT:   %5 = load i256, i256* %copy_dst_1, align 4
//CHECK-NEXT:   %constraint3 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_12, i256 %5, i1* %constraint3)
//CHECK-NEXT:   %copy_src_2 = getelementptr i256, i256* %3, i32 2
//CHECK-NEXT:   %copy_dst_2 = getelementptr i256, i256* %2, i32 2
//CHECK-NEXT:   %copy_val_2 = load i256, i256* %copy_src_2, align 4
//CHECK-NEXT:   store i256 %copy_val_2, i256* %copy_dst_2, align 4
//CHECK-NEXT:   %copy_val_24 = load i256, i256* %copy_src_2, align 4
//CHECK-NEXT:   %6 = load i256, i256* %copy_dst_2, align 4
//CHECK-NEXT:   %constraint5 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_24, i256 %6, i1* %constraint5)
//CHECK-NEXT:   %copy_src_3 = getelementptr i256, i256* %3, i32 3
//CHECK-NEXT:   %copy_dst_3 = getelementptr i256, i256* %2, i32 3
//CHECK-NEXT:   %copy_val_3 = load i256, i256* %copy_src_3, align 4
//CHECK-NEXT:   store i256 %copy_val_3, i256* %copy_dst_3, align 4
//CHECK-NEXT:   %copy_val_36 = load i256, i256* %copy_src_3, align 4
//CHECK-NEXT:   %7 = load i256, i256* %copy_dst_3, align 4
//CHECK-NEXT:   %constraint7 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_36, i256 %7, i1* %constraint7)
//CHECK-NEXT:   %copy_src_4 = getelementptr i256, i256* %3, i32 4
//CHECK-NEXT:   %copy_dst_4 = getelementptr i256, i256* %2, i32 4
//CHECK-NEXT:   %copy_val_4 = load i256, i256* %copy_src_4, align 4
//CHECK-NEXT:   store i256 %copy_val_4, i256* %copy_dst_4, align 4
//CHECK-NEXT:   %copy_val_48 = load i256, i256* %copy_src_4, align 4
//CHECK-NEXT:   %8 = load i256, i256* %copy_dst_4, align 4
//CHECK-NEXT:   %constraint9 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_48, i256 %8, i1* %constraint9)
//CHECK-NEXT:   %copy_src_5 = getelementptr i256, i256* %3, i32 5
//CHECK-NEXT:   %copy_dst_5 = getelementptr i256, i256* %2, i32 5
//CHECK-NEXT:   %copy_val_5 = load i256, i256* %copy_src_5, align 4
//CHECK-NEXT:   store i256 %copy_val_5, i256* %copy_dst_5, align 4
//CHECK-NEXT:   %copy_val_510 = load i256, i256* %copy_src_5, align 4
//CHECK-NEXT:   %9 = load i256, i256* %copy_dst_5, align 4
//CHECK-NEXT:   %constraint11 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_510, i256 %9, i1* %constraint11)
//CHECK-NEXT:   %copy_src_6 = getelementptr i256, i256* %3, i32 6
//CHECK-NEXT:   %copy_dst_6 = getelementptr i256, i256* %2, i32 6
//CHECK-NEXT:   %copy_val_6 = load i256, i256* %copy_src_6, align 4
//CHECK-NEXT:   store i256 %copy_val_6, i256* %copy_dst_6, align 4
//CHECK-NEXT:   %copy_val_612 = load i256, i256* %copy_src_6, align 4
//CHECK-NEXT:   %10 = load i256, i256* %copy_dst_6, align 4
//CHECK-NEXT:   %constraint13 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_612, i256 %10, i1* %constraint13)
//CHECK-NEXT:   %copy_src_7 = getelementptr i256, i256* %3, i32 7
//CHECK-NEXT:   %copy_dst_7 = getelementptr i256, i256* %2, i32 7
//CHECK-NEXT:   %copy_val_7 = load i256, i256* %copy_src_7, align 4
//CHECK-NEXT:   store i256 %copy_val_7, i256* %copy_dst_7, align 4
//CHECK-NEXT:   %copy_val_714 = load i256, i256* %copy_src_7, align 4
//CHECK-NEXT:   %11 = load i256, i256* %copy_dst_7, align 4
//CHECK-NEXT:   %constraint15 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_714, i256 %11, i1* %constraint15)
//CHECK-NEXT:   %copy_src_8 = getelementptr i256, i256* %3, i32 8
//CHECK-NEXT:   %copy_dst_8 = getelementptr i256, i256* %2, i32 8
//CHECK-NEXT:   %copy_val_8 = load i256, i256* %copy_src_8, align 4
//CHECK-NEXT:   store i256 %copy_val_8, i256* %copy_dst_8, align 4
//CHECK-NEXT:   %copy_val_816 = load i256, i256* %copy_src_8, align 4
//CHECK-NEXT:   %12 = load i256, i256* %copy_dst_8, align 4
//CHECK-NEXT:   %constraint17 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_816, i256 %12, i1* %constraint17)
//CHECK-NEXT:   %copy_src_9 = getelementptr i256, i256* %3, i32 9
//CHECK-NEXT:   %copy_dst_9 = getelementptr i256, i256* %2, i32 9
//CHECK-NEXT:   %copy_val_9 = load i256, i256* %copy_src_9, align 4
//CHECK-NEXT:   store i256 %copy_val_9, i256* %copy_dst_9, align 4
//CHECK-NEXT:   %copy_val_918 = load i256, i256* %copy_src_9, align 4
//CHECK-NEXT:   %13 = load i256, i256* %copy_dst_9, align 4
//CHECK-NEXT:   %constraint19 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_918, i256 %13, i1* %constraint19)
//CHECK-NEXT:   %copy_src_10 = getelementptr i256, i256* %3, i32 10
//CHECK-NEXT:   %copy_dst_10 = getelementptr i256, i256* %2, i32 10
//CHECK-NEXT:   %copy_val_10 = load i256, i256* %copy_src_10, align 4
//CHECK-NEXT:   store i256 %copy_val_10, i256* %copy_dst_10, align 4
//CHECK-NEXT:   %copy_val_1020 = load i256, i256* %copy_src_10, align 4
//CHECK-NEXT:   %14 = load i256, i256* %copy_dst_10, align 4
//CHECK-NEXT:   %constraint21 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_1020, i256 %14, i1* %constraint21)
//CHECK-NEXT:   %copy_src_11 = getelementptr i256, i256* %3, i32 11
//CHECK-NEXT:   %copy_dst_11 = getelementptr i256, i256* %2, i32 11
//CHECK-NEXT:   %copy_val_11 = load i256, i256* %copy_src_11, align 4
//CHECK-NEXT:   store i256 %copy_val_11, i256* %copy_dst_11, align 4
//CHECK-NEXT:   %copy_val_1122 = load i256, i256* %copy_src_11, align 4
//CHECK-NEXT:   %15 = load i256, i256* %copy_dst_11, align 4
//CHECK-NEXT:   %constraint23 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_1122, i256 %15, i1* %constraint23)
//CHECK-NEXT:   %copy_src_12 = getelementptr i256, i256* %3, i32 12
//CHECK-NEXT:   %copy_dst_12 = getelementptr i256, i256* %2, i32 12
//CHECK-NEXT:   %copy_val_1224 = load i256, i256* %copy_src_12, align 4
//CHECK-NEXT:   store i256 %copy_val_1224, i256* %copy_dst_12, align 4
//CHECK-NEXT:   %copy_val_1225 = load i256, i256* %copy_src_12, align 4
//CHECK-NEXT:   %16 = load i256, i256* %copy_dst_12, align 4
//CHECK-NEXT:   %constraint26 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_1225, i256 %16, i1* %constraint26)
//CHECK-NEXT:   %copy_src_13 = getelementptr i256, i256* %3, i32 13
//CHECK-NEXT:   %copy_dst_13 = getelementptr i256, i256* %2, i32 13
//CHECK-NEXT:   %copy_val_13 = load i256, i256* %copy_src_13, align 4
//CHECK-NEXT:   store i256 %copy_val_13, i256* %copy_dst_13, align 4
//CHECK-NEXT:   %copy_val_1327 = load i256, i256* %copy_src_13, align 4
//CHECK-NEXT:   %17 = load i256, i256* %copy_dst_13, align 4
//CHECK-NEXT:   %constraint28 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_1327, i256 %17, i1* %constraint28)
//CHECK-NEXT:   %copy_src_14 = getelementptr i256, i256* %3, i32 14
//CHECK-NEXT:   %copy_dst_14 = getelementptr i256, i256* %2, i32 14
//CHECK-NEXT:   %copy_val_14 = load i256, i256* %copy_src_14, align 4
//CHECK-NEXT:   store i256 %copy_val_14, i256* %copy_dst_14, align 4
//CHECK-NEXT:   %copy_val_1429 = load i256, i256* %copy_src_14, align 4
//CHECK-NEXT:   %18 = load i256, i256* %copy_dst_14, align 4
//CHECK-NEXT:   %constraint30 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_1429, i256 %18, i1* %constraint30)
//CHECK-NEXT:   %copy_src_15 = getelementptr i256, i256* %3, i32 15
//CHECK-NEXT:   %copy_dst_15 = getelementptr i256, i256* %2, i32 15
//CHECK-NEXT:   %copy_val_15 = load i256, i256* %copy_src_15, align 4
//CHECK-NEXT:   store i256 %copy_val_15, i256* %copy_dst_15, align 4
//CHECK-NEXT:   %copy_val_1531 = load i256, i256* %copy_src_15, align 4
//CHECK-NEXT:   %19 = load i256, i256* %copy_dst_15, align 4
//CHECK-NEXT:   %constraint32 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_1531, i256 %19, i1* %constraint32)
//CHECK-NEXT:   %copy_src_16 = getelementptr i256, i256* %3, i32 16
//CHECK-NEXT:   %copy_dst_16 = getelementptr i256, i256* %2, i32 16
//CHECK-NEXT:   %copy_val_16 = load i256, i256* %copy_src_16, align 4
//CHECK-NEXT:   store i256 %copy_val_16, i256* %copy_dst_16, align 4
//CHECK-NEXT:   %copy_val_1633 = load i256, i256* %copy_src_16, align 4
//CHECK-NEXT:   %20 = load i256, i256* %copy_dst_16, align 4
//CHECK-NEXT:   %constraint34 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_1633, i256 %20, i1* %constraint34)
//CHECK-NEXT:   %copy_src_17 = getelementptr i256, i256* %3, i32 17
//CHECK-NEXT:   %copy_dst_17 = getelementptr i256, i256* %2, i32 17
//CHECK-NEXT:   %copy_val_17 = load i256, i256* %copy_src_17, align 4
//CHECK-NEXT:   store i256 %copy_val_17, i256* %copy_dst_17, align 4
//CHECK-NEXT:   %copy_val_1735 = load i256, i256* %copy_src_17, align 4
//CHECK-NEXT:   %21 = load i256, i256* %copy_dst_17, align 4
//CHECK-NEXT:   %constraint36 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_1735, i256 %21, i1* %constraint36)
//CHECK-NEXT:   %copy_src_18 = getelementptr i256, i256* %3, i32 18
//CHECK-NEXT:   %copy_dst_18 = getelementptr i256, i256* %2, i32 18
//CHECK-NEXT:   %copy_val_18 = load i256, i256* %copy_src_18, align 4
//CHECK-NEXT:   store i256 %copy_val_18, i256* %copy_dst_18, align 4
//CHECK-NEXT:   %copy_val_1837 = load i256, i256* %copy_src_18, align 4
//CHECK-NEXT:   %22 = load i256, i256* %copy_dst_18, align 4
//CHECK-NEXT:   %constraint38 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_1837, i256 %22, i1* %constraint38)
//CHECK-NEXT:   %copy_src_19 = getelementptr i256, i256* %3, i32 19
//CHECK-NEXT:   %copy_dst_19 = getelementptr i256, i256* %2, i32 19
//CHECK-NEXT:   %copy_val_19 = load i256, i256* %copy_src_19, align 4
//CHECK-NEXT:   store i256 %copy_val_19, i256* %copy_dst_19, align 4
//CHECK-NEXT:   %copy_val_1939 = load i256, i256* %copy_src_19, align 4
//CHECK-NEXT:   %23 = load i256, i256* %copy_dst_19, align 4
//CHECK-NEXT:   %constraint40 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_1939, i256 %23, i1* %constraint40)
//CHECK-NEXT:   %copy_src_20 = getelementptr i256, i256* %3, i32 20
//CHECK-NEXT:   %copy_dst_20 = getelementptr i256, i256* %2, i32 20
//CHECK-NEXT:   %copy_val_20 = load i256, i256* %copy_src_20, align 4
//CHECK-NEXT:   store i256 %copy_val_20, i256* %copy_dst_20, align 4
//CHECK-NEXT:   %copy_val_2041 = load i256, i256* %copy_src_20, align 4
//CHECK-NEXT:   %24 = load i256, i256* %copy_dst_20, align 4
//CHECK-NEXT:   %constraint42 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_2041, i256 %24, i1* %constraint42)
//CHECK-NEXT:   %copy_src_21 = getelementptr i256, i256* %3, i32 21
//CHECK-NEXT:   %copy_dst_21 = getelementptr i256, i256* %2, i32 21
//CHECK-NEXT:   %copy_val_21 = load i256, i256* %copy_src_21, align 4
//CHECK-NEXT:   store i256 %copy_val_21, i256* %copy_dst_21, align 4
//CHECK-NEXT:   %copy_val_2143 = load i256, i256* %copy_src_21, align 4
//CHECK-NEXT:   %25 = load i256, i256* %copy_dst_21, align 4
//CHECK-NEXT:   %constraint44 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_2143, i256 %25, i1* %constraint44)
//CHECK-NEXT:   %copy_src_22 = getelementptr i256, i256* %3, i32 22
//CHECK-NEXT:   %copy_dst_22 = getelementptr i256, i256* %2, i32 22
//CHECK-NEXT:   %copy_val_22 = load i256, i256* %copy_src_22, align 4
//CHECK-NEXT:   store i256 %copy_val_22, i256* %copy_dst_22, align 4
//CHECK-NEXT:   %copy_val_2245 = load i256, i256* %copy_src_22, align 4
//CHECK-NEXT:   %26 = load i256, i256* %copy_dst_22, align 4
//CHECK-NEXT:   %constraint46 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_2245, i256 %26, i1* %constraint46)
//CHECK-NEXT:   %copy_src_23 = getelementptr i256, i256* %3, i32 23
//CHECK-NEXT:   %copy_dst_23 = getelementptr i256, i256* %2, i32 23
//CHECK-NEXT:   %copy_val_23 = load i256, i256* %copy_src_23, align 4
//CHECK-NEXT:   store i256 %copy_val_23, i256* %copy_dst_23, align 4
//CHECK-NEXT:   %copy_val_2347 = load i256, i256* %copy_src_23, align 4
//CHECK-NEXT:   %27 = load i256, i256* %copy_dst_23, align 4
//CHECK-NEXT:   %constraint48 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_2347, i256 %27, i1* %constraint48)
//CHECK-NEXT:   %copy_src_24 = getelementptr i256, i256* %3, i32 24
//CHECK-NEXT:   %copy_dst_24 = getelementptr i256, i256* %2, i32 24
//CHECK-NEXT:   %copy_val_2449 = load i256, i256* %copy_src_24, align 4
//CHECK-NEXT:   store i256 %copy_val_2449, i256* %copy_dst_24, align 4
//CHECK-NEXT:   %copy_val_2450 = load i256, i256* %copy_src_24, align 4
//CHECK-NEXT:   %28 = load i256, i256* %copy_dst_24, align 4
//CHECK-NEXT:   %constraint51 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %copy_val_2450, i256 %28, i1* %constraint51)
//CHECK-NEXT:   br label %prologue
