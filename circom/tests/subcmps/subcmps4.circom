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

template SubCmps4(n) {
    signal input inp[n*2];
    signal output outp[2];

    component a = Sum(n);
    component b = Sum(n);

    for (var i = 0; i < n*2; i++) {
        if (i % 2 == 0) {
            a.inp[i\2] <== inp[i];
        } else {
            b.inp[i\2] <== inp[i];
        }
    }
    outp[0] <-- a.outp;
    outp[1] <-- b.outp;
}

component main = SubCmps4(3);

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %fix_[[X1:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9]+]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr i256, i256* %fix_0, i32 0
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
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+\.T\.F}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %subfix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]], i256* %subfix_[[X3:[0-9]+]],
//CHECK-SAME:  i256* %fix_[[X4:[0-9]+]], [0 x i256]* %sub_[[X3]], i256* %subc_[[X3]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2:[0-9]+\.T\.F]]:
//CHECK-NEXT:   br label %fold_true1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_true1:
//CHECK-NEXT:   %0 = getelementptr i256, i256* %fix_[[X2]], i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr i256, i256* %subfix_[[X1]], i32 0
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %1, i256 %3, i1* %constraint)
//CHECK-NEXT:   %4 = load i256, i256* %subc_[[X3]], align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %4, i256 1)
//CHECK-NEXT:   %5 = getelementptr i256, i256* %subc_[[X3]], i32 0
//CHECK-NEXT:   store i256 %call.fr_sub, i256* %5, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %7 = load i256, i256* %6, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %7, i256 1)
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 %call.fr_add, i256* %8, align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+\.F\.F}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %subfix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]], i256* %subfix_[[X3:[0-9]+]],
//CHECK-SAME:  i256* %fix_[[X4:[0-9]+]], [0 x i256]* %sub_[[X3]], i256* %subc_[[X3]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_3:[0-9]+\.F\.F]]:
//CHECK-NEXT:   br label %fold_false1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_false1:
//CHECK-NEXT:   %0 = getelementptr i256, i256* %fix_[[X4]], i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr i256, i256* %subfix_[[X3]], i32 0
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %1, i256 %3, i1* %constraint)
//CHECK-NEXT:   %4 = load i256, i256* %subc_[[X3]], align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %4, i256 1)
//CHECK-NEXT:   %5 = getelementptr i256, i256* %subc_[[X3]], i32 0
//CHECK-NEXT:   store i256 %call.fr_sub, i256* %5, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %7 = load i256, i256* %6, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %7, i256 1)
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 %call.fr_add, i256* %8, align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+\.T\.T}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %subfix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]], i256* %subfix_[[X3:[0-9]+]],
//CHECK-SAME:  i256* %fix_[[X4:[0-9]+]], [0 x i256]* %sub_[[X3]], i256* %subc_[[X3]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_4:[0-9]+\.T\.T]]:
//CHECK-NEXT:   br label %fold_true1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_true1:
//CHECK-NEXT:   %0 = getelementptr i256, i256* %fix_[[X2]], i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr i256, i256* %subfix_[[X1]], i32 0
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %1, i256 %3, i1* %constraint)
//CHECK-NEXT:   %4 = load i256, i256* %subc_[[X3]], align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %4, i256 1)
//CHECK-NEXT:   %5 = getelementptr i256, i256* %subc_[[X3]], i32 0
//CHECK-NEXT:   store i256 %call.fr_sub, i256* %5, align 4
//CHECK-NEXT:   call void @Sum_0_run([0 x i256]* %sub_[[X3]])
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %7 = load i256, i256* %6, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %7, i256 1)
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 %call.fr_add, i256* %8, align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+\.F\.T}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %subfix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]], i256* %subfix_[[X3:[0-9]+]],
//CHECK-SAME:  i256* %fix_[[X4:[0-9]+]], [0 x i256]* %sub_[[X3]], i256* %subc_[[X3]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_5:[0-9]+\.F\.T]]:
//CHECK-NEXT:   br label %fold_false1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_false1:
//CHECK-NEXT:   %0 = getelementptr i256, i256* %fix_[[X4]], i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr i256, i256* %subfix_[[X3]], i32 0
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %1, i256 %3, i1* %constraint)
//CHECK-NEXT:   %4 = load i256, i256* %subc_[[X3]], align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %4, i256 1)
//CHECK-NEXT:   %5 = getelementptr i256, i256* %subc_[[X3]], i32 0
//CHECK-NEXT:   store i256 %call.fr_sub, i256* %5, align 4
//CHECK-NEXT:   call void @Sum_0_run([0 x i256]* %sub_[[X3]])
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %7 = load i256, i256* %6, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %7, i256 1)
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 %call.fr_add, i256* %8, align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @Sum_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [3 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 3, i256* %1, align 4
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
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %10 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %11 = load i256, i256* %10, align 4
//CHECK-NEXT:   %12 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %11, i256* %12, align 4
//CHECK-NEXT:   %13 = load i256, i256* %12, align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %11, i256 %13, i1* %constraint)
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define dso_local void @SubCmps4_1_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [2 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [2 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 3, i256* %1, align 4
//CHECK-NEXT:   br label %create_cmp2
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp2:
//CHECK-NEXT:   %2 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0
//CHECK-NEXT:   call void @Sum_0_build({ [0 x i256]*, i32 }* %2)
//CHECK-NEXT:   br label %create_cmp3
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp3:
//CHECK-NEXT:   %3 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1
//CHECK-NEXT:   call void @Sum_0_build({ [0 x i256]*, i32 }* %3)
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %4 = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %4, align 4
//CHECK-NEXT:   br label %unrolled_loop5
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop5:
//CHECK-NEXT:   %5 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %6 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %7 = load [0 x i256]*, [0 x i256]** %6, align 8
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %7, i32 0
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %8, i32 0, i256 1
//CHECK-NEXT:   %10 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %5, [0 x i256]* %0, i256* %9, i256* %10, i256* null, i256* null, [0 x i256]* null, i256* null)
//CHECK-NEXT:   %11 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %12 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %13 = load [0 x i256]*, [0 x i256]** %12, align 8
//CHECK-NEXT:   %14 = getelementptr [0 x i256], [0 x i256]* %13, i32 0
//CHECK-NEXT:   %15 = getelementptr [0 x i256], [0 x i256]* %14, i32 0, i256 1
//CHECK-NEXT:   %16 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   %17 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %18 = load [0 x i256]*, [0 x i256]** %17, align 8
//CHECK-NEXT:   %19 = getelementptr [0 x i256], [0 x i256]* %18, i32 0
//CHECK-NEXT:   %20 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %21 = bitcast i32* %20 to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_3]]([0 x i256]* %11, [0 x i256]* %0, i256* null, i256* null, i256* %15, i256* %16, [0 x i256]* %19, i256* %21)
//CHECK-NEXT:   %22 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %23 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %24 = load [0 x i256]*, [0 x i256]** %23, align 8
//CHECK-NEXT:   %25 = getelementptr [0 x i256], [0 x i256]* %24, i32 0
//CHECK-NEXT:   %26 = getelementptr [0 x i256], [0 x i256]* %25, i32 0, i256 2
//CHECK-NEXT:   %27 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 4
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %22, [0 x i256]* %0, i256* %26, i256* %27, i256* null, i256* null, [0 x i256]* null, i256* null)
//CHECK-NEXT:   %28 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %29 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %30 = load [0 x i256]*, [0 x i256]** %29, align 8
//CHECK-NEXT:   %31 = getelementptr [0 x i256], [0 x i256]* %30, i32 0
//CHECK-NEXT:   %32 = getelementptr [0 x i256], [0 x i256]* %31, i32 0, i256 2
//CHECK-NEXT:   %33 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 5
//CHECK-NEXT:   %34 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %35 = load [0 x i256]*, [0 x i256]** %34, align 8
//CHECK-NEXT:   %36 = getelementptr [0 x i256], [0 x i256]* %35, i32 0
//CHECK-NEXT:   %37 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %38 = bitcast i32* %37 to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_3]]([0 x i256]* %28, [0 x i256]* %0, i256* null, i256* null, i256* %32, i256* %33, [0 x i256]* %36, i256* %38)
//CHECK-NEXT:   %39 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %40 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %41 = load [0 x i256]*, [0 x i256]** %40, align 8
//CHECK-NEXT:   %42 = getelementptr [0 x i256], [0 x i256]* %41, i32 0
//CHECK-NEXT:   %43 = getelementptr [0 x i256], [0 x i256]* %42, i32 0, i256 3
//CHECK-NEXT:   %44 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 6
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_4]]([0 x i256]* %39, [0 x i256]* %0, i256* %43, i256* %44, i256* null, i256* null, [0 x i256]* null, i256* null)
//CHECK-NEXT:   %45 = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %46 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %47 = load [0 x i256]*, [0 x i256]** %46, align 8
//CHECK-NEXT:   %48 = getelementptr [0 x i256], [0 x i256]* %47, i32 0
//CHECK-NEXT:   %49 = getelementptr [0 x i256], [0 x i256]* %48, i32 0, i256 3
//CHECK-NEXT:   %50 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 7
//CHECK-NEXT:   %51 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %52 = load [0 x i256]*, [0 x i256]** %51, align 8
//CHECK-NEXT:   %53 = getelementptr [0 x i256], [0 x i256]* %52, i32 0
//CHECK-NEXT:   %54 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %55 = bitcast i32* %54 to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_5]]([0 x i256]* %45, [0 x i256]* %0, i256* null, i256* null, i256* %49, i256* %50, [0 x i256]* %53, i256* %55)
//CHECK-NEXT:   br label %store6
//CHECK-EMPTY: 
//CHECK-NEXT: store6:
//CHECK-NEXT:   %56 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %57 = load [0 x i256]*, [0 x i256]** %56, align 8
//CHECK-NEXT:   %58 = getelementptr [0 x i256], [0 x i256]* %57, i32 0, i32 0
//CHECK-NEXT:   %59 = load i256, i256* %58, align 4
//CHECK-NEXT:   %60 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %59, i256* %60, align 4
//CHECK-NEXT:   br label %store7
//CHECK-EMPTY: 
//CHECK-NEXT: store7:
//CHECK-NEXT:   %61 = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %62 = load [0 x i256]*, [0 x i256]** %61, align 8
//CHECK-NEXT:   %63 = getelementptr [0 x i256], [0 x i256]* %62, i32 0, i32 0
//CHECK-NEXT:   %64 = load i256, i256* %63, align 4
//CHECK-NEXT:   %65 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:   store i256 %64, i256* %65, align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
