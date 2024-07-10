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
