pragma circom 2.1.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// %[[T00]] (i.e. arena) = [ a[0][0], a[0][1], a[1][0], a[1][1], a[2][0], a[2][1], b[0][0], b[0][1], b[1][0], b[1][1], b[2][0], b[2][1], agg, i, j ]
function sum(a, b) {
    var agg = 0;
    for (var i = 0; i < 3; i++) {
        for (var j = 0; j < 2; j++) {
            agg += a[i][j] - b[i][j];
        }
    }
    return agg;
}

template CallArgTest() {
    signal input x[3][2];
    signal input y[3][2];
    signal output a;

    a <-- sum(x, y);
}

component main = CallArgTest();

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9a-zA-Z_\.]+}}
//CHECK-SAME: ([0 x i256]* %lvars, [0 x i256]* %signals, i256* %[[V0:var_[0-9]+]], i256* %[[V1:var_[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9a-zA-Z_\.]+]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 12
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 12
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T01]], align 4
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[V0]], i32 0
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T03]], align 4
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[V1]], i32 0
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T05]], align 4
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = call i256 @fr_sub(i256 %[[T04]], i256 %[[T06]])
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T02]], i256 %[[T11]])
//CHECK-NEXT:   store i256 %[[T12]], i256* %[[T00]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 14
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 14
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T08]], align 4
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T09]], i256 1)
//CHECK-NEXT:   store i256 %[[T13]], i256* %[[T07]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} i256 @sum_{{[0-9a-zA-Z_\.]+}}
//CHECK-SAME: (i256* %[[T00:[0-9a-zA-Z_\.]+]]){{.*}} {
//CHECK-NEXT: [[$FUN_NAME:sum_[0-9a-zA-Z_\.]+]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY:
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T00]], i32 12
//CHECK-NEXT:   store i256 0, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY:
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T00]], i32 13
//CHECK-NEXT:   store i256 0, i256* %[[T02]], align 4
//CHECK-NEXT:   br label %unrolled_loop3
//CHECK-EMPTY:
//CHECK-NEXT: unrolled_loop3:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T00]], i32 14
//CHECK-NEXT:   store i256 0, i256* %[[T03]], align 4
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T00]] to [0 x i256]*
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T00]] to [0 x i256]*
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T05]], i32 0, i256 0
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T00]] to [0 x i256]*
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T07]], i32 0, i256 6
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T04]], [0 x i256]* null, i256* %[[T06]], i256* %[[T08]])
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T00]] to [0 x i256]*
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T00]] to [0 x i256]*
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T10]], i32 0, i256 1
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T00]] to [0 x i256]*
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T12]], i32 0, i256 7
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T09]], [0 x i256]* null, i256* %[[T11]], i256* %[[T13]])
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T00]], i32 13
//CHECK-NEXT:   store i256 1, i256* %[[T14]], align 4
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T00]], i32 14
//CHECK-NEXT:   store i256 0, i256* %[[T15]], align 4
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T00]] to [0 x i256]*
//CHECK-NEXT:   %[[T17:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T00]] to [0 x i256]*
//CHECK-NEXT:   %[[T18:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T17]], i32 0, i256 2
//CHECK-NEXT:   %[[T19:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T00]] to [0 x i256]*
//CHECK-NEXT:   %[[T20:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T19]], i32 0, i256 8
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T16]], [0 x i256]* null, i256* %[[T18]], i256* %[[T20]])
//CHECK-NEXT:   %[[T21:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T00]] to [0 x i256]*
//CHECK-NEXT:   %[[T22:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T00]] to [0 x i256]*
//CHECK-NEXT:   %[[T23:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T22]], i32 0, i256 3
//CHECK-NEXT:   %[[T24:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T00]] to [0 x i256]*
//CHECK-NEXT:   %[[T25:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T24]], i32 0, i256 9
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T21]], [0 x i256]* null, i256* %[[T23]], i256* %[[T25]])
//CHECK-NEXT:   %[[T26:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T00]], i32 13
//CHECK-NEXT:   store i256 2, i256* %[[T26]], align 4
//CHECK-NEXT:   %[[T27:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T00]], i32 14
//CHECK-NEXT:   store i256 0, i256* %[[T27]], align 4
//CHECK-NEXT:   %[[T28:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T00]] to [0 x i256]*
//CHECK-NEXT:   %[[T29:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T00]] to [0 x i256]*
//CHECK-NEXT:   %[[T30:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T29]], i32 0, i256 4
//CHECK-NEXT:   %[[T31:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T00]] to [0 x i256]*
//CHECK-NEXT:   %[[T32:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T31]], i32 0, i256 10
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T28]], [0 x i256]* null, i256* %[[T30]], i256* %[[T32]])
//CHECK-NEXT:   %[[T33:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T00]] to [0 x i256]*
//CHECK-NEXT:   %[[T34:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T00]] to [0 x i256]*
//CHECK-NEXT:   %[[T35:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T34]], i32 0, i256 5
//CHECK-NEXT:   %[[T36:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T00]] to [0 x i256]*
//CHECK-NEXT:   %[[T37:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T36]], i32 0, i256 11
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T33]], [0 x i256]* null, i256* %[[T35]], i256* %[[T37]])
//CHECK-NEXT:   %[[T38:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T00]], i32 13
//CHECK-NEXT:   store i256 3, i256* %[[T38]], align 4
//CHECK-NEXT:   br label %return4
//CHECK-EMPTY:
//CHECK-NEXT: return4:
//CHECK-NEXT:   %[[T39:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T00]], i32 12
//CHECK-NEXT:   %[[T40:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T39]], align 4
//CHECK-NEXT:   ret i256 %[[T40]]
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @CallArgTest_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[T00:[0-9a-zA-Z_\.]+]]){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [0 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY:
//CHECK-NEXT: call1:
//CHECK-NEXT:   %[[$FUN_NAME]]_arena = alloca [15 x i256], align 8
//CHECK-NEXT:   %[[DST_PTR_A:[0-9a-zA-Z_\.]+]] = getelementptr [15 x i256], [15 x i256]* %[[$FUN_NAME]]_arena, i32 0, i32 0
//CHECK-NEXT:   %[[SRC_PTR_A:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T00]], i32 0, i32 1
//CHECK-NEXT:   %[[CPY_SRC_A0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR_A]], i32 0
//CHECK-NEXT:   %[[CPY_DST_A0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR_A]], i32 0
//CHECK-NEXT:   %[[CPY_VAL_A0:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_A0]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_A0]], i256* %[[CPY_DST_A0]], align 4
//CHECK-NEXT:   %[[CPY_SRC_A1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR_A]], i32 1
//CHECK-NEXT:   %[[CPY_DST_A1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR_A]], i32 1
//CHECK-NEXT:   %[[CPY_VAL_A1:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_A1]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_A1]], i256* %[[CPY_DST_A1]], align 4
//CHECK-NEXT:   %[[CPY_SRC_A2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR_A]], i32 2
//CHECK-NEXT:   %[[CPY_DST_A2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR_A]], i32 2
//CHECK-NEXT:   %[[CPY_VAL_A2:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_A2]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_A2]], i256* %[[CPY_DST_A2]], align 4
//CHECK-NEXT:   %[[CPY_SRC_A3:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR_A]], i32 3
//CHECK-NEXT:   %[[CPY_DST_A3:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR_A]], i32 3
//CHECK-NEXT:   %[[CPY_VAL_A3:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_A3]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_A3]], i256* %[[CPY_DST_A3]], align 4
//CHECK-NEXT:   %[[CPY_SRC_A4:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR_A]], i32 4
//CHECK-NEXT:   %[[CPY_DST_A4:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR_A]], i32 4
//CHECK-NEXT:   %[[CPY_VAL_A4:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_A4]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_A4]], i256* %[[CPY_DST_A4]], align 4
//CHECK-NEXT:   %[[CPY_SRC_A5:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR_A]], i32 5
//CHECK-NEXT:   %[[CPY_DST_A5:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR_A]], i32 5
//CHECK-NEXT:   %[[CPY_VAL_A5:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_A5]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_A5]], i256* %[[CPY_DST_A5]], align 4
//CHECK-NEXT:   %[[DST_PTR_B:[0-9a-zA-Z_\.]+]] = getelementptr [15 x i256], [15 x i256]* %[[$FUN_NAME]]_arena, i32 0, i32 6
//CHECK-NEXT:   %[[SRC_PTR_B:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T00]], i32 0, i32 7
//CHECK-NEXT:   %[[CPY_SRC_B0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR_B]], i32 0
//CHECK-NEXT:   %[[CPY_DST_B0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR_B]], i32 0
//CHECK-NEXT:   %[[CPY_VAL_B0:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_B0]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_B0]], i256* %[[CPY_DST_B0]], align 4
//CHECK-NEXT:   %[[CPY_SRC_B1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR_B]], i32 1
//CHECK-NEXT:   %[[CPY_DST_B1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR_B]], i32 1
//CHECK-NEXT:   %[[CPY_VAL_B1:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_B1]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_B1]], i256* %[[CPY_DST_B1]], align 4
//CHECK-NEXT:   %[[CPY_SRC_B2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR_B]], i32 2
//CHECK-NEXT:   %[[CPY_DST_B2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR_B]], i32 2
//CHECK-NEXT:   %[[CPY_VAL_B2:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_B2]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_B2]], i256* %[[CPY_DST_B2]], align 4
//CHECK-NEXT:   %[[CPY_SRC_B3:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR_B]], i32 3
//CHECK-NEXT:   %[[CPY_DST_B3:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR_B]], i32 3
//CHECK-NEXT:   %[[CPY_VAL_B3:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_B3]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_B3]], i256* %[[CPY_DST_B3]], align 4
//CHECK-NEXT:   %[[CPY_SRC_B4:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR_B]], i32 4
//CHECK-NEXT:   %[[CPY_DST_B4:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR_B]], i32 4
//CHECK-NEXT:   %[[CPY_VAL_B4:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_B4]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_B4]], i256* %[[CPY_DST_B4]], align 4
//CHECK-NEXT:   %[[CPY_SRC_B5:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR_B]], i32 5
//CHECK-NEXT:   %[[CPY_DST_B5:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR_B]], i32 5
//CHECK-NEXT:   %[[CPY_VAL_B5:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_B5]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_B5]], i256* %[[CPY_DST_B5]], align 4
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = bitcast [15 x i256]* %[[$FUN_NAME]]_arena to i256*
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = call i256 @[[$FUN_NAME]](i256* %[[T05]])
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T00]], i32 0, i32 0
//CHECK-NEXT:   store i256 %[[T07]], i256* %[[T06]], align 4
//CHECK-NEXT:   br label %prologue
