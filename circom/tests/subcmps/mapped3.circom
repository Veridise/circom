pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s

template ArrayOp(q) {
    signal input inp[15];
    signal output outp[15];

    for (var i = 0; i < 15; i++) {
        outp[i] <== inp[i] + q;
    }
}

//CHECK-LABEL: define void @ArrayOp_{{[0-9]+}}_build
//CHECK-SAME: ({ [0 x i256]*, i32 }* %{{.*}})
//CHECK: alloca [30 x i256]
//CHECK: %[[DIM_REG:.*]] = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 1
//CHECK: store i32 15, i32* %{{.*}}[[DIM_REG]]

template Wrapper() {
    signal input inp[15];
    signal output outp;

    component m[4];

    for (var q = 0; q < 4; q++) {
        // This test exhibits the behavior because the array of different subcomponents
        // (differentiated by the template parameter changing)
        m[q] = ArrayOp(q);
        for (var i = 0; i < 15; i++) {
            m[q].inp[i] <== inp[i];
        }
    }

    outp <== m[2].outp[3];
}

component main = Wrapper();

//CHECK-LABEL: define void @Wrapper_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %{{.*}})
//CHECK: %lvars = alloca [2 x i256]
//COM: offset = (1 * (3 * 7)) + (2 * (7)) + (3) + 1 (since 0 is output) = 21 + 14 + 3 + 1 = 39
//CHECK: store{{.*}}:{{.*}}; preds = %unrolled_loop{{.*}}
//CHECK: %[[SUB_PTR:.*]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK: %[[SUBCMP:.*]] = load [0 x i256]*, [0 x i256]** %[[SUB_PTR]]
//CHECK: %[[VAL_PTR:.*]] = getelementptr [0 x i256], [0 x i256]* %[[SUBCMP]], i32 0, i32 3
//CHECK: %[[VAL:.*]] = load i256, i256* %[[VAL_PTR]]
//CHECK: %[[OUTP_PTR:.*]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK: store i256 %[[VAL]], i256* %[[OUTP_PTR]]
