pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// Scalar copy version of `array_copy1_vec.circom` test. Output is identical except for basic blocks.
template Array1(n, S) {
    signal output out[n];

    for (var i = 0; i < n; i++) {
      out[i] <== S[i];
    }
}

component main = Array1(5, [11,22,33,44,55]);

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9a-zA-Z_\.]+}}([0 x i256]* %lvars, [0 x i256]* %signals, 
//CHECK-SAME: i256* %sig_[[X1:[0-9]+]], i256* %var_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2:[0-9a-zA-Z_\.]+]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_[[X1]], i32 0
//CHECK-NEXT:   %[[T1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_[[X2]], i32 0
//CHECK-NEXT:   %[[T2:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T1]], align 4
//CHECK-NEXT:   store i256 %[[T2]], i256* %[[T0]], align 4
//CHECK-NEXT:   %[[T3:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T0]], align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T2]], i256 %[[T3]], i1* %constraint)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T4:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %[[T5:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %[[T6:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T5]], align 4
//CHECK-NEXT:   %[[C1:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T6]], i256 1)
//CHECK-NEXT:   store i256 %[[C1]], i256* %[[T4]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY:
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..array.param.{{[0-9a-zA-Z_\.]+}}([0 x i256]* %lvars){{.*}} {
//CHECK-NEXT: ..generated..array.param.[[$F_ID_1:[0-9a-zA-Z_\.]+]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY:
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 11, i256* %[[T00]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY:
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 22, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY:
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 33, i256* %[[T02]], align 4
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY:
//CHECK-NEXT: store4:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 44, i256* %[[T03]], align 4
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY:
//CHECK-NEXT: store5:
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 55, i256* %[[T04]], align 4
//CHECK-NEXT:   br label %return6
//CHECK-EMPTY:
//CHECK-NEXT: return6:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @Array1_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9a-zA-Z_\.]+]]){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [7 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK:        %[[T01:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..array.param.[[$F_ID_1]]([0 x i256]* %[[T01]])
//CHECK:        %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 5, i256* %[[T02]], align 4
//CHECK:        %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 0, i256* %[[T03]], align 4
//CHECK:        %[[T04:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 0
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T06]], i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T04]], [0 x i256]* %[[ARG]], i256* %[[T05]], i256* %[[T07]])
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 1
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T10]], i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T08]], [0 x i256]* %[[ARG]], i256* %[[T09]], i256* %[[T11]])
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 2
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T14]], i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T12]], [0 x i256]* %[[ARG]], i256* %[[T13]], i256* %[[T15]])
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T17:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 3
//CHECK-NEXT:   %[[T18:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T19:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T18]], i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T16]], [0 x i256]* %[[ARG]], i256* %[[T17]], i256* %[[T19]])
//CHECK-NEXT:   %[[T20:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T21:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 4
//CHECK-NEXT:   %[[T22:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T23:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T22]], i32 0, i256 4
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T20]], [0 x i256]* %[[ARG]], i256* %[[T21]], i256* %[[T23]])
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY:
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
