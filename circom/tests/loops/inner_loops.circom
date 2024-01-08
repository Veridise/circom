pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template InnerLoops(n) {
    signal input a[n];
    var b[n];

    for (var i = 0; i < n; i++) {
        for (var j = 0; j <= i; j++) {
            // NOTE: When processing the outer loop, the following statement is determined NOT
            //  safe to move into a new function since it uses 'j' which is unknown. That results
            //  in the outer loop unrolling without extrating the body to a new function. Then
            //  the two copies of the inner loop are processed and their bodies are extracted to
            //  new functions and replaced with calls to those functions before unrolling. So
            //  it ends up creating two slightly different functions for this innermost body,
            //  one for each iteration of the outer loop (i.e. when b=0 and when b=1).
            b[i] += a[i - j];
        }
    }
}

component main = InnerLoops(2);
//
// %0 (i.e. signal arena) = { a[0], a[1] }
// %lvars = { n, b[0], b[1], i, j }
//
//unrolled code:
//	b[0] = b[0] + a[0 - 0 = 0];     //extracted function 1
//	b[1] = b[1] + a[1 - 0 = 1];     //extracted function 2
//	b[1] = b[1] + a[1 - 1 = 0];     //extracted function 2
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T00]], align 4
//CHECK-NEXT:   %[[C01:[0-9a-zA-Z_.]+]] = call i32 @fr_cast_to_addr(i256 %[[T01]])
//CHECK-NEXT:   %[[A01:[0-9a-zA-Z_.]+]] = mul i32 1, %[[C01]]
//CHECK-NEXT:   %[[A02:[0-9a-zA-Z_.]+]] = add i32 %[[A01]], 1
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T02]], align 4
//CHECK-NEXT:   %[[C02:[0-9a-zA-Z_.]+]] = call i32 @fr_cast_to_addr(i256 %[[T03]])
//CHECK-NEXT:   %mul_addr2 = mul i32 1, %[[C02]]
//CHECK-NEXT:   %add_addr3 = add i32 %mul_addr2, 1
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 %add_addr3
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T04]], align 4
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T06]], align 4
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T08]], align 4
//CHECK-NEXT:   %[[C03:[0-9a-zA-Z_.]+]] = call i256 @fr_sub(i256 %[[T07]], i256 %[[T09]])
//CHECK-NEXT:   %[[C04:[0-9a-zA-Z_.]+]] = call i32 @fr_cast_to_addr(i256 %[[C03]])
//CHECK-NEXT:   %mul_addr5 = mul i32 1, %[[C04]]
//CHECK-NEXT:   %add_addr6 = add i32 %mul_addr5, 0
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 %add_addr6
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T10]], align 4
//CHECK-NEXT:   %[[C05:[0-9a-zA-Z_.]+]] = call i256 @fr_add(i256 %[[T05]], i256 %[[T11]])
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 %[[A02]]
//CHECK-NEXT:   store i256 %[[C05]], i256* %[[T12]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T13]], align 4
//CHECK-NEXT:   %[[C06:[0-9a-zA-Z_.]+]] = call i256 @fr_add(i256 %[[T14]], i256 1)
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 %[[C06]], i256* %[[T15]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
// 
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_2:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %fix_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T00]], align 4
//CHECK-NEXT:   %[[C01:[0-9a-zA-Z_.]+]] = call i32 @fr_cast_to_addr(i256 %[[T01]])
//CHECK-NEXT:   %[[A01:[0-9a-zA-Z_.]+]] = mul i32 1, %[[C01]]
//CHECK-NEXT:   %[[A02:[0-9a-zA-Z_.]+]] = add i32 %[[A01]], 1
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T02]], align 4
//CHECK-NEXT:   %[[C01:[0-9a-zA-Z_.]+]] = call i32 @fr_cast_to_addr(i256 %[[T03]])
//CHECK-NEXT:   %[[A03:[0-9a-zA-Z_.]+]] = mul i32 1, %[[C01]]
//CHECK-NEXT:   %[[A04:[0-9a-zA-Z_.]+]] = add i32 %[[A03]], 1
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 %[[A04]]
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T04]], align 4
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %fix_0, i32 0
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T06]], align 4
//CHECK-NEXT:   %[[C02:[0-9a-zA-Z_.]+]] = call i256 @fr_add(i256 %[[T05]], i256 %[[T07]])
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 %[[A02]]
//CHECK-NEXT:   store i256 %[[C02]], i256* %[[T08]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T09]], align 4
//CHECK-NEXT:   %[[C03:[0-9a-zA-Z_.]+]] = call i256 @fr_add(i256 %[[T10]], i256 1)
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 %[[C03]], i256* %[[T11]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @InnerLoops_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK:      unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %[[T05]], align 4
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = bitcast [5 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T06]], [0 x i256]* %0)
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 1, i256* %[[T07]], align 4
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %[[T08]], align 4
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_.]+]] = bitcast [5 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T09]], [0 x i256]* %0, i256* %[[T10]])
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_.]+]] = bitcast [5 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T11]], [0 x i256]* %0, i256* %[[T12]])
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 2, i256* %[[T13]], align 4
//CHECK-NEXT:   br label %prologue
