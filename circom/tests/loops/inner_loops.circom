pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s

template InnerLoops(n) {
    signal input a[n];
    var b[n];

    for (var i = 0; i < n; i++) {
        for (var j = 0; j <= i; j++) {
            b[i] += a[i - j];
        }
    }
}

component main = InnerLoops(2);
//
//ARG = { a[0], a[1] }
//lvars = { n, b[0], b[1], i, j }
//unrolled code:
//	b[0] = b[0] + a[0 - 0 = 0];
//	b[1] = b[1] + a[1 - 0 = 1];
//	b[1] = b[1] + a[1 - 1 = 0];
//
//
//CHECK-LABEL: define void @InnerLoops_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9]+]])
//// Use the block labels to check that the loop is unrolled and check the unrolled body
//CHECK-NOT: loop.cond{{.*}}:
//CHECK-NOT: loop.body{{.*}}:
//CHECK-NOT: loop.end{{.*}}:
//CHECK:      unrolled_loop{{.*}}:
//				// j = 0
//CHECK-NEXT:   %[[T01:[[:alnum:]_.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %{{.*}}[[T01]], align 4
//				// b[0] = b[0] + a[0]
//CHECK-NEXT:   %[[T02:[[:alnum:]_.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T03:[[:alnum:]_.]+]] = load i256, i256* %{{.*}}[[T02]], align 4
//CHECK-NEXT:   %[[T04:[[:alnum:]_.]+]] = getelementptr [0 x i256], [0 x i256]* %{{.*}}[[ARG]], i32 0, i32 0
//CHECK-NEXT:   %[[T05:[[:alnum:]_.]+]] = load i256, i256* %{{.*}}[[T04]], align 4
//CHECK-NEXT:   %[[T06:[[:alnum:]_.]+]] = call i256 @fr_add(i256 %{{.*}}[[T03]], i256 %{{.*}}[[T05]])
//CHECK-NEXT:   %[[T07:[[:alnum:]_.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 %{{.*}}[[T06]], i256* %{{.*}}[[T07]], align 4
//				// j = 1
//CHECK-NEXT:   %[[T08:[[:alnum:]_.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %{{.*}}[[T08]], align 4
//				// i = 1
//CHECK-NEXT:   %[[T09:[[:alnum:]_.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 1, i256* %{{.*}}[[T09]], align 4
//				// j = 0
//CHECK-NEXT:   %[[T10:[[:alnum:]_.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %{{.*}}[[T10]], align 4
//				// b[1] = b[1] + a[1]
//CHECK-NEXT:   %[[T11:[[:alnum:]_.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[T12:[[:alnum:]_.]+]] = load i256, i256* %{{.*}}[[T11]], align 4
//CHECK-NEXT:   %[[T13:[[:alnum:]_.]+]] = getelementptr [0 x i256], [0 x i256]* %{{.*}}[[ARG]], i32 0, i32 1
//CHECK-NEXT:   %[[T14:[[:alnum:]_.]+]] = load i256, i256* %{{.*}}[[T13]], align 4
//CHECK-NEXT:   %[[T15:[[:alnum:]_.]+]] = call i256 @fr_add(i256 %{{.*}}[[T12]], i256 %{{.*}}[[T14]])
//CHECK-NEXT:   %[[T16:[[:alnum:]_.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 %{{.*}}[[T15]], i256* %{{.*}}[[T16]], align 4
//				// j = 1
//CHECK-NEXT:   %[[T17:[[:alnum:]_.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %{{.*}}[[T17]], align 4
//				// b[1] = b[1] + a[0]
//CHECK-NEXT:   %[[T18:[[:alnum:]_.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[T19:[[:alnum:]_.]+]] = load i256, i256* %{{.*}}[[T18]], align 4
//CHECK-NEXT:   %[[T20:[[:alnum:]_.]+]] = getelementptr [0 x i256], [0 x i256]* %{{.*}}[[ARG]], i32 0, i32 0
//CHECK-NEXT:   %[[T21:[[:alnum:]_.]+]] = load i256, i256* %{{.*}}[[T20]], align 4
//CHECK-NEXT:   %[[T22:[[:alnum:]_.]+]] = call i256 @fr_add(i256 %{{.*}}[[T19]], i256 %{{.*}}[[T21]])
//CHECK-NEXT:   %[[T23:[[:alnum:]_.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 %{{.*}}[[T22]], i256* %{{.*}}[[T23]], align 4
//				// j = 2
//CHECK-NEXT:   %[[T24:[[:alnum:]_.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %{{.*}}[[T24]], align 4
//				// i = 2
//CHECK-NEXT:   %[[T25:[[:alnum:]_.]+]] = getelementptr [5 x i256], [5 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 2, i256* %{{.*}}[[T25]], align 4
//CHECK-NOT: loop.cond{{.*}}:
//CHECK-NOT: loop.body{{.*}}:
//CHECK-NOT: loop.end{{.*}}:
//CHECK:   }
