pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template InnerLoops(n) {
    signal input a[n];
    var b[n];

    // Manually unrolled loop from inner_loops.circom
    //for (var i = 0; i < n; i++) {

    var i = 0;
    for (var j = 0; j <= i; j++) {
        b[i] = a[i - j];
    }
    i++; // 1
    for (var j = 0; j <= i; j++) {
        b[i] = a[i - j];
    }
    i++; // 2
    for (var j = 0; j <= i; j++) {
        b[i] = a[i - j];
    }
    i++; // 3
    for (var j = 0; j <= i; j++) {
        b[i] = a[i - j];
    }
    i++; // 4
    for (var j = 0; j <= i; j++) {
        b[i] = a[i - j];
    }
    i++; // 5
}

component main = InnerLoops(5);

//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   store i256 1, i256* %3, align 4
//CHECK-NEXT:   br label %return{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: return{{[0-9]+}}:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
// 
//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_2:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %fix_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2]]:
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %0 = getelementptr i256, i256* %fix_0, i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   %4 = load i256, i256* %3, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %4, i256 1)
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   store i256 %call.fr_add, i256* %5, align 4
//CHECK-NEXT:   br label %return{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: return{{[0-9]+}}:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
// 
//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_3:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %fix_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_3]]:
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %0 = getelementptr i256, i256* %fix_0, i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   %4 = load i256, i256* %3, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %4, i256 1)
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   store i256 %call.fr_add, i256* %5, align 4
//CHECK-NEXT:   br label %return{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: return{{[0-9]+}}:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_4:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %fix_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_4]]:
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %0 = getelementptr i256, i256* %fix_0, i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   %4 = load i256, i256* %3, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %4, i256 1)
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   store i256 %call.fr_add, i256* %5, align 4
//CHECK-NEXT:   br label %return{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: return{{[0-9]+}}:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_5:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %fix_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_5]]:
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %0 = getelementptr i256, i256* %fix_0, i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   %4 = load i256, i256* %3, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %4, i256 1)
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   store i256 %call.fr_add, i256* %5, align 4
//CHECK-NEXT:   br label %return{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: return{{[0-9]+}}:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @InnerLoops_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK:      unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %9 = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %9, [0 x i256]* %0)
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %10 = getelementptr [8 x i256], [8 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 1, i256* %10, align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %11 = getelementptr [8 x i256], [8 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   store i256 0, i256* %11, align 4
//CHECK-NEXT:   br label %unrolled_loop{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %12 = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %13 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %12, [0 x i256]* %0, i256* %13)
//CHECK-NEXT:   %14 = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %15 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %14, [0 x i256]* %0, i256* %15)
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %16 = getelementptr [8 x i256], [8 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 2, i256* %16, align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %17 = getelementptr [8 x i256], [8 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   store i256 0, i256* %17, align 4
//CHECK-NEXT:   br label %unrolled_loop{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %18 = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %19 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_3]]([0 x i256]* %18, [0 x i256]* %0, i256* %19)
//CHECK-NEXT:   %20 = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %21 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_3]]([0 x i256]* %20, [0 x i256]* %0, i256* %21)
//CHECK-NEXT:   %22 = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %23 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_3]]([0 x i256]* %22, [0 x i256]* %0, i256* %23)
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %24 = getelementptr [8 x i256], [8 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 3, i256* %24, align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %25 = getelementptr [8 x i256], [8 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   store i256 0, i256* %25, align 4
//CHECK-NEXT:   br label %unrolled_loop{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %26 = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %27 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_4]]([0 x i256]* %26, [0 x i256]* %0, i256* %27)
//CHECK-NEXT:   %28 = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %29 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_4]]([0 x i256]* %28, [0 x i256]* %0, i256* %29)
//CHECK-NEXT:   %30 = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %31 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_4]]([0 x i256]* %30, [0 x i256]* %0, i256* %31)
//CHECK-NEXT:   %32 = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %33 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_4]]([0 x i256]* %32, [0 x i256]* %0, i256* %33)
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %34 = getelementptr [8 x i256], [8 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 4, i256* %34, align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %35 = getelementptr [8 x i256], [8 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   store i256 0, i256* %35, align 4
//CHECK-NEXT:   br label %unrolled_loop{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %36 = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %37 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 4
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_5]]([0 x i256]* %36, [0 x i256]* %0, i256* %37)
//CHECK-NEXT:   %38 = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %39 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_5]]([0 x i256]* %38, [0 x i256]* %0, i256* %39)
//CHECK-NEXT:   %40 = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %41 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_5]]([0 x i256]* %40, [0 x i256]* %0, i256* %41)
//CHECK-NEXT:   %42 = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %43 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_5]]([0 x i256]* %42, [0 x i256]* %0, i256* %43)
//CHECK-NEXT:   %44 = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %45 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_5]]([0 x i256]* %44, [0 x i256]* %0, i256* %45)
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %46 = getelementptr [8 x i256], [8 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 5, i256* %46, align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
