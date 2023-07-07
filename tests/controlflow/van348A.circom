//Ensure all blocks have terminators when control flow does not continue past any branch
//	of the if statement (and the merge block after should not even be generated).

pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && circom --llvm -o %t %s

function short_div(k) {
    if (k == 0) {
		return k;
    } else {
        return -k;
    }
}

function long_div(){
    var out[1];
    out[0] = short_div(2);
    return out;
}

template BigModOld() {
    var out[1] = long_div();
}

component main = BigModOld();
