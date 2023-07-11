pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && circom --llvm -o %t %s

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
