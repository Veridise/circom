pragma circom 2.1.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function sum(a, b, c) {
    return a[0][0][0] + a[1][0][0] + a[2][0][0] + a[3][0][0] + b[0][0] + b[1][2] + c;
}

template CallArgTest() {
    signal input x[4][2][3];
    signal input y[2][3];
    signal input z;
    signal output q;

    q <-- sum(x, y, z);
}

component main = CallArgTest();

//CHECK-LABEL: define{{.*}} i256 @sum_
//CHECK-SAME: [[$F_ID_1:[0-9a-zA-Z_\.]+]](i256* %0){{.*}} {
//CHECK-NEXT: sum_[[$F_ID_1]]:
//CHECK-NEXT:   br label %return1
//CHECK-EMPTY:
//CHECK-NEXT: return1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T01]], align 4
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 6
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T03]], align 4
//CHECK-NEXT:   %[[T90:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T02]], i256 %[[T04]])
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 12
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T05]], align 4
//CHECK-NEXT:   %[[T91:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T90]], i256 %[[T06]])
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 18
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T07]], align 4
//CHECK-NEXT:   %[[T92:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T91]], i256 %[[T08]])
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 24
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T09]], align 4
//CHECK-NEXT:   %[[T93:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T92]], i256 %[[T10]])
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 29
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T11]], align 4
//CHECK-NEXT:   %[[T94:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T93]], i256 %[[T12]])
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 30
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T13]], align 4
//CHECK-NEXT:   %[[T95:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T94]], i256 %[[T14]])
//CHECK-NEXT:   ret i256 %[[T95]]
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @CallArgTest_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [0 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY:
//CHECK-NEXT: call1:
//CHECK-NEXT:   %[[CALL_ARENA:[0-9a-zA-Z_\.]+]] = alloca [31 x i256], align 8
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr [31 x i256], [31 x i256]* %[[CALL_ARENA]], i32 0, i32 0
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:   %[[CPY_SRC_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 0
//CHECK-NEXT:   %[[CPY_DST_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 0
//CHECK-NEXT:   %[[CPY_VAL_0:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_0]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_0]], i256* %[[CPY_DST_0]], align 4
//CHECK-NEXT:   %[[CPY_SRC_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 1
//CHECK-NEXT:   %[[CPY_DST_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 1
//CHECK-NEXT:   %[[CPY_VAL_1:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_1]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_1]], i256* %[[CPY_DST_1]], align 4
//CHECK-NEXT:   %[[CPY_SRC_2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 2
//CHECK-NEXT:   %[[CPY_DST_2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 2
//CHECK-NEXT:   %[[CPY_VAL_2:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_2]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_2]], i256* %[[CPY_DST_2]], align 4
//CHECK-NEXT:   %[[CPY_SRC_3:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 3
//CHECK-NEXT:   %[[CPY_DST_3:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 3
//CHECK-NEXT:   %[[CPY_VAL_3:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_3]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_3]], i256* %[[CPY_DST_3]], align 4
//CHECK-NEXT:   %[[CPY_SRC_4:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 4
//CHECK-NEXT:   %[[CPY_DST_4:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 4
//CHECK-NEXT:   %[[CPY_VAL_4:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_4]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_4]], i256* %[[CPY_DST_4]], align 4
//CHECK-NEXT:   %[[CPY_SRC_5:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 5
//CHECK-NEXT:   %[[CPY_DST_5:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 5
//CHECK-NEXT:   %[[CPY_VAL_5:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_5]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_5]], i256* %[[CPY_DST_5]], align 4
//CHECK-NEXT:   %[[CPY_SRC_6:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 6
//CHECK-NEXT:   %[[CPY_DST_6:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 6
//CHECK-NEXT:   %[[CPY_VAL_6:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_6]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_6]], i256* %[[CPY_DST_6]], align 4
//CHECK-NEXT:   %[[CPY_SRC_7:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 7
//CHECK-NEXT:   %[[CPY_DST_7:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 7
//CHECK-NEXT:   %[[CPY_VAL_7:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_7]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_7]], i256* %[[CPY_DST_7]], align 4
//CHECK-NEXT:   %[[CPY_SRC_8:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 8
//CHECK-NEXT:   %[[CPY_DST_8:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 8
//CHECK-NEXT:   %[[CPY_VAL_8:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_8]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_8]], i256* %[[CPY_DST_8]], align 4
//CHECK-NEXT:   %[[CPY_SRC_9:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 9
//CHECK-NEXT:   %[[CPY_DST_9:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 9
//CHECK-NEXT:   %[[CPY_VAL_9:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_9]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_9]], i256* %[[CPY_DST_9]], align 4
//CHECK-NEXT:   %[[CPY_SRC_10:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 10
//CHECK-NEXT:   %[[CPY_DST_10:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 10
//CHECK-NEXT:   %[[CPY_VAL_10:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_10]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_10]], i256* %[[CPY_DST_10]], align 4
//CHECK-NEXT:   %[[CPY_SRC_11:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 11
//CHECK-NEXT:   %[[CPY_DST_11:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 11
//CHECK-NEXT:   %[[CPY_VAL_11:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_11]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_11]], i256* %[[CPY_DST_11]], align 4
//CHECK-NEXT:   %[[CPY_SRC_12:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 12
//CHECK-NEXT:   %[[CPY_DST_12:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 12
//CHECK-NEXT:   %[[CPY_VAL_12:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_12]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_12]], i256* %[[CPY_DST_12]], align 4
//CHECK-NEXT:   %[[CPY_SRC_13:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 13
//CHECK-NEXT:   %[[CPY_DST_13:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 13
//CHECK-NEXT:   %[[CPY_VAL_13:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_13]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_13]], i256* %[[CPY_DST_13]], align 4
//CHECK-NEXT:   %[[CPY_SRC_14:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 14
//CHECK-NEXT:   %[[CPY_DST_14:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 14
//CHECK-NEXT:   %[[CPY_VAL_14:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_14]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_14]], i256* %[[CPY_DST_14]], align 4
//CHECK-NEXT:   %[[CPY_SRC_15:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 15
//CHECK-NEXT:   %[[CPY_DST_15:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 15
//CHECK-NEXT:   %[[CPY_VAL_15:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_15]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_15]], i256* %[[CPY_DST_15]], align 4
//CHECK-NEXT:   %[[CPY_SRC_16:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 16
//CHECK-NEXT:   %[[CPY_DST_16:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 16
//CHECK-NEXT:   %[[CPY_VAL_16:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_16]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_16]], i256* %[[CPY_DST_16]], align 4
//CHECK-NEXT:   %[[CPY_SRC_17:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 17
//CHECK-NEXT:   %[[CPY_DST_17:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 17
//CHECK-NEXT:   %[[CPY_VAL_17:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_17]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_17]], i256* %[[CPY_DST_17]], align 4
//CHECK-NEXT:   %[[CPY_SRC_18:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 18
//CHECK-NEXT:   %[[CPY_DST_18:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 18
//CHECK-NEXT:   %[[CPY_VAL_18:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_18]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_18]], i256* %[[CPY_DST_18]], align 4
//CHECK-NEXT:   %[[CPY_SRC_19:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 19
//CHECK-NEXT:   %[[CPY_DST_19:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 19
//CHECK-NEXT:   %[[CPY_VAL_19:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_19]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_19]], i256* %[[CPY_DST_19]], align 4
//CHECK-NEXT:   %[[CPY_SRC_20:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 20
//CHECK-NEXT:   %[[CPY_DST_20:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 20
//CHECK-NEXT:   %[[CPY_VAL_20:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_20]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_20]], i256* %[[CPY_DST_20]], align 4
//CHECK-NEXT:   %[[CPY_SRC_21:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 21
//CHECK-NEXT:   %[[CPY_DST_21:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 21
//CHECK-NEXT:   %[[CPY_VAL_21:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_21]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_21]], i256* %[[CPY_DST_21]], align 4
//CHECK-NEXT:   %[[CPY_SRC_22:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 22
//CHECK-NEXT:   %[[CPY_DST_22:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 22
//CHECK-NEXT:   %[[CPY_VAL_22:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_22]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_22]], i256* %[[CPY_DST_22]], align 4
//CHECK-NEXT:   %[[CPY_SRC_23:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 23
//CHECK-NEXT:   %[[CPY_DST_23:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 23
//CHECK-NEXT:   %[[CPY_VAL_23:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_23]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_23]], i256* %[[CPY_DST_23]], align 4
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [31 x i256], [31 x i256]* %[[CALL_ARENA]], i32 0, i32 24
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 25
//CHECK-NEXT:   %[[CPY_SRC_01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T04]], i32 0
//CHECK-NEXT:   %[[CPY_DST_02:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T03]], i32 0
//CHECK-NEXT:   %[[CPY_VAL_03:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_01]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_03]], i256* %[[CPY_DST_02]], align 4
//CHECK-NEXT:   %[[CPY_SRC_110:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T04]], i32 1
//CHECK-NEXT:   %[[CPY_DST_111:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T03]], i32 1
//CHECK-NEXT:   %[[CPY_VAL_112:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_110]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_112]], i256* %[[CPY_DST_111]], align 4
//CHECK-NEXT:   %[[CPY_SRC_213:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T04]], i32 2
//CHECK-NEXT:   %[[CPY_DST_214:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T03]], i32 2
//CHECK-NEXT:   %[[CPY_VAL_215:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_213]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_215]], i256* %[[CPY_DST_214]], align 4
//CHECK-NEXT:   %[[CPY_SRC_316:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T04]], i32 3
//CHECK-NEXT:   %[[CPY_DST_317:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T03]], i32 3
//CHECK-NEXT:   %[[CPY_VAL_318:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_316]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_318]], i256* %[[CPY_DST_317]], align 4
//CHECK-NEXT:   %[[CPY_SRC_419:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T04]], i32 4
//CHECK-NEXT:   %[[CPY_DST_420:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T03]], i32 4
//CHECK-NEXT:   %[[CPY_VAL_421:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_419]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_421]], i256* %[[CPY_DST_420]], align 4
//CHECK-NEXT:   %[[CPY_SRC_522:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T04]], i32 5
//CHECK-NEXT:   %[[CPY_DST_523:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T03]], i32 5
//CHECK-NEXT:   %[[CPY_VAL_524:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_522]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_524]], i256* %[[CPY_DST_523]], align 4
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr [31 x i256], [31 x i256]* %[[CALL_ARENA]], i32 0, i32 30
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 31
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T06]], align 4
//CHECK-NEXT:   store i256 %[[T07]], i256* %[[T05]], align 4
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = bitcast [31 x i256]* %[[CALL_ARENA]] to i256*
//CHECK-NEXT:   %[[T99:[0-9a-zA-Z_\.]+]] = call i256 @sum_[[$F_ID_1]](i256* %[[T08]])
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %[[T99]], i256* %[[T09]], align 4
//CHECK-NEXT:   br label %prologue
