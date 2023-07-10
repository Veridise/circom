pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && circom --llvm -o %t %s
//
// XFAIL: *
// TODO: Failure occurs in https://github.com/Veridise/circom/pull/15
//       due to an assertion that was added and unintentionally revealed
//       that return values from call expressions are not stored.
//

function identity(n) {
   return n;
}

function short_div(n) {
    var ret;
    if (n != 0) {
	    ret = identity(n);
    }
    return ret;
}

function long_div(n){
    var out[1];
    out[0] = short_div(n);
    return out;
}

template BigModOld(n) {
    var r[1] = long_div(n);
}

component main = BigModOld(2);
