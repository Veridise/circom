pragma circom 2.0.3;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function long_gt(a, b) {
    for (var i = 1; i >= 0; i--) {
        if (a[i] > b[i]) {
            return 1;
        }
        if (a[i] < b[i]) {
            return 0;
        }
    }
    return 0;
}

function long_scalar_mult() {
    var out[2];
    return out;
}

function long_div2(){
    var norm[2] = long_scalar_mult();
    var out[1] = [long_gt(norm, norm)];
    return out;
}

template Test() {
	var out[1] = long_div2();
}

component main = Test();

//CHECK-LABEL: define{{.*}} i256* @long_scalar_mult_
//CHECK-SAME: [[$F_ID_1:[0-9a-zA-Z_\.]+]](i256* %0){{.*}} {
//CHECK-NEXT: long_scalar_mult_[[$F_ID_1]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   store i256 0, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T02]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   ret i256* %[[T03]]
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} i256 @long_gt_
//CHECK-SAME: [[$F_ID_2:[0-9a-zA-Z_\.]+]](i256* %0){{.*}} {
//CHECK-NEXT: long_gt_[[$F_ID_2]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 4
//CHECK-NEXT:   store i256 1, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %loop2
//CHECK-EMPTY: 
//CHECK-NEXT: loop2:
//CHECK-NEXT:   br label %loop.cond
//CHECK-EMPTY: 
//CHECK-NEXT: loop.cond:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 4
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T02]], align 4
//CHECK-NEXT:   %[[T99:[0-9a-zA-Z_\.]+]] = call i1 @fr_ge(i256 %[[T03]], i256 0)
//CHECK-NEXT:   br i1 %[[T99]], label %loop.body, label %loop.end
//CHECK-EMPTY: 
//CHECK-NEXT: loop.body:
//CHECK-NEXT:   br i1 false, label %if.then, label %if.else
//CHECK-EMPTY: 
//CHECK-NEXT: loop.end:
//CHECK-NEXT:   br label %return12
//CHECK-EMPTY: 
//CHECK-NEXT: if.then:
//CHECK-NEXT:   ret i256 1
//CHECK-EMPTY: 
//CHECK-NEXT: if.else:
//CHECK-NEXT:   br label %if.merge
//CHECK-EMPTY: 
//CHECK-NEXT: if.merge:
//CHECK-NEXT:   br i1 false, label %if.then1, label %if.else2
//CHECK-EMPTY: 
//CHECK-NEXT: if.then1:
//CHECK-NEXT:   ret i256 0
//CHECK-EMPTY: 
//CHECK-NEXT: if.else2:
//CHECK-NEXT:   br label %if.merge3
//CHECK-EMPTY: 
//CHECK-NEXT: if.merge3:
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 4
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 4
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T05]], align 4
//CHECK-NEXT:   %[[T98:[0-9a-zA-Z_\.]+]] = call i256 @fr_sub(i256 %[[T06]], i256 1)
//CHECK-NEXT:   store i256 %[[T98]], i256* %[[T04]], align 4
//CHECK-NEXT:   br label %loop.cond
//CHECK-EMPTY: 
//CHECK-NEXT: return12:
//CHECK-NEXT:   ret i256 0
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} i256 @long_div2_
//CHECK-SAME: [[$F_ID_3:[0-9a-zA-Z_\.]+]](i256* %0){{.*}} {
//CHECK-NEXT: long_div2_[[$F_ID_3]]:
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY: 
//CHECK-NEXT: call1:
//CHECK-NEXT:   %[[ARENA_1:[0-9a-zA-Z_\.]+]] = alloca [2 x i256], align 8
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = bitcast [2 x i256]* %[[ARENA_1]] to i256*
//CHECK-NEXT:   %call.long_scalar_mult_[[$F_ID_1]] = call i256* @long_scalar_mult_[[$F_ID_1]](i256* %[[T01]])
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %[[CPY_SRC_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %call.long_scalar_mult_[[$F_ID_1]], i32 0
//CHECK-NEXT:   %[[CPY_DST_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 0
//CHECK-NEXT:   %[[CPY_VAL_0:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_0]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_0]], i256* %[[CPY_DST_0]], align 4
//CHECK-NEXT:   %[[CPY_SRC_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %call.long_scalar_mult_[[$F_ID_1]], i32 1
//CHECK-NEXT:   %[[CPY_DST_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 1
//CHECK-NEXT:   %[[CPY_VAL_1:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_1]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_1]], i256* %[[CPY_DST_1]], align 4
//CHECK-NEXT:   br label %call2
//CHECK-EMPTY: 
//CHECK-NEXT: call2:
//CHECK-NEXT:   %[[ARENA_2:[0-9a-zA-Z_\.]+]] = alloca [5 x i256], align 8
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %[[ARENA_2]], i32 0, i32 0
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %[[CPY_SRC_01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T04]], i32 0
//CHECK-NEXT:   %[[CPY_DST_02:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T03]], i32 0
//CHECK-NEXT:   %[[CPY_VAL_03:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_01]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_03]], i256* %[[CPY_DST_02]], align 4
//CHECK-NEXT:   %[[CPY_SRC_14:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T04]], i32 1
//CHECK-NEXT:   %[[CPY_DST_15:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T03]], i32 1
//CHECK-NEXT:   %[[CPY_VAL_16:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_14]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_16]], i256* %[[CPY_DST_15]], align 4
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %[[ARENA_2]], i32 0, i32 2
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %[[CPY_SRC_07:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T06]], i32 0
//CHECK-NEXT:   %[[CPY_DST_08:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T05]], i32 0
//CHECK-NEXT:   %[[CPY_VAL_09:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_07]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_09]], i256* %[[CPY_DST_08]], align 4
//CHECK-NEXT:   %[[CPY_SRC_110:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T06]], i32 1
//CHECK-NEXT:   %[[CPY_DST_111:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T05]], i32 1
//CHECK-NEXT:   %[[CPY_VAL_112:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_110]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_112]], i256* %[[CPY_DST_111]], align 4
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = bitcast [5 x i256]* %[[ARENA_2]] to i256*
//CHECK-NEXT:   %[[T97:[0-9a-zA-Z_\.]+]] = call i256 @long_gt_[[$F_ID_2]](i256* %[[T07]])
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 3
//CHECK-NEXT:   store i256 %[[T97]], i256* %[[T08]], align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 2
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 3
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T10]], align 4
//CHECK-NEXT:   store i256 %[[T11]], i256* %[[T09]], align 4
//CHECK-NEXT:   br label %return4
//CHECK-EMPTY: 
//CHECK-NEXT: return4:
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 2
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T12]], align 4
//CHECK-NEXT:   ret i256 %[[T13]]
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @Test_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [1 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY: 
//CHECK-NEXT: call1:
//CHECK-NEXT:   %[[ARENA_3:[0-9a-zA-Z_\.]+]] = alloca [4 x i256], align 8
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = bitcast [4 x i256]* %[[ARENA_3]] to i256*
//CHECK-NEXT:   %[[T96:[0-9a-zA-Z_\.]+]] = call i256 @long_div2_[[$F_ID_3]](i256* %[[T01]])
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [1 x i256], [1 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 %[[T96]], i256* %[[T02]], align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
