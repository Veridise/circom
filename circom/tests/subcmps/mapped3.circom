pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template ArrayOp(q) {
    signal input inp[15];
    signal output outp[15];

    for (var i = 0; i < 15; i++) {
        outp[i] <== inp[i] + q;
    }
}

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

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9]+]]:
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2:[0-9]+]]:
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_3:[0-9]+]]:
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_4:[0-9]+]]:
//
//CHECK-LABEL: define{{.*}} void @ArrayOp_{{[0-9]+}}_build({ [0 x i256]*, i32 }* %0){{.*}} {
//CHECK-NEXT: main:
//CHECK-NEXT:   %[[SIGNALS:.*]] = alloca [30 x i256]
//CHECK-NEXT:   %[[COUNTER:.*]] = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 1
//CHECK-NEXT:   store i32 15, i32* %[[COUNTER]]
//
//CHECK-LABEL: define{{.*}} void @ArrayOp_
//CHECK-SAME: [[$RUN_1:[0-9]+]]_run([0 x i256]* %0){{.*}} {
//CHECK: call void @..generated..loop.body.[[$F_ID_1]](
//CHECK: call void @..generated..loop.body.[[$F_ID_1]](
//CHECK: call void @..generated..loop.body.[[$F_ID_1]](
//CHECK: call void @..generated..loop.body.[[$F_ID_1]](
//CHECK: call void @..generated..loop.body.[[$F_ID_1]](
//CHECK: call void @..generated..loop.body.[[$F_ID_1]](
//CHECK: call void @..generated..loop.body.[[$F_ID_1]](
//CHECK: call void @..generated..loop.body.[[$F_ID_1]](
//CHECK: call void @..generated..loop.body.[[$F_ID_1]](
//CHECK: call void @..generated..loop.body.[[$F_ID_1]](
//CHECK: call void @..generated..loop.body.[[$F_ID_1]](
//CHECK: call void @..generated..loop.body.[[$F_ID_1]](
//CHECK: call void @..generated..loop.body.[[$F_ID_1]](
//CHECK: call void @..generated..loop.body.[[$F_ID_1]](
//CHECK: call void @..generated..loop.body.[[$F_ID_1]](
//
//CHECK-LABEL: define{{.*}} void @ArrayOp_
//CHECK-SAME: [[$RUN_2:[0-9]+]]_run([0 x i256]* %0){{.*}} {
//CHECK: call void @..generated..loop.body.[[$F_ID_2]](
//CHECK: call void @..generated..loop.body.[[$F_ID_2]](
//CHECK: call void @..generated..loop.body.[[$F_ID_2]](
//CHECK: call void @..generated..loop.body.[[$F_ID_2]](
//CHECK: call void @..generated..loop.body.[[$F_ID_2]](
//CHECK: call void @..generated..loop.body.[[$F_ID_2]](
//CHECK: call void @..generated..loop.body.[[$F_ID_2]](
//CHECK: call void @..generated..loop.body.[[$F_ID_2]](
//CHECK: call void @..generated..loop.body.[[$F_ID_2]](
//CHECK: call void @..generated..loop.body.[[$F_ID_2]](
//CHECK: call void @..generated..loop.body.[[$F_ID_2]](
//CHECK: call void @..generated..loop.body.[[$F_ID_2]](
//CHECK: call void @..generated..loop.body.[[$F_ID_2]](
//CHECK: call void @..generated..loop.body.[[$F_ID_2]](
//CHECK: call void @..generated..loop.body.[[$F_ID_2]](
//
//CHECK-LABEL: define{{.*}} void @ArrayOp_
//CHECK-SAME: [[$RUN_3:[0-9]+]]_run([0 x i256]* %0){{.*}} {
//CHECK: call void @..generated..loop.body.[[$F_ID_3]](
//CHECK: call void @..generated..loop.body.[[$F_ID_3]](
//CHECK: call void @..generated..loop.body.[[$F_ID_3]](
//CHECK: call void @..generated..loop.body.[[$F_ID_3]](
//CHECK: call void @..generated..loop.body.[[$F_ID_3]](
//CHECK: call void @..generated..loop.body.[[$F_ID_3]](
//CHECK: call void @..generated..loop.body.[[$F_ID_3]](
//CHECK: call void @..generated..loop.body.[[$F_ID_3]](
//CHECK: call void @..generated..loop.body.[[$F_ID_3]](
//CHECK: call void @..generated..loop.body.[[$F_ID_3]](
//CHECK: call void @..generated..loop.body.[[$F_ID_3]](
//CHECK: call void @..generated..loop.body.[[$F_ID_3]](
//CHECK: call void @..generated..loop.body.[[$F_ID_3]](
//CHECK: call void @..generated..loop.body.[[$F_ID_3]](
//CHECK: call void @..generated..loop.body.[[$F_ID_3]](
//
//CHECK-LABEL: define{{.*}} void @ArrayOp_
//CHECK-SAME: [[$RUN_4:[0-9]+]]_run([0 x i256]* %0){{.*}} {
//CHECK: call void @..generated..loop.body.[[$F_ID_4]](
//CHECK: call void @..generated..loop.body.[[$F_ID_4]](
//CHECK: call void @..generated..loop.body.[[$F_ID_4]](
//CHECK: call void @..generated..loop.body.[[$F_ID_4]](
//CHECK: call void @..generated..loop.body.[[$F_ID_4]](
//CHECK: call void @..generated..loop.body.[[$F_ID_4]](
//CHECK: call void @..generated..loop.body.[[$F_ID_4]](
//CHECK: call void @..generated..loop.body.[[$F_ID_4]](
//CHECK: call void @..generated..loop.body.[[$F_ID_4]](
//CHECK: call void @..generated..loop.body.[[$F_ID_4]](
//CHECK: call void @..generated..loop.body.[[$F_ID_4]](
//CHECK: call void @..generated..loop.body.[[$F_ID_4]](
//CHECK: call void @..generated..loop.body.[[$F_ID_4]](
//CHECK: call void @..generated..loop.body.[[$F_ID_4]](
//CHECK: call void @..generated..loop.body.[[$F_ID_4]](
//
//CHECK-LABEL: define{{.*}} void @Wrapper_{{[0-9]+}}_build({ [0 x i256]*, i32 }* %0){{.*}} {
//CHECK-NEXT: main:
//CHECK-NEXT:   %[[SIGNALS:.*]] = alloca [16 x i256]
//CHECK-NEXT:   %[[COUNTER:.*]] = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 1
//CHECK-NEXT:   store i32 15, i32* %{{.*}}[[COUNTER]]
//
//CHECK-LABEL: define{{.*}} void @Wrapper_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK: %lvars = alloca [2 x i256]
//CHECK: unrolled_loop{{[0-9]+}}:
//CHECK: call void @ArrayOp_[[$RUN_1]]_run([0 x i256]* %
//CHECK: call void @ArrayOp_[[$RUN_2]]_run([0 x i256]* %
//CHECK: call void @ArrayOp_[[$RUN_3]]_run([0 x i256]* %
//CHECK: call void @ArrayOp_[[$RUN_4]]_run([0 x i256]* %
//COM: offset = (1 * (3 * 7)) + (2 * (7)) + (3) + 1 (since 0 is output) = 21 + 14 + 3 + 1 = 39
//CHECK: store{{[0-9]+}}:{{ +}}; preds = %unrolled_loop{{[0-9]+}}
//CHECK-NEXT: %[[SUB_PTR:.*]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT: %[[SUBCMP:.*]] = load [0 x i256]*, [0 x i256]** %[[SUB_PTR]]
//CHECK-NEXT: %[[VAL_PTR:.*]] = getelementptr [0 x i256], [0 x i256]* %[[SUBCMP]], i32 0, i32 3
//CHECK-NEXT: %[[VAL:.*]] = load i256, i256* %[[VAL_PTR]]
//CHECK-NEXT: %[[OUTP_PTR:.*]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT: store i256 %[[VAL]], i256* %[[OUTP_PTR]]
