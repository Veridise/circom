//Ensure all blocks have terminators with 2 loops back-to-back in a nested if statement

pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && circom --llvm -o %t %s

function long_div2(n, k, m, a) {
    var dividend[5];
    for (var i = m; i >= 0; i--) {
        if (i == m) {
            dividend[k] = 0;
            for (var j = k - 1; j >= 0; j-=2) {
                dividend[j] = a[j + m];
            }
            for (var j = k - 2; j >= 0; j-=2) {
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
