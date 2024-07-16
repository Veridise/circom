pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// This test demonstrates that a full call stack context is needed when unrolling, not just the most recent call.
// The loop within the template is extracted to a new function so each call to that function will pass different
//  'len' parameter value to 'fun()' thus the iteration count of the loop within 'fun()' depends not on the
//  most recent caller of 'fun()' but 1 call back on the stack.

function fun(in, len) {
	var sum = 0;
    for (var j = 0; j < len; j++) {
    	sum += in[j];
    }
	return sum;
}

template NeedsStackContext(max) {
    signal input in[max];
    signal output out[max];
    for (var i = 0; i < max; i++) { // extracted loop body function 1
    	out[i] <-- fun(in, i);
    }
}

component main = NeedsStackContext(3);

//CHECK-LABEL: define{{.*}} i256 @fun_
//CHECK-SAME: [[$F_ID_1:[0-9a-zA-Z_\.]+]](i256* %0){{.*}} {
//CHECK-NEXT: fun_[[$F_ID_1]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 4
//CHECK-NEXT:   store i256 0, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 5
//CHECK-NEXT:   store i256 0, i256* %[[T02]], align 4
//CHECK-NEXT:   br label %unrolled_loop3
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop3:
//CHECK-NEXT:   br label %return4
//CHECK-EMPTY: 
//CHECK-NEXT: return4:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 4
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T03]], align 4
//CHECK-NEXT:   ret i256 %[[T04]]
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} i256 @fun_
//CHECK-SAME: [[$F_ID_2:[0-9a-zA-Z_\.]+]](i256* %0){{.*}} {
//CHECK-NEXT: fun_[[$F_ID_2]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 4
//CHECK-NEXT:   store i256 0, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 5
//CHECK-NEXT:   store i256 0, i256* %[[T02]], align 4
//CHECK-NEXT:   br label %unrolled_loop3
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop3:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 4
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 4
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T04]], align 4
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 5
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T06]], align 4
//CHECK-NEXT:   %[[T99:[0-9a-zA-Z_\.]+]] = call i32 @fr_cast_to_addr(i256 %[[T07]])
//CHECK-NEXT:   %[[T98:[0-9a-zA-Z_\.]+]] = mul i32 1, %[[T99]]
//CHECK-NEXT:   %[[T97:[0-9a-zA-Z_\.]+]] = add i32 %[[T98]], 0
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 %[[T97]]
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T08]], align 4
//CHECK-NEXT:   %[[T95:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T05]], i256 %[[T09]])
//CHECK-NEXT:   store i256 %[[T95]], i256* %[[T03]], align 4
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 5
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 5
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T11]], align 4
//CHECK-NEXT:   %[[T96:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T12]], i256 1)
//CHECK-NEXT:   store i256 %[[T96]], i256* %[[T10]], align 4
//CHECK-NEXT:   br label %return4
//CHECK-EMPTY: 
//CHECK-NEXT: return4:
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 4
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T13]], align 4
//CHECK-NEXT:   ret i256 %[[T14]]
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} i256 @fun_
//CHECK-SAME: [[$F_ID_3:[0-9a-zA-Z_\.]+]](i256* %0){{.*}} {
//CHECK-NEXT: fun_[[$F_ID_3]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 4
//CHECK-NEXT:   store i256 0, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 5
//CHECK-NEXT:   store i256 0, i256* %[[T02]], align 4
//CHECK-NEXT:   br label %unrolled_loop3
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop3:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T04]], i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_7:[0-9a-zA-Z_\.]+]]([0 x i256]* %[[T03]], [0 x i256]* null, i256* %[[T05]])
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T07]], i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_7]]([0 x i256]* %[[T06]], [0 x i256]* null, i256* %[[T08]])
//CHECK-NEXT:   br label %return4
//CHECK-EMPTY: 
//CHECK-NEXT: return4:
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 4
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T09]], align 4
//CHECK-NEXT:   ret i256 %[[T10]]
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_4:[0-9a-zA-Z_\.]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %sig_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_4]]:
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY: 
//CHECK-NEXT: call1:
//CHECK-NEXT:   %[[CALL_ARENA:[0-9a-zA-Z_\.]+]] = alloca [6 x i256], align 8
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr [6 x i256], [6 x i256]* %[[CALL_ARENA]], i32 0, i32 0
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 3
//CHECK-NEXT:   %[[CPY_SRC_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 0
//CHECK-NEXT:   %[[CPY_DST_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T00]], i32 0
//CHECK-NEXT:   %[[CPY_VAL_0:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_0]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_0]], i256* %[[CPY_DST_0]], align 4
//CHECK-NEXT:   %[[CPY_SRC_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 1
//CHECK-NEXT:   %[[CPY_DST_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T00]], i32 1
//CHECK-NEXT:   %[[CPY_VAL_1:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_1]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_1]], i256* %[[CPY_DST_1]], align 4
//CHECK-NEXT:   %[[CPY_SRC_2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 2
//CHECK-NEXT:   %[[CPY_DST_2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T00]], i32 2
//CHECK-NEXT:   %[[CPY_VAL_2:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_2]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_2]], i256* %[[CPY_DST_2]], align 4
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [6 x i256], [6 x i256]* %[[CALL_ARENA]], i32 0, i32 3
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T03]], align 4
//CHECK-NEXT:   store i256 %[[T04]], i256* %[[T02]], align 4
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %[[CALL_ARENA]] to i256*
//CHECK-NEXT:   %[[T94:[0-9a-zA-Z_\.]+]] = call i256 @fun_[[$F_ID_1]](i256* %[[T05]])
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_0, i32 0
//CHECK-NEXT:   store i256 %[[T94]], i256* %[[T06]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T08]], align 4
//CHECK-NEXT:   %[[T95:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T09]], i256 1)
//CHECK-NEXT:   store i256 %[[T95]], i256* %[[T07]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_5:[0-9a-zA-Z_\.]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %sig_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_5]]:
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY: 
//CHECK-NEXT: call1:
//CHECK-NEXT:   %[[CALL_ARENA:[0-9a-zA-Z_\.]+]] = alloca [6 x i256], align 8
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr [6 x i256], [6 x i256]* %[[CALL_ARENA]], i32 0, i32 0
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 3
//CHECK-NEXT:   %[[CPY_SRC_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 0
//CHECK-NEXT:   %[[CPY_DST_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T00]], i32 0
//CHECK-NEXT:   %[[CPY_VAL_0:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_0]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_0]], i256* %[[CPY_DST_0]], align 4
//CHECK-NEXT:   %[[CPY_SRC_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 1
//CHECK-NEXT:   %[[CPY_DST_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T00]], i32 1
//CHECK-NEXT:   %[[CPY_VAL_1:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_1]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_1]], i256* %[[CPY_DST_1]], align 4
//CHECK-NEXT:   %[[CPY_SRC_2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 2
//CHECK-NEXT:   %[[CPY_DST_2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T00]], i32 2
//CHECK-NEXT:   %[[CPY_VAL_2:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_2]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_2]], i256* %[[CPY_DST_2]], align 4
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [6 x i256], [6 x i256]* %[[CALL_ARENA]], i32 0, i32 3
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T03]], align 4
//CHECK-NEXT:   store i256 %[[T04]], i256* %[[T02]], align 4
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %[[CALL_ARENA]] to i256*
//CHECK-NEXT:   %[[T93:[0-9a-zA-Z_\.]+]] = call i256 @fun_[[$F_ID_2]](i256* %[[T05]])
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_0, i32 0
//CHECK-NEXT:   store i256 %[[T93]], i256* %[[T06]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T08]], align 4
//CHECK-NEXT:   %[[T95:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T09]], i256 1)
//CHECK-NEXT:   store i256 %[[T95]], i256* %[[T07]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_6:[0-9a-zA-Z_\.]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %sig_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_6]]:
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY: 
//CHECK-NEXT: call1:
//CHECK-NEXT:   %[[CALL_ARENA:[0-9a-zA-Z_\.]+]] = alloca [6 x i256], align 8
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr [6 x i256], [6 x i256]* %[[CALL_ARENA]], i32 0, i32 0
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 3
//CHECK-NEXT:   %[[CPY_SRC_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 0
//CHECK-NEXT:   %[[CPY_DST_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T00]], i32 0
//CHECK-NEXT:   %[[CPY_VAL_0:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_0]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_0]], i256* %[[CPY_DST_0]], align 4
//CHECK-NEXT:   %[[CPY_SRC_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 1
//CHECK-NEXT:   %[[CPY_DST_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T00]], i32 1
//CHECK-NEXT:   %[[CPY_VAL_1:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_1]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_1]], i256* %[[CPY_DST_1]], align 4
//CHECK-NEXT:   %[[CPY_SRC_2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T01]], i32 2
//CHECK-NEXT:   %[[CPY_DST_2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T00]], i32 2
//CHECK-NEXT:   %[[CPY_VAL_2:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_2]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_2]], i256* %[[CPY_DST_2]], align 4
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [6 x i256], [6 x i256]* %[[CALL_ARENA]], i32 0, i32 3
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T03]], align 4
//CHECK-NEXT:   store i256 %[[T04]], i256* %[[T02]], align 4
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %[[CALL_ARENA]] to i256*
//CHECK-NEXT:   %[[T92:[0-9a-zA-Z_\.]+]] = call i256 @fun_[[$F_ID_3]](i256* %[[T05]])
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_0, i32 0
//CHECK-NEXT:   store i256 %[[T92]], i256* %[[T06]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T08]], align 4
//CHECK-NEXT:   %[[T95:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T09]], i256 1)
//CHECK-NEXT:   store i256 %[[T95]], i256* %[[T07]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_7]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %var_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_7]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T01]], align 4
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_0, i32 0
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T03]], align 4
//CHECK-NEXT:   %[[T95:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T02]], i256 %[[T04]])
//CHECK-NEXT:   store i256 %[[T95]], i256* %[[T00]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T06]], align 4
//CHECK-NEXT:   %[[T96:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T07]], i256 1)
//CHECK-NEXT:   store i256 %[[T96]], i256* %[[T05]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @NeedsStackContext_{{[0-9]}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [2 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 3, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T02]], align 4
//CHECK-NEXT:   br label %unrolled_loop3
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop3:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_4]]([0 x i256]* %[[T03]], [0 x i256]* %0, i256* %[[T04]])
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_5]]([0 x i256]* %[[T05]], [0 x i256]* %0, i256* %[[T06]])
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_6]]([0 x i256]* %[[T07]], [0 x i256]* %0, i256* %[[T08]])
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
