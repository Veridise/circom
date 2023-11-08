pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template Sum(n) {
    signal input inp[n];
    signal output outp;

    var s = 0;

    for (var i = 0; i < n; i++) {
        s += inp[i];
    }

    outp <== s;
}

template SubCmps3() {
    signal input inp[4];
    signal output outp;

    component s = Sum(4);

    for (var i = 0; i < 4; i++) {
        s.inp[i] <== inp[i];
        if (i == 3) {
            outp <== s.outp;
        }
    }
}

component main = SubCmps3();

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9]+]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr i256, i256* %fix_[[X1]], i32 0
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %1, i256 %3)
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 %call.fr_add, i256* %4, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %6 = load i256, i256* %5, align 4
//CHECK-NEXT:   %call.fr_add1 = call i256 @fr_add(i256 %6, i256 1)
//CHECK-NEXT:   %7 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 %call.fr_add1, i256* %7, align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+\.F\.F}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %subfix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]], i256* %subfix_[[X3:[0-9]+]], [0 x i256]* %sub_[[X3]], i256* %subc_[[X3]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2:[0-9]+\.F\.F]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr i256, i256* %fix_[[X2]], i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr i256, i256* %subfix_[[X1]], i32 0
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %1, i256 %3, i1* %constraint)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %4 = load i256, i256* %subc_[[X3]], align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %4, i256 1)
//CHECK-NEXT:   %5 = getelementptr i256, i256* %subc_[[X3]], i32 0
//CHECK-NEXT:   store i256 %call.fr_sub, i256* %5, align 4
//CHECK-NEXT:   br label %fold_false3
//CHECK-EMPTY: 
//CHECK-NEXT: fold_false3:
//CHECK-NEXT:   br label %fold_false4
//CHECK-EMPTY: 
//CHECK-NEXT: fold_false4:
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   %7 = load i256, i256* %6, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %7, i256 1)
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 %call.fr_add, i256* %8, align 4
//CHECK-NEXT:   br label %return6
//CHECK-EMPTY: 
//CHECK-NEXT: return6:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+\.T\.T}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %subfix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]], i256* %subfix_[[X3:[0-9]+]], [0 x i256]* %sub_[[X3]], i256* %subc_[[X3]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_3:[0-9]+\.T\.T]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr i256, i256* %fix_[[X2]], i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr i256, i256* %subfix_[[X1]], i32 0
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %1, i256 %3, i1* %constraint)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %4 = load i256, i256* %subc_[[X3]], align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %4, i256 1)
//CHECK-NEXT:   %5 = getelementptr i256, i256* %subc_[[X3]], i32 0
//CHECK-NEXT:   store i256 %call.fr_sub, i256* %5, align 4
//CHECK-NEXT:   br label %fold_true3
//CHECK-EMPTY: 
//CHECK-NEXT: fold_true3:
//CHECK-NEXT:   call void @Sum_{{[0-9]+}}_run([0 x i256]* %sub_[[X3]])
//CHECK-NEXT:   br label %fold_true4
//CHECK-EMPTY: 
//CHECK-NEXT: fold_true4:
//CHECK-NEXT:   %6 = getelementptr i256, i256* %subfix_[[X3]], i32 0
//CHECK-NEXT:   %7 = load i256, i256* %6, align 4
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 0
//CHECK-NEXT:   store i256 %7, i256* %8, align 4
//CHECK-NEXT:   %9 = load i256, i256* %8, align 4
//CHECK-NEXT:   %constraint1 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %7, i256 %9, i1* %constraint1)
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %10 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   %11 = load i256, i256* %10, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %11, i256 1)
//CHECK-NEXT:   %12 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 %call.fr_add, i256* %12, align 4
//CHECK-NEXT:   br label %return6
//CHECK-EMPTY: 
//CHECK-NEXT: return6:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @Sum_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [3 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 4, i256* %1, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %2 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %2, align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %3 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 0, i256* %3, align 4
//CHECK-NEXT:   br label %unrolled_loop4
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop4:
//CHECK-NEXT:   %4 = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %4, [0 x i256]* %0, i256* %5)
//CHECK-NEXT:   %6 = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %7 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %6, [0 x i256]* %0, i256* %7)
//CHECK-NEXT:   %8 = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %8, [0 x i256]* %0, i256* %9)
//CHECK-NEXT:   %10 = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 4
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %10, [0 x i256]* %0, i256* %11)
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %12 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %13 = load i256, i256* %12, align 4
//CHECK-NEXT:   %14 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %13, i256* %14, align 4
//CHECK-NEXT:   %15 = load i256, i256* %14, align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %13, i256 %15, i1* %constraint)
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @SubCmps3_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [1 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [1 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %create_cmp1
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp1:
//CHECK-NEXT:   %1 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0
//CHECK-NEXT:   call void @Sum_0_build({ [0 x i256]*, i32 }* %1)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %2 = getelementptr [1 x i256], [1 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 0, i256* %2, align 4
//CHECK-NEXT:   br label %unrolled_loop3
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop3:
//CHECK-NEXT:  %3 = bitcast [1 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:  %4 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:  %5 = load [0 x i256]*, [0 x i256]** %4, align 8
//CHECK-NEXT:  %6 = getelementptr [0 x i256], [0 x i256]* %5, i32 0
//CHECK-NEXT:  %7 = getelementptr [0 x i256], [0 x i256]* %6, i32 0, i256 1
//CHECK-NEXT:  %8 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:  %9 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:  %10 = load [0 x i256]*, [0 x i256]** %9, align 8
//CHECK-NEXT:  %11 = getelementptr [0 x i256], [0 x i256]* %10, i32 0
//CHECK-NEXT:  %12 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:  %13 = bitcast i32* %12 to i256*
//CHECK-NEXT:  call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %3, [0 x i256]* %0, i256* %7, i256* %8, i256* null, [0 x i256]* %11, i256* %13)
//CHECK-NEXT:  %14 = bitcast [1 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:  %15 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:  %16 = load [0 x i256]*, [0 x i256]** %15, align 8
//CHECK-NEXT:  %17 = getelementptr [0 x i256], [0 x i256]* %16, i32 0
//CHECK-NEXT:  %18 = getelementptr [0 x i256], [0 x i256]* %17, i32 0, i256 2
//CHECK-NEXT:  %19 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:  %20 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:  %21 = load [0 x i256]*, [0 x i256]** %20, align 8
//CHECK-NEXT:  %22 = getelementptr [0 x i256], [0 x i256]* %21, i32 0
//CHECK-NEXT:  %23 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:  %24 = bitcast i32* %23 to i256*
//CHECK-NEXT:  call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %14, [0 x i256]* %0, i256* %18, i256* %19, i256* null, [0 x i256]* %22, i256* %24)
//CHECK-NEXT:  %25 = bitcast [1 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:  %26 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:  %27 = load [0 x i256]*, [0 x i256]** %26, align 8
//CHECK-NEXT:  %28 = getelementptr [0 x i256], [0 x i256]* %27, i32 0
//CHECK-NEXT:  %29 = getelementptr [0 x i256], [0 x i256]* %28, i32 0, i256 3
//CHECK-NEXT:  %30 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:  %31 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:  %32 = load [0 x i256]*, [0 x i256]** %31, align 8
//CHECK-NEXT:  %33 = getelementptr [0 x i256], [0 x i256]* %32, i32 0
//CHECK-NEXT:  %34 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:  %35 = bitcast i32* %34 to i256*
//CHECK-NEXT:  call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %25, [0 x i256]* %0, i256* %29, i256* %30, i256* null, [0 x i256]* %33, i256* %35)
//CHECK-NEXT:  %36 = bitcast [1 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:  %37 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:  %38 = load [0 x i256]*, [0 x i256]** %37, align 8
//CHECK-NEXT:  %39 = getelementptr [0 x i256], [0 x i256]* %38, i32 0
//CHECK-NEXT:  %40 = getelementptr [0 x i256], [0 x i256]* %39, i32 0, i256 4
//CHECK-NEXT:  %41 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 4
//CHECK-NEXT:  %42 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:  %43 = load [0 x i256]*, [0 x i256]** %42, align 8
//CHECK-NEXT:  %44 = getelementptr [0 x i256], [0 x i256]* %43, i32 0
//CHECK-NEXT:  %45 = getelementptr [0 x i256], [0 x i256]* %44, i32 0, i256 0
//CHECK-NEXT:  %46 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:  %47 = load [0 x i256]*, [0 x i256]** %46, align 8
//CHECK-NEXT:  %48 = getelementptr [0 x i256], [0 x i256]* %47, i32 0
//CHECK-NEXT:  %49 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:  %50 = bitcast i32* %49 to i256*
//CHECK-NEXT:  call void @..generated..loop.body.[[$F_ID_3]]([0 x i256]* %36, [0 x i256]* %0, i256* %40, i256* %41, i256* %45, [0 x i256]* %48, i256* %50)
//CHECK-NEXT:  br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
