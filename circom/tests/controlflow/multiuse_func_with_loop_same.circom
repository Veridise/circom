pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// %0 = [ s[0], s[1], s[2], s[3], s[4], s[5], s[6], s[7], s[8], s[9], n, sum, i ]
function f(s, n) {
    var sum = 0;
    for (var i = 0; i < n; i++) {
        sum += s[i];
    }
    return sum;
}

template MultiUse() {
    signal input inp[10];
    signal output outp[3];

    outp[0] <-- f(inp, 2);
    outp[1] <-- f(inp, 2);
    outp[2] <-- f(inp, 2);
}

component main = MultiUse();

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %var_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 11
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 11
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T01]], align 4
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_0, i32 0
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T03]], align 4
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T02]], i256 %[[T04]])
//CHECK-NEXT:   store i256 %[[T08]], i256* %[[T00]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 12
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 12
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T06]], align 4
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T07]], i256 1)
//CHECK-NEXT:   store i256 %[[T09]], i256* %[[T05]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} i256 @f_0.2(i256* %0){{.*}} {
//CHECK-NEXT: f_0.2:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 11
//CHECK-NEXT:   store i256 0, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 12
//CHECK-NEXT:   store i256 0, i256* %[[T02]], align 4
//CHECK-NEXT:   br label %unrolled_loop3
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop3:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T04]], i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T03]], [0 x i256]* null, i256* %[[T05]])
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T07]], i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T06]], [0 x i256]* null, i256* %[[T08]])
//CHECK-NEXT:   br label %return4
//CHECK-EMPTY: 
//CHECK-NEXT: return4:
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 11
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T09]], align 4
//CHECK-NEXT:   ret i256 %[[T10]]
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @MultiUse_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [0 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY: 
//CHECK-NEXT: call1:
//CHECK-NEXT:   %[[A01:[0-9a-zA-Z_\.]+]] = alloca [13 x i256], align 8
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr [13 x i256], [13 x i256]* %[[A01]], i32 0, i32 0
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 3
//CHECK-NEXT:   %[[CPY_SRC_10:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 0
//CHECK-NEXT:   %[[CPY_DST_10:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 0
//CHECK-NEXT:   %[[CPY_VAL_10:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_10]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_10]], i256* %[[CPY_DST_10]], align 4
//CHECK-NEXT:   %[[CPY_SRC_11:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 1
//CHECK-NEXT:   %[[CPY_DST_11:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 1
//CHECK-NEXT:   %[[CPY_VAL_11:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_11]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_11]], i256* %[[CPY_DST_11]], align 4
//CHECK-NEXT:   %[[CPY_SRC_12:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 2
//CHECK-NEXT:   %[[CPY_DST_12:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 2
//CHECK-NEXT:   %[[CPY_VAL_12:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_12]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_12]], i256* %[[CPY_DST_12]], align 4
//CHECK-NEXT:   %[[CPY_SRC_13:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 3
//CHECK-NEXT:   %[[CPY_DST_13:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 3
//CHECK-NEXT:   %[[CPY_VAL_13:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_13]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_13]], i256* %[[CPY_DST_13]], align 4
//CHECK-NEXT:   %[[CPY_SRC_14:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 4
//CHECK-NEXT:   %[[CPY_DST_14:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 4
//CHECK-NEXT:   %[[CPY_VAL_14:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_14]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_14]], i256* %[[CPY_DST_14]], align 4
//CHECK-NEXT:   %[[CPY_SRC_15:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 5
//CHECK-NEXT:   %[[CPY_DST_15:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 5
//CHECK-NEXT:   %[[CPY_VAL_15:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_15]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_15]], i256* %[[CPY_DST_15]], align 4
//CHECK-NEXT:   %[[CPY_SRC_16:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 6
//CHECK-NEXT:   %[[CPY_DST_16:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 6
//CHECK-NEXT:   %[[CPY_VAL_16:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_16]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_16]], i256* %[[CPY_DST_16]], align 4
//CHECK-NEXT:   %[[CPY_SRC_17:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 7
//CHECK-NEXT:   %[[CPY_DST_17:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 7
//CHECK-NEXT:   %[[CPY_VAL_17:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_17]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_17]], i256* %[[CPY_DST_17]], align 4
//CHECK-NEXT:   %[[CPY_SRC_18:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 8
//CHECK-NEXT:   %[[CPY_DST_18:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 8
//CHECK-NEXT:   %[[CPY_VAL_18:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_18]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_18]], i256* %[[CPY_DST_18]], align 4
//CHECK-NEXT:   %[[CPY_SRC_19:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 9
//CHECK-NEXT:   %[[CPY_DST_19:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 9
//CHECK-NEXT:   %[[CPY_VAL_19:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_19]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_19]], i256* %[[CPY_DST_19]], align 4
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [13 x i256], [13 x i256]* %[[A01]], i32 0, i32 10
//CHECK-NEXT:   store i256 2, i256* %[[T03]], align 4
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = bitcast [13 x i256]* %[[A01]] to i256*
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_\.]+]] = call i256 @f_0.2(i256* %[[T04]])
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %[[T16]], i256* %[[T05]], align 4
//CHECK-NEXT:   br label %call2
//CHECK-EMPTY: 
//CHECK-NEXT: call2:
//CHECK-NEXT:   %[[A02:[0-9a-zA-Z_\.]+]] = alloca [13 x i256], align 8
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr [13 x i256], [13 x i256]* %[[A02]], i32 0, i32 0
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 3
//CHECK-NEXT:   %[[CPY_SRC_20:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T07]], i32 0
//CHECK-NEXT:   %[[CPY_DST_20:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T06]], i32 0
//CHECK-NEXT:   %[[CPY_VAL_20:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_20]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_20]], i256* %[[CPY_DST_20]], align 4
//CHECK-NEXT:   %[[CPY_SRC_21:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T07]], i32 1
//CHECK-NEXT:   %[[CPY_DST_21:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T06]], i32 1
//CHECK-NEXT:   %[[CPY_VAL_21:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_21]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_21]], i256* %[[CPY_DST_21]], align 4
//CHECK-NEXT:   %[[CPY_SRC_22:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T07]], i32 2
//CHECK-NEXT:   %[[CPY_DST_22:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T06]], i32 2
//CHECK-NEXT:   %[[CPY_VAL_22:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_22]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_22]], i256* %[[CPY_DST_22]], align 4
//CHECK-NEXT:   %[[CPY_SRC_23:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T07]], i32 3
//CHECK-NEXT:   %[[CPY_DST_23:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T06]], i32 3
//CHECK-NEXT:   %[[CPY_VAL_23:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_23]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_23]], i256* %[[CPY_DST_23]], align 4
//CHECK-NEXT:   %[[CPY_SRC_24:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T07]], i32 4
//CHECK-NEXT:   %[[CPY_DST_24:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T06]], i32 4
//CHECK-NEXT:   %[[CPY_VAL_24:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_24]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_24]], i256* %[[CPY_DST_24]], align 4
//CHECK-NEXT:   %[[CPY_SRC_25:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T07]], i32 5
//CHECK-NEXT:   %[[CPY_DST_25:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T06]], i32 5
//CHECK-NEXT:   %[[CPY_VAL_25:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_25]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_25]], i256* %[[CPY_DST_25]], align 4
//CHECK-NEXT:   %[[CPY_SRC_26:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T07]], i32 6
//CHECK-NEXT:   %[[CPY_DST_26:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T06]], i32 6
//CHECK-NEXT:   %[[CPY_VAL_26:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_26]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_26]], i256* %[[CPY_DST_26]], align 4
//CHECK-NEXT:   %[[CPY_SRC_27:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T07]], i32 7
//CHECK-NEXT:   %[[CPY_DST_27:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T06]], i32 7
//CHECK-NEXT:   %[[CPY_VAL_27:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_27]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_27]], i256* %[[CPY_DST_27]], align 4
//CHECK-NEXT:   %[[CPY_SRC_28:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T07]], i32 8
//CHECK-NEXT:   %[[CPY_DST_28:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T06]], i32 8
//CHECK-NEXT:   %[[CPY_VAL_28:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_28]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_28]], i256* %[[CPY_DST_28]], align 4
//CHECK-NEXT:   %[[CPY_SRC_29:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T07]], i32 9
//CHECK-NEXT:   %[[CPY_DST_29:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T06]], i32 9
//CHECK-NEXT:   %[[CPY_VAL_29:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_29]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_29]], i256* %[[CPY_DST_29]], align 4
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = getelementptr [13 x i256], [13 x i256]* %[[A02]], i32 0, i32 10
//CHECK-NEXT:   store i256 2, i256* %[[T08]], align 4
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = bitcast [13 x i256]* %[[A02]] to i256*
//CHECK-NEXT:   %[[T17:[0-9a-zA-Z_\.]+]] = call i256 @f_0.2(i256* %[[T09]])
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:   store i256 %[[T17]], i256* %[[T10]], align 4
//CHECK-NEXT:   br label %call3
//CHECK-EMPTY: 
//CHECK-NEXT: call3:
//CHECK-NEXT:   %[[A03:[0-9a-zA-Z_\.]+]] = alloca [13 x i256], align 8
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = getelementptr [13 x i256], [13 x i256]* %[[A03]], i32 0, i32 0
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 3
//CHECK-NEXT:   %[[CPY_SRC_30:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T12]], i32 0
//CHECK-NEXT:   %[[CPY_DST_30:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T11]], i32 0
//CHECK-NEXT:   %[[CPY_VAL_30:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_30]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_30]], i256* %[[CPY_DST_30]], align 4
//CHECK-NEXT:   %[[CPY_SRC_31:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T12]], i32 1
//CHECK-NEXT:   %[[CPY_DST_31:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T11]], i32 1
//CHECK-NEXT:   %[[CPY_VAL_31:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_31]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_31]], i256* %[[CPY_DST_31]], align 4
//CHECK-NEXT:   %[[CPY_SRC_32:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T12]], i32 2
//CHECK-NEXT:   %[[CPY_DST_32:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T11]], i32 2
//CHECK-NEXT:   %[[CPY_VAL_32:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_32]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_32]], i256* %[[CPY_DST_32]], align 4
//CHECK-NEXT:   %[[CPY_SRC_33:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T12]], i32 3
//CHECK-NEXT:   %[[CPY_DST_33:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T11]], i32 3
//CHECK-NEXT:   %[[CPY_VAL_33:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_33]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_33]], i256* %[[CPY_DST_33]], align 4
//CHECK-NEXT:   %[[CPY_SRC_34:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T12]], i32 4
//CHECK-NEXT:   %[[CPY_DST_34:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T11]], i32 4
//CHECK-NEXT:   %[[CPY_VAL_34:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_34]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_34]], i256* %[[CPY_DST_34]], align 4
//CHECK-NEXT:   %[[CPY_SRC_35:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T12]], i32 5
//CHECK-NEXT:   %[[CPY_DST_35:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T11]], i32 5
//CHECK-NEXT:   %[[CPY_VAL_35:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_35]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_35]], i256* %[[CPY_DST_35]], align 4
//CHECK-NEXT:   %[[CPY_SRC_36:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T12]], i32 6
//CHECK-NEXT:   %[[CPY_DST_36:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T11]], i32 6
//CHECK-NEXT:   %[[CPY_VAL_36:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_36]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_36]], i256* %[[CPY_DST_36]], align 4
//CHECK-NEXT:   %[[CPY_SRC_37:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T12]], i32 7
//CHECK-NEXT:   %[[CPY_DST_37:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T11]], i32 7
//CHECK-NEXT:   %[[CPY_VAL_37:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_37]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_37]], i256* %[[CPY_DST_37]], align 4
//CHECK-NEXT:   %[[CPY_SRC_38:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T12]], i32 8
//CHECK-NEXT:   %[[CPY_DST_38:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T11]], i32 8
//CHECK-NEXT:   %[[CPY_VAL_38:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_38]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_38]], i256* %[[CPY_DST_38]], align 4
//CHECK-NEXT:   %[[CPY_SRC_39:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T12]], i32 9
//CHECK-NEXT:   %[[CPY_DST_39:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T11]], i32 9
//CHECK-NEXT:   %[[CPY_VAL_39:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_39]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_39]], i256* %[[CPY_DST_39]], align 4
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_\.]+]] = getelementptr [13 x i256], [13 x i256]* %[[A03]], i32 0, i32 10
//CHECK-NEXT:   store i256 2, i256* %[[T13]], align 4
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_\.]+]] = bitcast [13 x i256]* %[[A03]] to i256*
//CHECK-NEXT:   %[[T18:[0-9a-zA-Z_\.]+]] = call i256 @f_0.2(i256* %[[T14]])
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 2
//CHECK-NEXT:   store i256 %[[T18]], i256* %[[T15]], align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
