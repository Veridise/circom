pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && circom --llvm -o %t %s

template Van276() {
    var a = 168700;
    var b = 999999;
}

component main = Van276();
