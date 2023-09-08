pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template InnerLoops(n) {
    signal input a[n];
    var b[n];

    for (var j = 0; j <= 0; j++) {
        b[0] = a[0 - j];
    }
    for (var j = 0; j <= 1; j++) {
        b[1] = a[1 - j];
    }
    for (var j = 0; j <= 2; j++) {
        b[2] = a[2 - j];
    }
    for (var j = 0; j <= 3; j++) {
        b[3] = a[3 - j];
    }
    for (var j = 0; j <= 4; j++) {
        b[4] = a[4 - j];
    }
}

component main = InnerLoops(5);

//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals){{.*}} {
//CHECK-NEXT: ..generated..loop.body.{{.*}}[[$F_ID_1]]:
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
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 1, i256* %3, align 4
//CHECK-NEXT:   br label %return{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: return{{[0-9]+}}:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_2:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, [0 x i256]* %fixed_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.{{.*}}[[$F_ID_2]]:
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %fixed_0, i32 0, i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %4 = load i256, i256* %3, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %4, i256 1)
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 %call.fr_add, i256* %5, align 4
//CHECK-NEXT:   br label %return{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: return{{[0-9]+}}:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_3:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, [0 x i256]* %fixed_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.{{.*}}[[$F_ID_3]]:
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %fixed_0, i32 0, i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %4 = load i256, i256* %3, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %4, i256 1)
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 %call.fr_add, i256* %5, align 4
//CHECK-NEXT:   br label %return{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: return{{[0-9]+}}:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_4:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, [0 x i256]* %fixed_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.{{.*}}[[$F_ID_4]]:
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %fixed_0, i32 0, i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %4 = load i256, i256* %3, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %4, i256 1)
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 %call.fr_add, i256* %5, align 4
//CHECK-NEXT:   br label %return{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: return{{[0-9]+}}:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_5:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, [0 x i256]* %fixed_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.{{.*}}[[$F_ID_5]]:
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %fixed_0, i32 0, i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %4 = load i256, i256* %3, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %4, i256 1)
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 %call.fr_add, i256* %5, align 4
//CHECK-NEXT:   br label %return{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: return{{[0-9]+}}:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @InnerLoops_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK:      unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %8 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.{{.*}}[[$F_ID_1]]([0 x i256]* %8, [0 x i256]* %0)
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %9 = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 0, i256* %9, align 4
//CHECK-NEXT:   br label %unrolled_loop{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT:  unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %10 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %12 = bitcast i256* %11 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.{{.*}}[[$F_ID_2]]([0 x i256]* %10, [0 x i256]* %0, [0 x i256]* %12)
//CHECK-NEXT:   %13 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %14 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   %15 = bitcast i256* %14 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.{{.*}}[[$F_ID_2]]([0 x i256]* %13, [0 x i256]* %0, [0 x i256]* %15)
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %16 = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 0, i256* %16, align 4
//CHECK-NEXT:   br label %unrolled_loop{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %17 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %18 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   %19 = bitcast i256* %18 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.{{.*}}[[$F_ID_3]]([0 x i256]* %17, [0 x i256]* %0, [0 x i256]* %19)
//CHECK-NEXT:   %20 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %21 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %22 = bitcast i256* %21 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.{{.*}}[[$F_ID_3]]([0 x i256]* %20, [0 x i256]* %0, [0 x i256]* %22)
//CHECK-NEXT:   %23 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %24 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   %25 = bitcast i256* %24 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.{{.*}}[[$F_ID_3]]([0 x i256]* %23, [0 x i256]* %0, [0 x i256]* %25)
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %26 = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 0, i256* %26, align 4
//CHECK-NEXT:   br label %unrolled_loop{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %27 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %28 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   %29 = bitcast i256* %28 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.{{.*}}[[$F_ID_4]]([0 x i256]* %27, [0 x i256]* %0, [0 x i256]* %29)
//CHECK-NEXT:   %30 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %31 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   %32 = bitcast i256* %31 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.{{.*}}[[$F_ID_4]]([0 x i256]* %30, [0 x i256]* %0, [0 x i256]* %32)
//CHECK-NEXT:   %33 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %34 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %35 = bitcast i256* %34 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.{{.*}}[[$F_ID_4]]([0 x i256]* %33, [0 x i256]* %0, [0 x i256]* %35)
//CHECK-NEXT:   %36 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %37 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   %38 = bitcast i256* %37 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.{{.*}}[[$F_ID_4]]([0 x i256]* %36, [0 x i256]* %0, [0 x i256]* %38)
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %39 = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 0, i256* %39, align 4
//CHECK-NEXT:   br label %unrolled_loop{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %40 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %41 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 4
//CHECK-NEXT:   %42 = bitcast i256* %41 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.{{.*}}[[$F_ID_5]]([0 x i256]* %40, [0 x i256]* %0, [0 x i256]* %42)
//CHECK-NEXT:   %43 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %44 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   %45 = bitcast i256* %44 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.{{.*}}[[$F_ID_5]]([0 x i256]* %43, [0 x i256]* %0, [0 x i256]* %45)
//CHECK-NEXT:   %46 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %47 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   %48 = bitcast i256* %47 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.{{.*}}[[$F_ID_5]]([0 x i256]* %46, [0 x i256]* %0, [0 x i256]* %48)
//CHECK-NEXT:   %49 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %50 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %51 = bitcast i256* %50 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.{{.*}}[[$F_ID_5]]([0 x i256]* %49, [0 x i256]* %0, [0 x i256]* %51)
//CHECK-NEXT:   %52 = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %53 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   %54 = bitcast i256* %53 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.{{.*}}[[$F_ID_5]]([0 x i256]* %52, [0 x i256]* %0, [0 x i256]* %54)
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
