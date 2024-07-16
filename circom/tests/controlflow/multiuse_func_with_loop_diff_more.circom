pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// Tests the case where the memory references within the unrolled function are different per call to 'f()'.

// %0 = [ s[0], s[1], s[2], s[3], s[4], s[5], s[6], s[7], s[8], s[9], count, offset, sum, i]
function f(s, count, offset) {
    var sum = 0;
    for (var i = 0; i < count; i++) {
        sum += s[i + offset];
    }
    return sum;
}

template MultiUse() {
    signal input inp[10];
    signal output outp[3];

    outp[0] <-- f(inp, 2, 1);
    outp[1] <-- f(inp, 2, 0);
    outp[2] <-- f(inp, 2, 3);
}

component main = MultiUse();

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9a-zA-Z_\.]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %var_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 12
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 12
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T01]], align 4
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_0, i32 0
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T03]], align 4
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T02]], i256 %[[T04]])
//CHECK-NEXT:   store i256 %[[T10]], i256* %[[T00]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 13
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 13
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T06]], align 4
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T07]], i256 1)
//CHECK-NEXT:   store i256 %[[T11]], i256* %[[T05]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} i256 @f_
//CHECK-SAME: [[$F_ID_2:[0-9a-zA-Z_\.]+]](i256* %0){{.*}} {
//CHECK-NEXT: f_[[$F_ID_2]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 12
//CHECK-NEXT:   store i256 0, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 13
//CHECK-NEXT:   store i256 0, i256* %[[T02]], align 4
//CHECK-NEXT:   br label %unrolled_loop3
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop3:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T04]], i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T03]], [0 x i256]* null, i256* %[[T05]])
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T07]], i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T06]], [0 x i256]* null, i256* %[[T08]])
//CHECK-NEXT:   br label %return4
//CHECK-EMPTY: 
//CHECK-NEXT: return4:
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 12
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T09]], align 4
//CHECK-NEXT:   ret i256 %[[T10]]
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} i256 @f_
//CHECK-SAME: [[$F_ID_3:[0-9a-zA-Z_\.]+]](i256* %0){{.*}} {
//CHECK-NEXT: f_[[$F_ID_3]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 12
//CHECK-NEXT:   store i256 0, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 13
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
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 12
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T09]], align 4
//CHECK-NEXT:   ret i256 %[[T10]]
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} i256 @f_
//CHECK-SAME: [[$F_ID_4:[0-9a-zA-Z_\.]+]](i256* %0){{.*}} {
//CHECK-NEXT: f_[[$F_ID_4]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 12
//CHECK-NEXT:   store i256 0, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 13
//CHECK-NEXT:   store i256 0, i256* %[[T02]], align 4
//CHECK-NEXT:   br label %unrolled_loop3
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop3:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T04]], i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T03]], [0 x i256]* null, i256* %[[T05]])
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T07]], i32 0, i256 4
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T06]], [0 x i256]* null, i256* %[[T08]])
//CHECK-NEXT:   br label %return4
//CHECK-EMPTY: 
//CHECK-NEXT: return4:
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 12
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T09]], align 4
//CHECK-NEXT:   ret i256 %[[T10]]
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @MultiUse_{{[0-9]}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [0 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY: 
//CHECK-NEXT: call1:
//CHECK-NEXT:   %[[CALL_ARENA_1:[0-9a-zA-Z_\.]+]] = alloca [14 x i256], align 8
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr [14 x i256], [14 x i256]* %[[CALL_ARENA_1]], i32 0, i32 0
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 3
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
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [14 x i256], [14 x i256]* %[[CALL_ARENA_1]], i32 0, i32 10
//CHECK-NEXT:   store i256 2, i256* %[[T03]], align 4
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr [14 x i256], [14 x i256]* %[[CALL_ARENA_1]], i32 0, i32 11
//CHECK-NEXT:   store i256 1, i256* %[[T04]], align 4
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = bitcast [14 x i256]* %[[CALL_ARENA_1]] to i256*
//CHECK-NEXT:   %[[T99:[0-9a-zA-Z_\.]+]] = call i256 @f_[[$F_ID_2]](i256* %[[T05]])
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %[[T99]], i256* %[[T06]], align 4
//CHECK-NEXT:   br label %call2
//CHECK-EMPTY: 
//CHECK-NEXT: call2:
//CHECK-NEXT:   %[[CALL_ARENA_2:[0-9a-zA-Z_\.]+]] = alloca [14 x i256], align 8
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = getelementptr [14 x i256], [14 x i256]* %[[CALL_ARENA_2]], i32 0, i32 0
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 3
//CHECK-NEXT:   %[[CPY_SRC_01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T08]], i32 0
//CHECK-NEXT:   %[[CPY_DST_02:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T07]], i32 0
//CHECK-NEXT:   %[[CPY_VAL_03:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_01]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_03]], i256* %[[CPY_DST_02]], align 4
//CHECK-NEXT:   %[[CPY_SRC_14:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T08]], i32 1
//CHECK-NEXT:   %[[CPY_DST_15:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T07]], i32 1
//CHECK-NEXT:   %[[CPY_VAL_16:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_14]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_16]], i256* %[[CPY_DST_15]], align 4
//CHECK-NEXT:   %[[CPY_SRC_27:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T08]], i32 2
//CHECK-NEXT:   %[[CPY_DST_28:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T07]], i32 2
//CHECK-NEXT:   %[[CPY_VAL_29:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_27]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_29]], i256* %[[CPY_DST_28]], align 4
//CHECK-NEXT:   %[[CPY_SRC_310:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T08]], i32 3
//CHECK-NEXT:   %[[CPY_DST_311:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T07]], i32 3
//CHECK-NEXT:   %[[CPY_VAL_312:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_310]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_312]], i256* %[[CPY_DST_311]], align 4
//CHECK-NEXT:   %[[CPY_SRC_413:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T08]], i32 4
//CHECK-NEXT:   %[[CPY_DST_414:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T07]], i32 4
//CHECK-NEXT:   %[[CPY_VAL_415:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_413]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_415]], i256* %[[CPY_DST_414]], align 4
//CHECK-NEXT:   %[[CPY_SRC_516:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T08]], i32 5
//CHECK-NEXT:   %[[CPY_DST_517:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T07]], i32 5
//CHECK-NEXT:   %[[CPY_VAL_518:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_516]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_518]], i256* %[[CPY_DST_517]], align 4
//CHECK-NEXT:   %[[CPY_SRC_619:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T08]], i32 6
//CHECK-NEXT:   %[[CPY_DST_620:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T07]], i32 6
//CHECK-NEXT:   %[[CPY_VAL_621:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_619]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_621]], i256* %[[CPY_DST_620]], align 4
//CHECK-NEXT:   %[[CPY_SRC_722:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T08]], i32 7
//CHECK-NEXT:   %[[CPY_DST_723:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T07]], i32 7
//CHECK-NEXT:   %[[CPY_VAL_724:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_722]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_724]], i256* %[[CPY_DST_723]], align 4
//CHECK-NEXT:   %[[CPY_SRC_825:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T08]], i32 8
//CHECK-NEXT:   %[[CPY_DST_826:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T07]], i32 8
//CHECK-NEXT:   %[[CPY_VAL_827:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_825]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_827]], i256* %[[CPY_DST_826]], align 4
//CHECK-NEXT:   %[[CPY_SRC_928:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T08]], i32 9
//CHECK-NEXT:   %[[CPY_DST_929:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T07]], i32 9
//CHECK-NEXT:   %[[CPY_VAL_930:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_928]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_930]], i256* %[[CPY_DST_929]], align 4
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr [14 x i256], [14 x i256]* %[[CALL_ARENA_2]], i32 0, i32 10
//CHECK-NEXT:   store i256 2, i256* %[[T09]], align 4
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = getelementptr [14 x i256], [14 x i256]* %[[CALL_ARENA_2]], i32 0, i32 11
//CHECK-NEXT:   store i256 0, i256* %[[T10]], align 4
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = bitcast [14 x i256]* %[[CALL_ARENA_2]] to i256*
//CHECK-NEXT:   %[[T98:[0-9a-zA-Z_\.]+]] = call i256 @f_[[$F_ID_3]](i256* %[[T11]])
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:   store i256 %[[T98]], i256* %[[T12]], align 4
//CHECK-NEXT:   br label %call3
//CHECK-EMPTY: 
//CHECK-NEXT: call3:
//CHECK-NEXT:   %[[CALL_ARENA_3:[0-9a-zA-Z_\.]+]] = alloca [14 x i256], align 8
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_\.]+]] = getelementptr [14 x i256], [14 x i256]* %[[CALL_ARENA_3]], i32 0, i32 0
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 3
//CHECK-NEXT:   %[[CPY_SRC_031:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T14]], i32 0
//CHECK-NEXT:   %[[CPY_DST_032:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T13]], i32 0
//CHECK-NEXT:   %[[CPY_VAL_033:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_031]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_033]], i256* %[[CPY_DST_032]], align 4
//CHECK-NEXT:   %[[CPY_SRC_134:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T14]], i32 1
//CHECK-NEXT:   %[[CPY_DST_135:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T13]], i32 1
//CHECK-NEXT:   %[[CPY_VAL_136:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_134]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_136]], i256* %[[CPY_DST_135]], align 4
//CHECK-NEXT:   %[[CPY_SRC_237:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T14]], i32 2
//CHECK-NEXT:   %[[CPY_DST_238:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T13]], i32 2
//CHECK-NEXT:   %[[CPY_VAL_239:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_237]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_239]], i256* %[[CPY_DST_238]], align 4
//CHECK-NEXT:   %[[CPY_SRC_340:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T14]], i32 3
//CHECK-NEXT:   %[[CPY_DST_341:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T13]], i32 3
//CHECK-NEXT:   %[[CPY_VAL_342:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_340]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_342]], i256* %[[CPY_DST_341]], align 4
//CHECK-NEXT:   %[[CPY_SRC_443:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T14]], i32 4
//CHECK-NEXT:   %[[CPY_DST_444:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T13]], i32 4
//CHECK-NEXT:   %[[CPY_VAL_445:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_443]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_445]], i256* %[[CPY_DST_444]], align 4
//CHECK-NEXT:   %[[CPY_SRC_546:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T14]], i32 5
//CHECK-NEXT:   %[[CPY_DST_547:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T13]], i32 5
//CHECK-NEXT:   %[[CPY_VAL_548:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_546]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_548]], i256* %[[CPY_DST_547]], align 4
//CHECK-NEXT:   %[[CPY_SRC_649:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T14]], i32 6
//CHECK-NEXT:   %[[CPY_DST_650:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T13]], i32 6
//CHECK-NEXT:   %[[CPY_VAL_651:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_649]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_651]], i256* %[[CPY_DST_650]], align 4
//CHECK-NEXT:   %[[CPY_SRC_752:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T14]], i32 7
//CHECK-NEXT:   %[[CPY_DST_753:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T13]], i32 7
//CHECK-NEXT:   %[[CPY_VAL_754:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_752]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_754]], i256* %[[CPY_DST_753]], align 4
//CHECK-NEXT:   %[[CPY_SRC_855:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T14]], i32 8
//CHECK-NEXT:   %[[CPY_DST_856:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T13]], i32 8
//CHECK-NEXT:   %[[CPY_VAL_857:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_855]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_857]], i256* %[[CPY_DST_856]], align 4
//CHECK-NEXT:   %[[CPY_SRC_958:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T14]], i32 9
//CHECK-NEXT:   %[[CPY_DST_959:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T13]], i32 9
//CHECK-NEXT:   %[[CPY_VAL_960:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_958]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_960]], i256* %[[CPY_DST_959]], align 4
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_\.]+]] = getelementptr [14 x i256], [14 x i256]* %[[CALL_ARENA_3]], i32 0, i32 10
//CHECK-NEXT:   store i256 2, i256* %[[T15]], align 4
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_\.]+]] = getelementptr [14 x i256], [14 x i256]* %[[CALL_ARENA_3]], i32 0, i32 11
//CHECK-NEXT:   store i256 3, i256* %[[T16]], align 4
//CHECK-NEXT:   %[[T17:[0-9a-zA-Z_\.]+]] = bitcast [14 x i256]* %[[CALL_ARENA_3]] to i256*
//CHECK-NEXT:   %[[T97:[0-9a-zA-Z_\.]+]] = call i256 @f_[[$F_ID_4]](i256* %[[T17]])
//CHECK-NEXT:   %[[T18:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 2
//CHECK-NEXT:   store i256 %[[T97]], i256* %[[T18]], align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
