pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function Recurse(i, n) {
    if (n == 0) {
        return i;
    }
    return Recurse(i, n-1);
}

template FnAssign() {
    signal input inp;
    signal output outp;

    outp <== Recurse(inp, 20);
}

component main = FnAssign();

//CHECK-LABEL: define{{.*}} i256 @Recurse_{{[0-9]+}}(i256* %0){{.*}} {
//CHECK-LABEL: define{{.*}} void @FnAssign_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
