pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function earlyReturnFn(i, n) {
    if (n == 0) {
        return i;
        assert(0 == 1); // This should be removed because of the early return above
    }
    return 0;
}

template EarlyReturn() {
    signal input inp;
    signal output outp;

    outp <== earlyReturnFn(inp, 0);
}

component main = EarlyReturn();

//CHECK-LABEL: define{{.*}} i256 @earlyReturnFn_0.T(i256* %0){{.*}} {
//CHECK-NEXT: earlyReturnFn_0.T:
//CHECK-NEXT:   br label %fold_true1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_true1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T01]], align 4
//CHECK-NEXT:   ret i256 %[[T02]]
//CHECK-NEXT: }
