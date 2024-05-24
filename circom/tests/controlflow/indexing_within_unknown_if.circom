pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template TestSetAllUnknownWithinUnknownCondition(k) {
    signal input in;
    var ret[10];

    if (in == 1) {
        for (var i = 0; i < k; i++) {
            ret[i] = 8;
        }
    }
}

component main = TestSetAllUnknownWithinUnknownCondition(1);

//CHECK-LABEL: define{{.*}} void @TestSetAllUnknownWithinUnknownCondition_{{[0-9]+}}_run
