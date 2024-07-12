pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function earlyReturnFn(in) {
    for (var i = 0; i < 6; i++) {
        return in;
        assert(0 == 1); // This should be removed because of the early return above
    }
    return -1;
}

template EarlyReturn() {
    signal input inp;
    signal output outp;

    outp <== earlyReturnFn(inp);
}

component main = EarlyReturn();

//CHECK-LABEL: define{{.*}} i256 @earlyReturnFn_
//CHECK-SAME: [[$F_ID:[0-9a-zA-Z_\.]+]](i256* %[[ARENA:[0-9a-zA-Z_\.]+]]){{.*}} {
//CHECK-NEXT: earlyReturnFn_[[$F_ID]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[ARENA]], i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T1]], align 4
//CHECK-NEXT:   br label %loop2
//CHECK-EMPTY: 
//CHECK-NEXT: loop2:
//CHECK-NEXT:   br label %loop.cond
//CHECK-EMPTY: 
//CHECK-NEXT: loop.cond:
//CHECK-NEXT:   %[[T2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[ARENA]], i32 1
//CHECK-NEXT:   %[[T3:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T2]], align 4
//CHECK-NEXT:   %[[T9:[0-9a-zA-Z_\.]+]] = call i1 @fr_lt(i256 %[[T3]], i256 6)
//CHECK-NEXT:   br i1 %[[T9]], label %loop.body, label %loop.end
//CHECK-EMPTY: 
//CHECK-NEXT: loop.body:
//CHECK-NEXT:   %[[T4:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[ARENA]], i32 0
//CHECK-NEXT:   %[[T5:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T4]], align 4
//CHECK-NEXT:   ret i256 %[[T5]]
//CHECK-EMPTY: 
//CHECK-NEXT: loop.end:
//CHECK-NEXT:   unreachable
//CHECK-NEXT: }
