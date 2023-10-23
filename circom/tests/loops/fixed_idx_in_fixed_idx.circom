pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*     // TEMPORARY: because EXTRACT_LOOP_BODY_TO_NEW_FUNC == false

// This case initially triggered the "assert!(bucket_to_args.is_empty());" line in body_extractor.rs
//  because the entire expression 'in[byte_order[i]]'' is replaced but the 'byte_order[i]' expression
//  is also listed in the "bucket_to_args" map as a safe replacement.
template EmulatedAesencRowShifting() {
    signal input in[16];
    signal output out[16];
    
    var byte_order[16] = [0, 5, 10, 15, 4, 9, 14, 3, 8, 13, 2, 7, 12, 1, 6, 11];

    for (var i = 0; i < 16; i++) {
        out[i] <== in[byte_order[i]];
    }
}

component main = EmulatedAesencRowShifting();

//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %fix_0, i256* %fix_1){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr i256, i256* %fix_1, i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr i256, i256* %fix_0, i32 0
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %1, i256 %3, i1* %constraint)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 16
//CHECK-NEXT:   %5 = load i256, i256* %4, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %5, i256 1)
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 16
//CHECK-NEXT:   store i256 %call.fr_add, i256* %6, align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @EmulatedAesencRowShifting_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [17 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY:
//CHECK:      unrolled_loop18:
//CHECK-NEXT:   %18 = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %19 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   %20 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 16
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %18, [0 x i256]* %0, i256* %19, i256* %20)
//CHECK-NEXT:   %21 = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %22 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %23 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 21
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %21, [0 x i256]* %0, i256* %22, i256* %23)
//CHECK-NEXT:   %24 = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %25 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   %26 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 26
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %24, [0 x i256]* %0, i256* %25, i256* %26)
//CHECK-NEXT:   %27 = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %28 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   %29 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 31
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %27, [0 x i256]* %0, i256* %28, i256* %29)
//CHECK-NEXT:   %30 = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %31 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 4
//CHECK-NEXT:   %32 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 20
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %30, [0 x i256]* %0, i256* %31, i256* %32)
//CHECK-NEXT:   %33 = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %34 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 5
//CHECK-NEXT:   %35 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 25
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %33, [0 x i256]* %0, i256* %34, i256* %35)
//CHECK-NEXT:   %36 = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %37 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 6
//CHECK-NEXT:   %38 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 30
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %36, [0 x i256]* %0, i256* %37, i256* %38)
//CHECK-NEXT:   %39 = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %40 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 7
//CHECK-NEXT:   %41 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 19
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %39, [0 x i256]* %0, i256* %40, i256* %41)
//CHECK-NEXT:   %42 = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %43 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 8
//CHECK-NEXT:   %44 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 24
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %42, [0 x i256]* %0, i256* %43, i256* %44)
//CHECK-NEXT:   %45 = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %46 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 9
//CHECK-NEXT:   %47 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 29
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %45, [0 x i256]* %0, i256* %46, i256* %47)
//CHECK-NEXT:   %48 = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %49 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 10
//CHECK-NEXT:   %50 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 18
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %48, [0 x i256]* %0, i256* %49, i256* %50)
//CHECK-NEXT:   %51 = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %52 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 11
//CHECK-NEXT:   %53 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 23
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %51, [0 x i256]* %0, i256* %52, i256* %53)
//CHECK-NEXT:   %54 = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %55 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 12
//CHECK-NEXT:   %56 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 28
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %54, [0 x i256]* %0, i256* %55, i256* %56)
//CHECK-NEXT:   %57 = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %58 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 13
//CHECK-NEXT:   %59 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 17
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %57, [0 x i256]* %0, i256* %58, i256* %59)
//CHECK-NEXT:   %60 = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %61 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 14
//CHECK-NEXT:   %62 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 22
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %60, [0 x i256]* %0, i256* %61, i256* %62)
//CHECK-NEXT:   %63 = bitcast [17 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %64 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 15
//CHECK-NEXT:   %65 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 27
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %63, [0 x i256]* %0, i256* %64, i256* %65)
//CHECK-NEXT:   br label %prologue
