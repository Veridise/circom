pragma circom 2.0.3;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function long_gt(a, b) {
    for (var i = 1; i >= 0; i--) {
        if (a[i] > b[i]) {
            return 1;
        }
        if (a[i] < b[i]) {
            return 2;
        }
    }
    return 0;
}

function long_scalar_mult() {
    return [[99, 88, 77], [66, 55, 44]];
}

template Test() {
    var norm[2][3] = long_scalar_mult();
    var out[1] = [long_gt(norm[0], norm[1])];
}

component main = Test();

// NOTE: With the constant arrays propagated through return and call,
//  the long_gt() function is totally optimized away to the value '1'.

//CHECK-LABEL: define{{.*}} void @Test_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [7 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY: 
//CHECK-NEXT: call1:
//CHECK-NEXT:   %[[ARENA:[0-9a-zA-Z_\.]+]] = alloca [12 x i256], align 8
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = bitcast [12 x i256]* %[[ARENA]] to i256*
//CHECK-NEXT:   %[[T99:[0-9a-zA-Z_\.]+]] = call i256* @long_scalar_mult_{{[0-9a-zA-Z_\.]+}}(i256* %[[T01]])
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   %[[CPY_SRC_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T99]], i32 0
//CHECK-NEXT:   %[[CPY_DST_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 0
//CHECK-NEXT:   %[[CPY_VAL_0:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_0]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_0]], i256* %[[CPY_DST_0]], align 4
//CHECK-NEXT:   %[[CPY_SRC_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T99]], i32 1
//CHECK-NEXT:   %[[CPY_DST_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 1
//CHECK-NEXT:   %[[CPY_VAL_1:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_1]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_1]], i256* %[[CPY_DST_1]], align 4
//CHECK-NEXT:   %[[CPY_SRC_2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T99]], i32 2
//CHECK-NEXT:   %[[CPY_DST_2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 2
//CHECK-NEXT:   %[[CPY_VAL_2:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_2]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_2]], i256* %[[CPY_DST_2]], align 4
//CHECK-NEXT:   %[[CPY_SRC_3:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T99]], i32 3
//CHECK-NEXT:   %[[CPY_DST_3:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 3
//CHECK-NEXT:   %[[CPY_VAL_3:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_3]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_3]], i256* %[[CPY_DST_3]], align 4
//CHECK-NEXT:   %[[CPY_SRC_4:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T99]], i32 4
//CHECK-NEXT:   %[[CPY_DST_4:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 4
//CHECK-NEXT:   %[[CPY_VAL_4:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_4]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_4]], i256* %[[CPY_DST_4]], align 4
//CHECK-NEXT:   %[[CPY_SRC_5:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T99]], i32 5
//CHECK-NEXT:   %[[CPY_DST_5:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 5
//CHECK-NEXT:   %[[CPY_VAL_5:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_5]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_5]], i256* %[[CPY_DST_5]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 1, i256* %[[T03]], align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
