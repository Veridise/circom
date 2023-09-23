pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// IF condition can be known via in-place unrolling but not when body is extracted to a new function
template InnerConditional1(N) {
    signal output out;

    var acc = 0;
    for (var i = 1; i <= N; i++) {
        if (i < 5) {
            acc += i;
        } else {
            acc -= i;
        }
    }

    out <-- acc;
}

component main = InnerConditional1(10);

//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals){{.*}} {
//TODO: add more checks, pending https://veridise.atlassian.net/browse/VAN-676

//CHECK-LABEL: define void @InnerConditional1_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//TODO: add more checks, pending https://veridise.atlassian.net/browse/VAN-676
