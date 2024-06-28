pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function earlyReturnFn(in) {
    for (var i = 0; i < 6; i++) {
        if (i == 0) {
            return in;
        }
        assert(0 == 1); // This should be removed because of the early return above
    }
    return -1;
}

function noEarlyReturnFn(in) {
    for (var i = 0; i < 6; i++) {
        if (i == 99) {
            return in;
        }
        assert(in == 0);
    }
    return -1;
}


template EarlyReturn() {
    signal input inp;
    signal output outp[2];

    outp[0] <== noEarlyReturnFn(inp);
    outp[1] <== earlyReturnFn(inp);
}

component main = EarlyReturn();

//CHECK-LABEL: define{{.*}} i256 @noEarlyReturnFn_{{[0-9]+}}(i256* %0){{.*}} {
//CHECK-NEXT: noEarlyReturnFn_[[$F_ID_2:[0-9]+]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %unrolled_loop2
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop2:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1:[0-9]+\.F]]([0 x i256]* %[[T02]], [0 x i256]* null)
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T03]], [0 x i256]* null)
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T04]], [0 x i256]* null)
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T05]], [0 x i256]* null)
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T06]], [0 x i256]* null)
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T07]], [0 x i256]* null)
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_.]+]] = call i256 @fr_neg(i256 1)
//CHECK-NEXT:   ret i256 %[[T08]]
//CHECK-NEXT: }

//CHECK-LABEL: define{{.*}} i256 @earlyReturnFn_{{[0-9]+\.T}}(i256* %0){{.*}} {
//CHECK-NEXT: earlyReturnFn_[[$F_ID_3:[0-9]+\.T]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %loop2
//CHECK-EMPTY: 
//CHECK-NEXT: loop2:
//CHECK-NEXT:   br label %loop.cond
//CHECK-EMPTY: 
//CHECK-NEXT: loop.cond:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 1
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T02]], align 4
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_.]+]] = call i1 @fr_lt(i256 %[[T03]], i256 6)
//CHECK-NEXT:   br i1 %[[T08]], label %loop.body, label %loop.end
//CHECK-EMPTY: 
//CHECK-NEXT: loop.body:
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T06]], align 4
//CHECK-NEXT:   ret i256 %[[T07]]
//CHECK-EMPTY: 
//CHECK-NEXT: loop.end:
//CHECK-NEXT:   unreachable
//CHECK-NEXT: }

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1]]([0 x i256]* %lvars, [0 x i256]* %signals){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %fold_false1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_false1:
//CHECK-NEXT:   br label %assert2
//CHECK-EMPTY: 
//CHECK-NEXT: assert2:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T02]], align 4
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = call i1 @fr_eq(i256 %[[T03]], i256 0)
//CHECK-NEXT:   call void @__assert(i1 %[[T07]])
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T05]], align 4
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_.]+]] = call i256 @fr_add(i256 %[[T06]], i256 1)
//CHECK-NEXT:   store i256 %[[T08]], i256* %[[T04]], align 4
//CHECK-NEXT:   br label %return4
//CHECK-EMPTY: 
//CHECK-NEXT: return4:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }

//CHECK-LABEL: define{{.*}} void @EarlyReturn_0_run([0 x i256]* %0){{.*}} {
//CHECK: %[[CV_1:[0-9a-zA-Z_.]+]] = call i256 @noEarlyReturnFn_[[$F_ID_2]](i256* %{{[0-9]+}})
//CHECK: %[[CV_2:[0-9a-zA-Z_.]+]] = call i256 @earlyReturnFn_[[$F_ID_3]](i256* %{{[0-9]+}})
