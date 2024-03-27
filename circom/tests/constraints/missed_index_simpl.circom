pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// 3 signals, 0 lvars, 0 subcmps
template Mult() {
    signal input in[2];
    signal output out;
}

// 4 signals, 3 lvars, 2 subcmps
// lvars = [N, i, j]
template Good(N) {
    signal input inp[N][2];
    component c[N];

    for (var i = 0; i < N; i++) {
        c[i] = Mult();
        for (var j = 0; j < 2; j++) {
            c[i].in[j] <== inp[i][j];
        }

        c[i].out === 77;
    }
}

component main = Good(2);

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+\.F}}([0 x i256]* %lvars, [0 x i256]* %signals, 
//CHECK-SAME: i256* %subsig_[[X1:[0-9]+]], i256* %sig_[[X2:[0-9]+]], [0 x i256]* %sub_[[X1]], i256* %subc_[[X1]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9]+\.F]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr i256, i256* %sig_[[X2]], i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr i256, i256* %subsig_[[X1]], i32 0
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %1, i256 %3, i1* %constraint)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %4 = load i256, i256* %subc_[[X1]], align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %4, i256 1)
//CHECK-NEXT:   %5 = getelementptr i256, i256* %subc_[[X1]], i32 0
//CHECK-NEXT:   store i256 %call.fr_sub, i256* %5, align 4
//CHECK-NEXT:   br label %fold_false3
//CHECK-EMPTY: 
//CHECK-NEXT: fold_false3:
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %7 = load i256, i256* %6, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %7, i256 1)
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 %call.fr_add, i256* %8, align 4
//CHECK-NEXT:   br label %return5
//CHECK-EMPTY: 
//CHECK-NEXT: return5:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+\.T}}([0 x i256]* %lvars, [0 x i256]* %signals, 
//CHECK-SAME: i256* %subsig_[[X1:[0-9]+]], i256* %sig_[[X2:[0-9]+]], [0 x i256]* %sub_[[X1]], i256* %subc_[[X1]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2:[0-9]+\.T]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr i256, i256* %sig_[[X2]], i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr i256, i256* %subsig_[[X1]], i32 0
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %1, i256 %3, i1* %constraint)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %4 = load i256, i256* %subc_[[X1]], align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %4, i256 1)
//CHECK-NEXT:   %5 = getelementptr i256, i256* %subc_[[X1]], i32 0
//CHECK-NEXT:   store i256 %call.fr_sub, i256* %5, align 4
//CHECK-NEXT:   br label %fold_true3
//CHECK-EMPTY: 
//CHECK-NEXT: fold_true3:
//CHECK-NEXT:   call void @Mult_0_run([0 x i256]* %sub_[[X1]])
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %7 = load i256, i256* %6, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %7, i256 1)
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 %call.fr_add, i256* %8, align 4
//CHECK-NEXT:   br label %return5
//CHECK-EMPTY: 
//CHECK-NEXT: return5:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @Good_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
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
//CHECK-NEXT:   call void @Mult_0_build({ [0 x i256]*, i32 }* %2)
//CHECK-NEXT:   %3 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1
//CHECK-NEXT:   call void @Mult_0_build({ [0 x i256]*, i32 }* %3)
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %4 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %4, align 4
//CHECK-NEXT:   br label %unrolled_loop4
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop4:
//CHECK-NEXT:   %5 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 0, i256* %5, align 4
//CHECK-NEXT:   %6 = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %7 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %8 = load [0 x i256]*, [0 x i256]** %7, align 8
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %8, i32 0
//CHECK-NEXT:   %10 = getelementptr [0 x i256], [0 x i256]* %9, i32 0, i256 1
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   %12 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %13 = load [0 x i256]*, [0 x i256]** %12, align 8
//CHECK-NEXT:   %14 = getelementptr [0 x i256], [0 x i256]* %13, i32 0
//CHECK-NEXT:   %15 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %16 = bitcast i32* %15 to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %6, [0 x i256]* %0, i256* %10, i256* %11, [0 x i256]* %14, i256* %16)
//CHECK-NEXT:   %17 = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %18 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %19 = load [0 x i256]*, [0 x i256]** %18, align 8
//CHECK-NEXT:   %20 = getelementptr [0 x i256], [0 x i256]* %19, i32 0
//CHECK-NEXT:   %21 = getelementptr [0 x i256], [0 x i256]* %20, i32 0, i256 2
//CHECK-NEXT:   %22 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %23 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %24 = load [0 x i256]*, [0 x i256]** %23, align 8
//CHECK-NEXT:   %25 = getelementptr [0 x i256], [0 x i256]* %24, i32 0
//CHECK-NEXT:   %26 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %27 = bitcast i32* %26 to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %17, [0 x i256]* %0, i256* %21, i256* %22, [0 x i256]* %25, i256* %27)
//CHECK-NEXT:   %28 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %29 = load [0 x i256]*, [0 x i256]** %28, align 8
//CHECK-NEXT:   %30 = getelementptr [0 x i256], [0 x i256]* %29, i32 0, i32 0
//CHECK-NEXT:   %31 = load i256, i256* %30, align 4
//CHECK-NEXT:   %call.fr_eq = call i1 @fr_eq(i256 %31, i256 77)
//CHECK-NEXT:   call void @__assert(i1 %call.fr_eq)
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_value(i1 %call.fr_eq, i1* %constraint)
//CHECK-NEXT:   %32 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 1, i256* %32, align 4
//CHECK-NEXT:   %33 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 0, i256* %33, align 4
//CHECK-NEXT:   %34 = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %35 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %36 = load [0 x i256]*, [0 x i256]** %35, align 8
//CHECK-NEXT:   %37 = getelementptr [0 x i256], [0 x i256]* %36, i32 0
//CHECK-NEXT:   %38 = getelementptr [0 x i256], [0 x i256]* %37, i32 0, i256 1
//CHECK-NEXT:   %39 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   %40 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %41 = load [0 x i256]*, [0 x i256]** %40, align 8
//CHECK-NEXT:   %42 = getelementptr [0 x i256], [0 x i256]* %41, i32 0
//CHECK-NEXT:   %43 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %44 = bitcast i32* %43 to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %34, [0 x i256]* %0, i256* %38, i256* %39, [0 x i256]* %42, i256* %44)
//CHECK-NEXT:   %45 = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %46 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %47 = load [0 x i256]*, [0 x i256]** %46, align 8
//CHECK-NEXT:   %48 = getelementptr [0 x i256], [0 x i256]* %47, i32 0
//CHECK-NEXT:   %49 = getelementptr [0 x i256], [0 x i256]* %48, i32 0, i256 2
//CHECK-NEXT:   %50 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   %51 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %52 = load [0 x i256]*, [0 x i256]** %51, align 8
//CHECK-NEXT:   %53 = getelementptr [0 x i256], [0 x i256]* %52, i32 0
//CHECK-NEXT:   %54 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %55 = bitcast i32* %54 to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %45, [0 x i256]* %0, i256* %49, i256* %50, [0 x i256]* %53, i256* %55)
//CHECK-NEXT:   %56 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %57 = load [0 x i256]*, [0 x i256]** %56, align 8
//CHECK-NEXT:   %58 = getelementptr [0 x i256], [0 x i256]* %57, i32 0, i32 0
//CHECK-NEXT:   %59 = load i256, i256* %58, align 4
//CHECK-NEXT:   %call.fr_eq22 = call i1 @fr_eq(i256 %59, i256 77)
//CHECK-NEXT:   call void @__assert(i1 %call.fr_eq22)
//CHECK-NEXT:   %constraint23 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_value(i1 %call.fr_eq22, i1* %constraint23)
//CHECK-NEXT:   %60 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 2, i256* %60, align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
