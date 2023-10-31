pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL: .* // pending https://veridise.atlassian.net/browse/VAN-798

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

//COM:CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//COM:CHECK-SAME: i256* %fix_[[X1:[0-9]+]]){{.*}} {
//COM:CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9]+]]:
//COM:CHECK-NEXT:   br label %store1
//COM:CHECK-EMPTY: 
//COM:CHECK-NEXT: store1:
//COM:CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//COM:CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//COM:CHECK-NEXT:   %2 = getelementptr i256, i256* %fix_[[X1]], i32 0
//COM:CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//COM:CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %1, i256 %3)
//COM:CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//COM:CHECK-NEXT:   store i256 %call.fr_add, i256* %4, align 4
//COM:CHECK-NEXT:   br label %store2
//COM:CHECK-EMPTY: 
//COM:CHECK-NEXT: store2:
//COM:CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//COM:CHECK-NEXT:   %6 = load i256, i256* %5, align 4
//COM:CHECK-NEXT:   %call.fr_add1 = call i256 @fr_add(i256 %6, i256 1)
//COM:CHECK-NEXT:   %7 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//COM:CHECK-NEXT:   store i256 %call.fr_add1, i256* %7, align 4
//COM:CHECK-NEXT:   br label %return3
//COM:CHECK-EMPTY: 
//COM:CHECK-NEXT: return3:
//COM:CHECK-NEXT:   ret void
//COM:CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+\.F}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]], i256* %fix_[[X3:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2:[0-9]+\.F]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr i256, i256* %fix_[[X2]], i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr i256, i256* %fix_[[X1]], i32 0
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %1, i256 %3, i1* %constraint)
//CHECK-NEXT:   br label %fold_false2
//CHECK-EMPTY: 
//CHECK-NEXT: fold_false2:
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   %5 = load i256, i256* %4, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %5, i256 1)
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 %call.fr_add, i256* %6, align 4
//CHECK-NEXT:   br label %return4
//CHECK-EMPTY: 
//CHECK-NEXT: return4:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+\.T}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]], i256* %fix_[[X3:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_3:[0-9]+\.T]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr i256, i256* %fix_[[X2]], i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr i256, i256* %fix_[[X1]], i32 0
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %1, i256 %3, i1* %constraint)
//CHECK-NEXT:   br label %fold_true2
//CHECK-EMPTY: 
//CHECK-NEXT: fold_true2:
//CHECK-NEXT:   %4 = getelementptr i256, i256* %fix_[[X3]], i32 0
//CHECK-NEXT:   %5 = load i256, i256* %4, align 4
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 0
//CHECK-NEXT:   store i256 %5, i256* %6, align 4
//CHECK-NEXT:   %7 = load i256, i256* %6, align 4
//CHECK-NEXT:   %constraint1 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %5, i256 %7, i1* %constraint1)
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   %9 = load i256, i256* %8, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %9, i256 1)
//CHECK-NEXT:   %10 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 %call.fr_add, i256* %10, align 4
//CHECK-NEXT:   br label %return4
//CHECK-EMPTY: 
//CHECK-NEXT: return4:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//COM:CHECK-LABEL: define{{.*}} void @Sum_0_run([0 x i256]* %0){{.*}} {
//COM:CHECK-NEXT: prelude:
//COM:CHECK-NEXT:   %lvars = alloca [3 x i256], align 8
//COM:CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//COM:CHECK-NEXT:   br label %store1
//COM:CHECK-EMPTY: 
//COM:CHECK-NEXT: store1:
//COM:CHECK-NEXT:   %1 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 0
//COM:CHECK-NEXT:   store i256 4, i256* %1, align 4
//COM:CHECK-NEXT:   br label %store2
//COM:CHECK-EMPTY: 
//COM:CHECK-NEXT: store2:
//COM:CHECK-NEXT:   %2 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
//COM:CHECK-NEXT:   store i256 0, i256* %2, align 4
//COM:CHECK-NEXT:   br label %store3
//COM:CHECK-EMPTY: 
//COM:CHECK-NEXT: store3:
//COM:CHECK-NEXT:   %3 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 2
//COM:CHECK-NEXT:   store i256 0, i256* %3, align 4
//COM:CHECK-NEXT:   br label %unrolled_loop4
//COM:CHECK-EMPTY: 
//COM:CHECK-NEXT: unrolled_loop4:
//COM:CHECK-NEXT:   %4 = bitcast [3 x i256]* %lvars to [0 x i256]*
//COM:CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//COM:CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %4, [0 x i256]* %0, i256* %5)
//COM:CHECK-NEXT:   %6 = bitcast [3 x i256]* %lvars to [0 x i256]*
//COM:CHECK-NEXT:   %7 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//COM:CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %6, [0 x i256]* %0, i256* %7)
//COM:CHECK-NEXT:   %8 = bitcast [3 x i256]* %lvars to [0 x i256]*
//COM:CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//COM:CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %8, [0 x i256]* %0, i256* %9)
//COM:CHECK-NEXT:   %10 = bitcast [3 x i256]* %lvars to [0 x i256]*
//COM:CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 4
//COM:CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %10, [0 x i256]* %0, i256* %11)
//COM:CHECK-NEXT:   br label %store5
//COM:CHECK-EMPTY: 
//COM:CHECK-NEXT: store5:
//COM:CHECK-NEXT:   %12 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
//COM:CHECK-NEXT:   %13 = load i256, i256* %12, align 4
//COM:CHECK-NEXT:   %14 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//COM:CHECK-NEXT:   store i256 %13, i256* %14, align 4
//COM:CHECK-NEXT:   %15 = load i256, i256* %14, align 4
//COM:CHECK-NEXT:   %constraint = alloca i1, align 1
//COM:CHECK-NEXT:   call void @__constraint_values(i256 %13, i256 %15, i1* %constraint)
//COM:CHECK-NEXT:   br label %prologue
//COM:CHECK-EMPTY: 
//COM:CHECK-NEXT: prologue:
//COM:CHECK-NEXT:   ret void
//COM:CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @SubCmps3_1_run([0 x i256]* %0){{.*}} {
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
//CHECK-NEXT:   %3 = bitcast [1 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %4 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %5 = load [0 x i256]*, [0 x i256]** %4, align 8
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %5, i32 0
//CHECK-NEXT:   %7 = getelementptr [0 x i256], [0 x i256]* %6, i32 0, i256 1
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %3, [0 x i256]* %0, i256* %7, i256* %8, i256* null)
//CHECK-NEXT:   %9 = bitcast [1 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %10 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %11 = load [0 x i256]*, [0 x i256]** %10, align 8
//CHECK-NEXT:   %12 = getelementptr [0 x i256], [0 x i256]* %11, i32 0
//CHECK-NEXT:   %13 = getelementptr [0 x i256], [0 x i256]* %12, i32 0, i256 2
//CHECK-NEXT:   %14 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %9, [0 x i256]* %0, i256* %13, i256* %14, i256* null)
//CHECK-NEXT:   %15 = bitcast [1 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %16 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %17 = load [0 x i256]*, [0 x i256]** %16, align 8
//CHECK-NEXT:   %18 = getelementptr [0 x i256], [0 x i256]* %17, i32 0
//CHECK-NEXT:   %19 = getelementptr [0 x i256], [0 x i256]* %18, i32 0, i256 3
//CHECK-NEXT:   %20 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %15, [0 x i256]* %0, i256* %19, i256* %20, i256* null)
//CHECK-NEXT:   %21 = bitcast [1 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %22 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %23 = load [0 x i256]*, [0 x i256]** %22, align 8
//CHECK-NEXT:   %24 = getelementptr [0 x i256], [0 x i256]* %23, i32 0
//CHECK-NEXT:   %25 = getelementptr [0 x i256], [0 x i256]* %24, i32 0, i256 4
//CHECK-NEXT:   %26 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 4
//CHECK-NEXT:   %27 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %28 = load [0 x i256]*, [0 x i256]** %27, align 8
//CHECK-NEXT:   %29 = getelementptr [0 x i256], [0 x i256]* %28, i32 0
//CHECK-NEXT:   %30 = getelementptr [0 x i256], [0 x i256]* %29, i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_3]]([0 x i256]* %21, [0 x i256]* %0, i256* %25, i256* %26, i256* %30)
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
