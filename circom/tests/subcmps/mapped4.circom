pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template MatrixOp(q) {
    signal input inp[5][3];
    signal output outp[5][3];

    for (var i = 0; i < 5; i++) {
        for (var j = 0; j < 3; j++) {
            outp[i][j] <== inp[i][j] + q;
        }
    }
}

template Wrapper() {
    signal input inp[5][3];
    signal output outp;

    component m[4];

    for (var q = 0; q < 4; q++) {
        // This test exhibits the behavior because the array of different subcomponents
        // (differentiated by the template parameter changing)
        m[q] = MatrixOp(q);
        for (var i = 0; i < 5; i++) {
            for (var j = 0; j < 3; j++) {
                m[q].inp[i][j] <== inp[i][j];
            }
        }
    }

    outp <== m[2].outp[1][2];
}

component main = Wrapper();

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_01:[0-9]+]]:
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_02:[0-9]+]]:
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_03:[0-9]+]]:
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_04:[0-9]+]]:
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_05:[0-9]+]]:
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_06:[0-9]+]]:
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_07:[0-9]+]]:
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_08:[0-9]+]]:
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_09:[0-9]+]]:
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_10:[0-9]+]]:
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_11:[0-9]+]]:
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_12:[0-9]+]]:
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_13:[0-9]+]]:
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_14:[0-9]+]]:
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_15:[0-9]+]]:
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_16:[0-9]+]]:
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_17:[0-9]+]]:
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_18:[0-9]+]]:
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_19:[0-9]+]]:
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %fix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_20:[0-9]+]]:
//
//CHECK-LABEL: define{{.*}} void @MatrixOp_{{[0-9]+}}_build({ [0 x i256]*, i32 }* %0){{.*}} {
//CHECK-NEXT: main:
//CHECK-NEXT:   %[[SIGNALS:.*]] = alloca [30 x i256]
//CHECK-NEXT:   %[[COUNTER:.*]] = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 1
//CHECK-NEXT:   store i32 15, i32* %[[COUNTER]]
//
//CHECK-LABEL: define{{.*}} void @MatrixOp_
//CHECK-SAME: [[$RUN_1:[0-9]+]]_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [3 x i256]
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }]
//CHECK: call void @..generated..loop.body.[[$F_ID_01]](
//CHECK: call void @..generated..loop.body.[[$F_ID_01]](
//CHECK: call void @..generated..loop.body.[[$F_ID_01]](
//CHECK: call void @..generated..loop.body.[[$F_ID_02]](
//CHECK: call void @..generated..loop.body.[[$F_ID_02]](
//CHECK: call void @..generated..loop.body.[[$F_ID_02]](
//CHECK: call void @..generated..loop.body.[[$F_ID_03]](
//CHECK: call void @..generated..loop.body.[[$F_ID_03]](
//CHECK: call void @..generated..loop.body.[[$F_ID_03]](
//CHECK: call void @..generated..loop.body.[[$F_ID_04]](
//CHECK: call void @..generated..loop.body.[[$F_ID_04]](
//CHECK: call void @..generated..loop.body.[[$F_ID_04]](
//CHECK: call void @..generated..loop.body.[[$F_ID_05]](
//CHECK: call void @..generated..loop.body.[[$F_ID_05]](
//CHECK: call void @..generated..loop.body.[[$F_ID_05]](
//
//CHECK-LABEL: define{{.*}} void @MatrixOp_{{[0-9]+}}_build({ [0 x i256]*, i32 }* %0){{.*}} {
//CHECK-NEXT: main:
//CHECK-NEXT:   %[[SIGNALS:.*]] = alloca [30 x i256]
//CHECK-NEXT:   %[[COUNTER:.*]] = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 1
//CHECK-NEXT:   store i32 15, i32* %[[COUNTER]]
//
//CHECK-LABEL: define{{.*}} void @MatrixOp_
//CHECK-SAME: [[$RUN_2:[0-9]+]]_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [3 x i256]
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }]
//CHECK: call void @..generated..loop.body.[[$F_ID_06]](
//CHECK: call void @..generated..loop.body.[[$F_ID_06]](
//CHECK: call void @..generated..loop.body.[[$F_ID_06]](
//CHECK: call void @..generated..loop.body.[[$F_ID_07]](
//CHECK: call void @..generated..loop.body.[[$F_ID_07]](
//CHECK: call void @..generated..loop.body.[[$F_ID_07]](
//CHECK: call void @..generated..loop.body.[[$F_ID_08]](
//CHECK: call void @..generated..loop.body.[[$F_ID_08]](
//CHECK: call void @..generated..loop.body.[[$F_ID_08]](
//CHECK: call void @..generated..loop.body.[[$F_ID_09]](
//CHECK: call void @..generated..loop.body.[[$F_ID_09]](
//CHECK: call void @..generated..loop.body.[[$F_ID_09]](
//CHECK: call void @..generated..loop.body.[[$F_ID_10]](
//CHECK: call void @..generated..loop.body.[[$F_ID_10]](
//CHECK: call void @..generated..loop.body.[[$F_ID_10]](
//
//CHECK-LABEL: define{{.*}} void @MatrixOp_{{[0-9]+}}_build({ [0 x i256]*, i32 }* %0){{.*}} {
//CHECK-NEXT: main:
//CHECK-NEXT:   %[[SIGNALS:.*]] = alloca [30 x i256]
//CHECK-NEXT:   %[[COUNTER:.*]] = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 1
//CHECK-NEXT:   store i32 15, i32* %[[COUNTER]]
//
//CHECK-LABEL: define{{.*}} void @MatrixOp_
//CHECK-SAME: [[$RUN_3:[0-9]+]]_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [3 x i256]
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }]
//CHECK: call void @..generated..loop.body.[[$F_ID_11]](
//CHECK: call void @..generated..loop.body.[[$F_ID_11]](
//CHECK: call void @..generated..loop.body.[[$F_ID_11]](
//CHECK: call void @..generated..loop.body.[[$F_ID_12]](
//CHECK: call void @..generated..loop.body.[[$F_ID_12]](
//CHECK: call void @..generated..loop.body.[[$F_ID_12]](
//CHECK: call void @..generated..loop.body.[[$F_ID_13]](
//CHECK: call void @..generated..loop.body.[[$F_ID_13]](
//CHECK: call void @..generated..loop.body.[[$F_ID_13]](
//CHECK: call void @..generated..loop.body.[[$F_ID_14]](
//CHECK: call void @..generated..loop.body.[[$F_ID_14]](
//CHECK: call void @..generated..loop.body.[[$F_ID_14]](
//CHECK: call void @..generated..loop.body.[[$F_ID_15]](
//CHECK: call void @..generated..loop.body.[[$F_ID_15]](
//CHECK: call void @..generated..loop.body.[[$F_ID_15]](
//
//CHECK-LABEL: define{{.*}} void @MatrixOp_{{[0-9]+}}_build({ [0 x i256]*, i32 }* %0){{.*}} {
//CHECK-NEXT: main:
//CHECK-NEXT:   %[[SIGNALS:.*]] = alloca [30 x i256]
//CHECK-NEXT:   %[[COUNTER:.*]] = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 1
//CHECK-NEXT:   store i32 15, i32* %[[COUNTER]]
//
//CHECK-LABEL: define{{.*}} void @MatrixOp_
//CHECK-SAME: [[$RUN_4:[0-9]+]]_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [3 x i256]
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }]
//CHECK: call void @..generated..loop.body.[[$F_ID_16]](
//CHECK: call void @..generated..loop.body.[[$F_ID_16]](
//CHECK: call void @..generated..loop.body.[[$F_ID_16]](
//CHECK: call void @..generated..loop.body.[[$F_ID_17]](
//CHECK: call void @..generated..loop.body.[[$F_ID_17]](
//CHECK: call void @..generated..loop.body.[[$F_ID_17]](
//CHECK: call void @..generated..loop.body.[[$F_ID_18]](
//CHECK: call void @..generated..loop.body.[[$F_ID_18]](
//CHECK: call void @..generated..loop.body.[[$F_ID_18]](
//CHECK: call void @..generated..loop.body.[[$F_ID_19]](
//CHECK: call void @..generated..loop.body.[[$F_ID_19]](
//CHECK: call void @..generated..loop.body.[[$F_ID_19]](
//CHECK: call void @..generated..loop.body.[[$F_ID_20]](
//CHECK: call void @..generated..loop.body.[[$F_ID_20]](
//CHECK: call void @..generated..loop.body.[[$F_ID_20]](
//
//CHECK-LABEL: define{{.*}} void @Wrapper_{{[0-9]+}}_build({ [0 x i256]*, i32 }* %0){{.*}} {
//CHECK-NEXT: main:
//CHECK-NEXT:   %[[SIGNALS:.*]] = alloca [16 x i256]
//CHECK-NEXT:   %[[COUNTER:.*]] = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 1
//CHECK-NEXT:   store i32 15, i32* %{{.*}}[[COUNTER]]
//
//CHECK-LABEL: define{{.*}} void @Wrapper_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK: %lvars = alloca [3 x i256]
//CHECK: unrolled_loop{{[0-9]+}}:
//CHECK: call void @MatrixOp_[[$RUN_1]]_run([0 x i256]* %
//CHECK: call void @MatrixOp_[[$RUN_2]]_run([0 x i256]* %
//CHECK: call void @MatrixOp_[[$RUN_3]]_run([0 x i256]* %
//CHECK: call void @MatrixOp_[[$RUN_4]]_run([0 x i256]* %
//CHECK: store{{[0-9]+}}:{{ +}}; preds = %unrolled_loop{{[0-9]+}}
//CHECK-NEXT: %[[SUB_PTR:.*]] = getelementptr [4 x { [0 x i256]*, i32 }], [4 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT: %[[SUBCMP:.*]] = load [0 x i256]*, [0 x i256]** %[[SUB_PTR]]
//CHECK-NEXT: %[[VAL_PTR:.*]] = getelementptr [0 x i256], [0 x i256]* %[[SUBCMP]], i32 0, i32 5
//CHECK-NEXT: %[[VAL:.*]] = load i256, i256* %[[VAL_PTR]]
//CHECK-NEXT: %[[OUTP_PTR:.*]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT: store i256 %[[VAL]], i256* %[[OUTP_PTR]]
