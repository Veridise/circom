pragma circom 2.0.3;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// %0 (i.e. arena) = [ a[0], a[1], b[0], b[1], i ]
function long_gt(a, b) {
    for (var i = 1; i >= 0; i--) {
        if (a[i] > b[i]) {
            return 1;
        }
        if (a[i] <= b[i]) {
            return 0;
        }
    }
    return 0;
}

// %0 (i.e. arena) = [ in[0], in[1], out[0], out[1] ]
function long_scalar_mult(in) {
    var out[2] = in;
    return out;
}

// %0 (i.e. arena) = [ in[0], in[1], norm[0], norm[1], out[0], RETURN(long_gt) ]
function long_div2(in){
    var norm[2] = long_scalar_mult(in);
    var out[1] = [long_gt(norm, norm)];
    return out;
}

// %0 (i.e. signal arena) = [ in[0], in[1] ]
// %lvars = [ out[0] ]
// %subcmps = []
template Test() {
    signal input in[2];
	var out[1] = long_div2(in);
}

component main = Test();

//CHECK-LABEL: define{{.*}} i256* @long_scalar_mult_
//CHECK-SAME: [[$F_ID_1:[0-9a-zA-Z_\.]+]](i256* %0){{.*}} {
//CHECK-NEXT: long_scalar_mult_[[$F_ID_1]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 2
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %[[CPY_SRC_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 0
//CHECK-NEXT:   %[[CPY_DST_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 0
//CHECK-NEXT:   %[[CPY_VAL_0:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_0]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_0]], i256* %[[CPY_DST_0]], align 4
//CHECK-NEXT:   %[[CPY_SRC_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T02]], i32 1
//CHECK-NEXT:   %[[CPY_DST_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 1
//CHECK-NEXT:   %[[CPY_VAL_1:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_1]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_1]], i256* %[[CPY_DST_1]], align 4
//CHECK-NEXT:   br label %return2
//CHECK-EMPTY: 
//CHECK-NEXT: return2:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 2
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
//CHECK-NEXT:   %[[T74:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 4
//CHECK-NEXT:   %[[T75:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T74]], align 4
//CHECK-NEXT:   %[[T91:[0-9a-zA-Z_\.]+]] = call i32 @fr_cast_to_addr(i256 %[[T75]])
//CHECK-NEXT:   %[[T92:[0-9a-zA-Z_\.]+]] = mul i32 1, %[[T91]]
//CHECK-NEXT:   %[[T93:[0-9a-zA-Z_\.]+]] = add i32 %[[T92]], 0
//CHECK-NEXT:   %[[T76:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 %[[T93]]
//CHECK-NEXT:   %[[T77:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T76]], align 4
//CHECK-NEXT:   %[[T78:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 4
//CHECK-NEXT:   %[[T79:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T78]], align 4
//CHECK-NEXT:   %[[T97:[0-9a-zA-Z_\.]+]] = call i32 @fr_cast_to_addr(i256 %[[T79]])
//CHECK-NEXT:   %[[T96:[0-9a-zA-Z_\.]+]] = mul i32 1, %[[T97]]
//CHECK-NEXT:   %[[T95:[0-9a-zA-Z_\.]+]] = add i32 %[[T96]], 2
//CHECK-NEXT:   %[[T80:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 %[[T95]]
//CHECK-NEXT:   %[[T81:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T80]], align 4
//CHECK-NEXT:   %[[T94:[0-9a-zA-Z_\.]+]] = call i1 @fr_gt(i256 %[[T77]], i256 %[[T81]])
//CHECK-NEXT:   br i1 %[[T94]], label %if.then, label %if.else
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
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 4
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T12]], align 4
//CHECK-NEXT:   %[[T27:[0-9a-zA-Z_\.]+]] = call i32 @fr_cast_to_addr(i256 %[[T13]])
//CHECK-NEXT:   %[[T26:[0-9a-zA-Z_\.]+]] = mul i32 1, %[[T27]]
//CHECK-NEXT:   %[[T25:[0-9a-zA-Z_\.]+]] = add i32 %[[T26]], 0
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 %[[T25]]
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T14]], align 4
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 4
//CHECK-NEXT:   %[[T17:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T16]], align 4
//CHECK-NEXT:   %[[T24:[0-9a-zA-Z_\.]+]] = call i32 @fr_cast_to_addr(i256 %[[T17]])
//CHECK-NEXT:   %[[T23:[0-9a-zA-Z_\.]+]] = mul i32 1, %[[T24]]
//CHECK-NEXT:   %[[T22:[0-9a-zA-Z_\.]+]] = add i32 %[[T23]], 2
//CHECK-NEXT:   %[[T18:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 %[[T22]]
//CHECK-NEXT:   %[[T19:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T18]], align 4
//CHECK-NEXT:   %[[T21:[0-9a-zA-Z_\.]+]] = call i1 @fr_le(i256 %[[T15]], i256 %[[T19]])
//CHECK-NEXT:   br i1 %[[T21]], label %if.then4, label %if.else5
//CHECK-EMPTY: 
//CHECK-NEXT: if.then4:
//CHECK-NEXT:   ret i256 0
//CHECK-EMPTY: 
//CHECK-NEXT: if.else5:
//CHECK-NEXT:   br label %if.merge6
//CHECK-EMPTY: 
//CHECK-NEXT: if.merge6:
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
//CHECK-NEXT:   %[[ARENA_1:[0-9a-zA-Z_\.]+]] = alloca [4 x i256], align 8
//CHECK-NEXT:   %[[T50:[0-9a-zA-Z_\.]+]] = getelementptr [4 x i256], [4 x i256]* %[[ARENA_1]], i32 0, i32 0
//CHECK-NEXT:   %[[T52:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %[[CPY_SRC_90:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T52]], i32 0
//CHECK-NEXT:   %[[CPY_DST_90:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T50]], i32 0
//CHECK-NEXT:   %[[CPY_VAL_90:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_90]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_90]], i256* %[[CPY_DST_90]], align 4
//CHECK-NEXT:   %[[CPY_SRC_91:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T52]], i32 1
//CHECK-NEXT:   %[[CPY_DST_91:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T50]], i32 1
//CHECK-NEXT:   %[[CPY_VAL_91:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_91]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_91]], i256* %[[CPY_DST_91]], align 4
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = bitcast [4 x i256]* %[[ARENA_1]] to i256*
//CHECK-NEXT:   %call.long_scalar_mult_[[$F_ID_1:[0-9a-zA-Z_\.]+]] = call i256* @long_scalar_mult_[[$F_ID_1]](i256* %[[T01]])
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 2
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
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 2
//CHECK-NEXT:   %[[CPY_SRC_01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T04]], i32 0
//CHECK-NEXT:   %[[CPY_DST_02:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T03]], i32 0
//CHECK-NEXT:   %[[CPY_VAL_03:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_01]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_03]], i256* %[[CPY_DST_02]], align 4
//CHECK-NEXT:   %[[CPY_SRC_14:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T04]], i32 1
//CHECK-NEXT:   %[[CPY_DST_15:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T03]], i32 1
//CHECK-NEXT:   %[[CPY_VAL_16:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_14]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_16]], i256* %[[CPY_DST_15]], align 4
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr [5 x i256], [5 x i256]* %[[ARENA_2]], i32 0, i32 2
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 2
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
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 5
//CHECK-NEXT:   store i256 %[[T97]], i256* %[[T08]], align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 4
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 5
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T10]], align 4
//CHECK-NEXT:   store i256 %[[T11]], i256* %[[T09]], align 4
//CHECK-NEXT:   br label %return4
//CHECK-EMPTY: 
//CHECK-NEXT: return4:
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 4
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
//CHECK-NEXT:   %[[ARENA_3:[0-9a-zA-Z_\.]+]] = alloca [6 x i256], align 8
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = getelementptr [6 x i256], [6 x i256]* %[[ARENA_3]], i32 0, i32 0
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   %[[CPY_SRC_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T12]], i32 0
//CHECK-NEXT:   %[[CPY_DST_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T11]], i32 0
//CHECK-NEXT:   %[[CPY_VAL_0:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_0]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_0]], i256* %[[CPY_DST_0]], align 4
//CHECK-NEXT:   %[[CPY_SRC_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T12]], i32 1
//CHECK-NEXT:   %[[CPY_DST_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T11]], i32 1
//CHECK-NEXT:   %[[CPY_VAL_1:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_1]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_1]], i256* %[[CPY_DST_1]], align 4
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %[[ARENA_3]] to i256*
//CHECK-NEXT:   %[[T96:[0-9a-zA-Z_\.]+]] = call i256 @long_div2_[[$F_ID_3]](i256* %[[T01]])
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [1 x i256], [1 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 %[[T96]], i256* %[[T02]], align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
