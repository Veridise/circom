pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*     // TEMPORARY: because EXTRACT_LOOP_BODY_TO_NEW_FUNC == false

template InnerConditional7(N) {
    signal output out;

    var a[N];
    for (var i = 0; i < N; i++) {
        // NOTE: When processing the outer loop, the statements indexed with 'j' are determined
        //  NOT safe to move into a new function since 'j' is unknown. That results in the outer
        //  loop unrolling without extrating the body to a new function. Then the three copies
        //  of the inner loop are processed and their bodies are extracted to new functions and
        //  replaced with calls to those functions before unrolling. So it ends up creating
        //  three slightly different functions for this innermost body, one for each iteration
        //  of the outer loop. Within each of those functions, 'i' is a known fixed value.
        for (var j = 0; j < N; j++) {
            if (i > 1) {
                a[j] += 999;
            } else {
                a[j] -= 111;
            }
        }
    }

    out <-- a[0] + a[1];
}

component main = InnerConditional7(3);

//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %branch1
//CHECK-EMPTY: 
//CHECK-NEXT: branch1:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %call.fr_gt = call i1 @fr_gt(i256 %1, i256 1)
//CHECK-NEXT:   br i1 %call.fr_gt, label %if.then, label %if.else
//CHECK-EMPTY: 
//CHECK-NEXT: if.then:
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %call.fr_cast_to_addr = call i32 @fr_cast_to_addr(i256 %3)
//CHECK-NEXT:   %mul_addr = mul i32 1, %call.fr_cast_to_addr
//CHECK-NEXT:   %add_addr = add i32 %mul_addr, 1
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 %add_addr
//CHECK-NEXT:   store i256 777, i256* %4, align 4
//CHECK-NEXT:   br label %if.merge
//CHECK-EMPTY: 
//CHECK-NEXT: if.else:
//CHECK-NEXT:   %5 = getelementptr i256, i256* %fix_[[X2]], i32 0
//CHECK-NEXT:   %6 = load i256, i256* %5, align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %6, i256 111)
//CHECK-NEXT:   %7 = getelementptr i256, i256* %fix_[[X1]], i32 0
//CHECK-NEXT:   store i256 %call.fr_sub, i256* %7, align 4
//CHECK-NEXT:   br label %if.merge
//CHECK-EMPTY: 
//CHECK-NEXT: if.merge:
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %9 = load i256, i256* %8, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %9, i256 1)
//CHECK-NEXT:   %10 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 %call.fr_add, i256* %10, align 4
//CHECK-NEXT:   br label %return6
//CHECK-EMPTY: 
//CHECK-NEXT: return6:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_2:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2]]:
//CHECK-NEXT:   br label %branch1
//CHECK-EMPTY: 
//CHECK-NEXT: branch1:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %call.fr_gt = call i1 @fr_gt(i256 %1, i256 1)
//CHECK-NEXT:   br i1 %call.fr_gt, label %if.then, label %if.else
//CHECK-EMPTY: 
//CHECK-NEXT: if.then:
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %call.fr_cast_to_addr = call i32 @fr_cast_to_addr(i256 %3)
//CHECK-NEXT:   %mul_addr = mul i32 1, %call.fr_cast_to_addr
//CHECK-NEXT:   %add_addr = add i32 %mul_addr, 1
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 %add_addr
//CHECK-NEXT:   store i256 777, i256* %4, align 4
//CHECK-NEXT:   br label %if.merge
//CHECK-EMPTY: 
//CHECK-NEXT: if.else:
//CHECK-NEXT:   %5 = getelementptr i256, i256* %fix_[[X2]], i32 0
//CHECK-NEXT:   %6 = load i256, i256* %5, align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %6, i256 111)
//CHECK-NEXT:   %7 = getelementptr i256, i256* %fix_[[X1]], i32 0
//CHECK-NEXT:   store i256 %call.fr_sub, i256* %7, align 4
//CHECK-NEXT:   br label %if.merge
//CHECK-EMPTY: 
//CHECK-NEXT: if.merge:
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %9 = load i256, i256* %8, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %9, i256 1)
//CHECK-NEXT:   %10 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 %call.fr_add, i256* %10, align 4
//CHECK-NEXT:   br label %return6
//CHECK-EMPTY: 
//CHECK-NEXT: return6:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_3:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %fix_[[X1:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_3]]:
//CHECK-NEXT:   br label %branch1
//CHECK-EMPTY: 
//CHECK-NEXT: branch1:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %call.fr_gt = call i1 @fr_gt(i256 %1, i256 1)
//CHECK-NEXT:   br i1 %call.fr_gt, label %if.then, label %if.else
//CHECK-EMPTY: 
//CHECK-NEXT: if.then:
//CHECK-NEXT:   %2 = getelementptr i256, i256* %fix_[[X1]], i32 0
//CHECK-NEXT:   store i256 777, i256* %2, align 4
//CHECK-NEXT:   br label %if.merge
//CHECK-EMPTY: 
//CHECK-NEXT: if.else:
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %4 = load i256, i256* %3, align 4
//CHECK-NEXT:   %call.fr_cast_to_addr = call i32 @fr_cast_to_addr(i256 %4)
//CHECK-NEXT:   %mul_addr = mul i32 1, %call.fr_cast_to_addr
//CHECK-NEXT:   %add_addr = add i32 %mul_addr, 1
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %6 = load i256, i256* %5, align 4
//CHECK-NEXT:   %call.fr_cast_to_addr1 = call i32 @fr_cast_to_addr(i256 %6)
//CHECK-NEXT:   %mul_addr2 = mul i32 1, %call.fr_cast_to_addr1
//CHECK-NEXT:   %add_addr3 = add i32 %mul_addr2, 1
//CHECK-NEXT:   %7 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 %add_addr3
//CHECK-NEXT:   %8 = load i256, i256* %7, align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %8, i256 111)
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 %add_addr
//CHECK-NEXT:   store i256 %call.fr_sub, i256* %9, align 4
//CHECK-NEXT:   br label %if.merge
//CHECK-EMPTY: 
//CHECK-NEXT: if.merge:
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %10 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %11 = load i256, i256* %10, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %11, i256 1)
//CHECK-NEXT:   %12 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 %call.fr_add, i256* %12, align 4
//CHECK-NEXT:   br label %return6
//CHECK-EMPTY: 
//CHECK-NEXT: return6:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @InnerConditional7_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [6 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 3, i256* %1, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %2 = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %2, align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %3 = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 0, i256* %3, align 4
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %4 = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 0, i256* %4, align 4
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %5 = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %5, align 4
//CHECK-NEXT:   br label %unrolled_loop6
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop6:
//CHECK-NEXT:   %6 = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 0, i256* %6, align 4
//CHECK-NEXT:   %7 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %8 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %8, i32 0, i256 1
//CHECK-NEXT:   %10 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %10, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %7, [0 x i256]* %0, i256* %9, i256* %11)
//CHECK-NEXT:   %12 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %13 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %14 = getelementptr [0 x i256], [0 x i256]* %13, i32 0, i256 2
//CHECK-NEXT:   %15 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %16 = getelementptr [0 x i256], [0 x i256]* %15, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %12, [0 x i256]* %0, i256* %14, i256* %16)
//CHECK-NEXT:   %17 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %18 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %19 = getelementptr [0 x i256], [0 x i256]* %18, i32 0, i256 3
//CHECK-NEXT:   %20 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %21 = getelementptr [0 x i256], [0 x i256]* %20, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %17, [0 x i256]* %0, i256* %19, i256* %21)
//CHECK-NEXT:   %22 = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %22, align 4
//CHECK-NEXT:   %23 = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 0, i256* %23, align 4
//CHECK-NEXT:   %24 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %25 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %26 = getelementptr [0 x i256], [0 x i256]* %25, i32 0, i256 1
//CHECK-NEXT:   %27 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %28 = getelementptr [0 x i256], [0 x i256]* %27, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %24, [0 x i256]* %0, i256* %26, i256* %28)
//CHECK-NEXT:   %29 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %30 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %31 = getelementptr [0 x i256], [0 x i256]* %30, i32 0, i256 2
//CHECK-NEXT:   %32 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %33 = getelementptr [0 x i256], [0 x i256]* %32, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %29, [0 x i256]* %0, i256* %31, i256* %33)
//CHECK-NEXT:   %34 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %35 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %36 = getelementptr [0 x i256], [0 x i256]* %35, i32 0, i256 3
//CHECK-NEXT:   %37 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %38 = getelementptr [0 x i256], [0 x i256]* %37, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %34, [0 x i256]* %0, i256* %36, i256* %38)
//CHECK-NEXT:   %39 = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %39, align 4
//CHECK-NEXT:   %40 = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 0, i256* %40, align 4
//CHECK-NEXT:   %41 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %42 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %43 = getelementptr [0 x i256], [0 x i256]* %42, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_3]]([0 x i256]* %41, [0 x i256]* %0, i256* %43)
//CHECK-NEXT:   %44 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %45 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %46 = getelementptr [0 x i256], [0 x i256]* %45, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_3]]([0 x i256]* %44, [0 x i256]* %0, i256* %46)
//CHECK-NEXT:   %47 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %48 = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %49 = getelementptr [0 x i256], [0 x i256]* %48, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_3]]([0 x i256]* %47, [0 x i256]* %0, i256* %49)
//CHECK-NEXT:   %50 = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 3, i256* %50, align 4
//CHECK-NEXT:   br label %store7
//CHECK-EMPTY: 
//CHECK-NEXT: store7:
//CHECK-NEXT:   %51 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 1554, i256* %51, align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
