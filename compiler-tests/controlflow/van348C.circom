//Ensure all blocks have terminators when there is a nesting of loops and if statements.

pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && circom --llvm -o %t %s

function long_div2(n, k, m, a) {
    var dividend[5];
    for (var i = m; i >= 0; i--) {
        if (i == m) {
            dividend[k] = 0;
            for (var j = 0; j < k; j++) {
                dividend[j] = a[j + m];
            }
        }
    }
    return dividend;
}

template BigModOld(n, k) {
    signal input a[2 * k];
    var r[5] = long_div2(n, k, k, a);
}

component main = BigModOld(8, 2);
