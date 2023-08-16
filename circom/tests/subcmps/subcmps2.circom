pragma circom 2.0.6;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s

template Sum(n) {
    signal input inp[n];
    signal output outp;

    var s = 0;

    for (var i = 0; i < n; i++) {
        s += inp[i];
    }

    outp <== s;
}

function nop(i) {
    return i;
}

template Caller() {
    signal input inp[4];
    signal output outp;

    component s = Sum(4);

    for (var i = 0; i < 4; i++) {
        s.inp[i] <== nop(inp[i]);
        //CHECK: %[[CALL_VAL:call\.nop_[0-3]]] = call i256 @nop_{{[0-3]}}(i256* %6)
        //CHECK: %[[SUBCMP_PTR:.*]] = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 {{[0-3]}}
        //CHECK: %[[SUBCMP:.*]] = load [0 x i256]*, [0 x i256]** %[[SUBCMP_PTR]]
        //CHECK: %[[SUBCMP_INP:.*]] = getelementptr [0 x i256], [0 x i256]* %[[SUBCMP]], i32 0, i32 {{[1-4]}}
        //CHECK: store i256 %[[CALL_VAL]], i256* %[[SUBCMP_INP]]
    }

    outp <== s.outp;
}

component main = Caller();