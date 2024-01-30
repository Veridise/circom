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
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %sig_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T00]], align 4
//CHECK-NEXT:   %[[C01:[0-9a-zA-Z_.]+]] = call i32 @fr_cast_to_addr(i256 %[[T01]])
//CHECK-NEXT:   %[[A01:[0-9a-zA-Z_.]+]] = mul i32 1, %[[C01]]
//CHECK-NEXT:   %[[A02:[0-9a-zA-Z_.]+]] = add i32 %[[A01]], 2
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %sig_0, i32 0
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T02]], align 4
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 %[[A02]]
//CHECK-NEXT:   store i256 %[[T03]], i256* %[[T04]], align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T05]], align 4
//CHECK-NEXT:   %[[C02:[0-9a-zA-Z_.]+]] = call i256 @fr_add(i256 %[[T06]], i256 1)
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 %[[C02]], i256* %[[T07]], align 4
//CHECK-NEXT:   br label %return{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: return{{[0-9]+}}:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @InnerLoops_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK:      unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 0, i256* %[[T06]], align 4
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T07]], [0 x i256]* %0, i256* %[[T08]])
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T09]], [0 x i256]* %0, i256* %[[T10]])
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T11]], [0 x i256]* %0, i256* %[[T12]])
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %[[T13]], align 4
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 0, i256* %[[T14]], align 4
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T15]], [0 x i256]* %0, i256* %[[T16]])
//CHECK-NEXT:   %[[T17:[0-9a-zA-Z_.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T18:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T17]], [0 x i256]* %0, i256* %[[T18]])
//CHECK-NEXT:   %[[T19:[0-9a-zA-Z_.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T20:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T19]], [0 x i256]* %0, i256* %[[T20]])
//CHECK-NEXT:   %[[T21:[0-9a-zA-Z_.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %[[T21]], align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %[[T22:[0-9a-zA-Z_.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[T23:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T22]], align 4
//CHECK-NEXT:   %[[T24:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %[[T23]], i256* %[[T24]], align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
