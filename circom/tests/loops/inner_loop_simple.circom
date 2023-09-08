pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template InnerLoops(n, m) {
    signal input in[m];
    signal output out;
    var b[n];

    for (var i = 0; i < n; i++) {
        for (var j = 0; j < m; j++) {
            b[i] = in[j];
        }
    }
    out <-- b[0];
}

component main = InnerLoops(2, 3);

// %0 (i.e. signal arena) = { out, in[0], in[1], in[2] }
// %lvars = { n, m, b[0], b[1], i, j }
//
//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, [0 x i256]* %fixed_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.{{.*}}[[$F_ID_1]]:
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %call.fr_cast_to_addr = call i32 @fr_cast_to_addr(i256 %1)
//CHECK-NEXT:   %mul_addr = mul i32 1, %call.fr_cast_to_addr
//CHECK-NEXT:   %add_addr = add i32 %mul_addr, 2
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %fixed_0, i32 0, i32 0
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 %add_addr
//CHECK-NEXT:   store i256 %3, i256* %4, align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %6 = load i256, i256* %5, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %6, i256 1)
//CHECK-NEXT:   %7 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 %call.fr_add, i256* %7, align 4
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
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %call.fr_cast_to_addr = call i32 @fr_cast_to_addr(i256 %1)
//CHECK-NEXT:   %mul_addr = mul i32 1, %call.fr_cast_to_addr
//CHECK-NEXT:   %add_addr = add i32 %mul_addr, 2
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %fixed_0, i32 0, i32 0
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 %add_addr
//CHECK-NEXT:   store i256 %3, i256* %4, align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %6 = load i256, i256* %5, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %6, i256 1)
//CHECK-NEXT:   %7 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 %call.fr_add, i256* %7, align 4
//CHECK-NEXT:   br label %return{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: return{{[0-9]+}}:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @InnerLoops_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK:      unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %6 = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 0, i256* %6, align 4
//CHECK-NEXT:   %7 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %9 = bitcast i256* %8 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.{{.*}}[[$F_ID_1]]([0 x i256]* %7, [0 x i256]* %0, [0 x i256]* %9)
//CHECK-NEXT:   %10 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   %12 = bitcast i256* %11 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.{{.*}}[[$F_ID_1]]([0 x i256]* %10, [0 x i256]* %0, [0 x i256]* %12)
//CHECK-NEXT:   %13 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %14 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   %15 = bitcast i256* %14 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.{{.*}}[[$F_ID_1]]([0 x i256]* %13, [0 x i256]* %0, [0 x i256]* %15)
//CHECK-NEXT:   %16 = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %17 = load i256, i256* %16, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %17, i256 1)
//CHECK-NEXT:   %18 = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 %call.fr_add, i256* %18, align 4
//CHECK-NEXT:   %19 = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 0, i256* %19, align 4
//CHECK-NEXT:   %20 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %21 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %22 = bitcast i256* %21 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.{{.*}}[[$F_ID_2]]([0 x i256]* %20, [0 x i256]* %0, [0 x i256]* %22)
//CHECK-NEXT:   %23 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %24 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   %25 = bitcast i256* %24 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.{{.*}}[[$F_ID_2]]([0 x i256]* %23, [0 x i256]* %0, [0 x i256]* %25)
//CHECK-NEXT:   %26 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %27 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   %28 = bitcast i256* %27 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.{{.*}}[[$F_ID_2]]([0 x i256]* %26, [0 x i256]* %0, [0 x i256]* %28)
//CHECK-NEXT:   %29 = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %30 = load i256, i256* %29, align 4
//CHECK-NEXT:   %call.fr_add23 = call i256 @fr_add(i256 %30, i256 1)
//CHECK-NEXT:   %31 = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 %call.fr_add23, i256* %31, align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %32 = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %33 = load i256, i256* %32, align 4
//CHECK-NEXT:   %34 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %33, i256* %34, align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
