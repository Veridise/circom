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

//CHECK-LABEL: define void @InnerLoops_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9]+]])
//CHECK: unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %[[T06:[[:alnum:]_.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 0, i256* %{{.*}}[[T06]], align 4
//CHECK-NEXT:   %[[T07:[[:alnum:]_.]+]] = getelementptr [0 x i256], [0 x i256]* %{{.*}}[[ARG]], i32 0, i32 1
//CHECK-NEXT:   %[[T08:[[:alnum:]_.]+]] = load i256, i256* %{{.*}}[[T07]], align 4
//CHECK-NEXT:   %[[T09:[[:alnum:]_.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 %{{.*}}[[T08]], i256* %{{.*}}[[T09]], align 4
//CHECK-NEXT:   %[[T10:[[:alnum:]_.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 1, i256* %{{.*}}[[T10]], align 4
//CHECK-NEXT:   %[[T11:[[:alnum:]_.]+]] = getelementptr [0 x i256], [0 x i256]* %{{.*}}[[ARG]], i32 0, i32 2
//CHECK-NEXT:   %[[T12:[[:alnum:]_.]+]] = load i256, i256* %{{.*}}[[T11]], align 4
//CHECK-NEXT:   %[[T13:[[:alnum:]_.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 %{{.*}}[[T12]], i256* %{{.*}}[[T13]], align 4
//CHECK-NEXT:   %[[T14:[[:alnum:]_.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 2, i256* %{{.*}}[[T14]], align 4
//CHECK-NEXT:   %[[T15:[[:alnum:]_.]+]] = getelementptr [0 x i256], [0 x i256]* %{{.*}}[[ARG]], i32 0, i32 3
//CHECK-NEXT:   %[[T16:[[:alnum:]_.]+]] = load i256, i256* %{{.*}}[[T15]], align 4
//CHECK-NEXT:   %[[T17:[[:alnum:]_.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 %{{.*}}[[T16]], i256* %{{.*}}[[T17]], align 4
//CHECK-NEXT:   %[[T18:[[:alnum:]_.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 3, i256* %{{.*}}[[T18]], align 4
//CHECK-NEXT:   %[[T19:[[:alnum:]_.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %{{.*}}[[T19]], align 4
//CHECK-NEXT:   %[[T20:[[:alnum:]_.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 0, i256* %{{.*}}[[T20]], align 4
//CHECK-NEXT:   %[[T21:[[:alnum:]_.]+]] = getelementptr [0 x i256], [0 x i256]* %{{.*}}[[ARG]], i32 0, i32 1
//CHECK-NEXT:   %[[T22:[[:alnum:]_.]+]] = load i256, i256* %{{.*}}[[T21]], align 4
//CHECK-NEXT:   %[[T23:[[:alnum:]_.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 %{{.*}}[[T22]], i256* %{{.*}}[[T23]], align 4
//CHECK-NEXT:   %[[T24:[[:alnum:]_.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 1, i256* %{{.*}}[[T24]], align 4
//CHECK-NEXT:   %[[T25:[[:alnum:]_.]+]] = getelementptr [0 x i256], [0 x i256]* %{{.*}}[[ARG]], i32 0, i32 2
//CHECK-NEXT:   %[[T26:[[:alnum:]_.]+]] = load i256, i256* %{{.*}}[[T25]], align 4
//CHECK-NEXT:   %[[T27:[[:alnum:]_.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 %{{.*}}[[T26]], i256* %{{.*}}[[T27]], align 4
//CHECK-NEXT:   %[[T28:[[:alnum:]_.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 2, i256* %{{.*}}[[T28]], align 4
//CHECK-NEXT:   %[[T29:[[:alnum:]_.]+]] = getelementptr [0 x i256], [0 x i256]* %{{.*}}[[ARG]], i32 0, i32 3
//CHECK-NEXT:   %[[T30:[[:alnum:]_.]+]] = load i256, i256* %{{.*}}[[T29]], align 4
//CHECK-NEXT:   %[[T31:[[:alnum:]_.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 %{{.*}}[[T30]], i256* %{{.*}}[[T31]], align 4
//CHECK-NEXT:   %[[T32:[[:alnum:]_.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 3, i256* %{{.*}}[[T32]], align 4
//CHECK-NEXT:   %[[T33:[[:alnum:]_.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %{{.*}}[[T33]], align 4
//CHECK-NEXT:   br label %store[[LBL:[0-9]+]]
//CHECK-EMPTY:
//CHECK-NEXT: store{{.*}}[[LBL]]:
//CHECK-NEXT:   %[[T34:[[:alnum:]_.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[T35:[[:alnum:]_.]+]] = load i256, i256* %{{.*}}[[T34]], align 4
//CHECK-NEXT:   %[[T36:[[:alnum:]_.]+]] = getelementptr [0 x i256], [0 x i256]* %{{.*}}[[ARG]], i32 0, i32 0
//CHECK-NEXT:   store i256 %{{.*}}[[T35]], i256* %{{.*}}[[T36]], align 4
//CHECK:   }
