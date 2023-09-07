pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL: .*

function fun(a, n, b, c, d, e, f, g) {
	var x[5];
    for (var i = 0; i < n; i++) {
    	x[i] = a[i] + b + c + d + e + f;
    }
	return x[0] + x[2] + x[4];
}

template CallInLoop(n, m) {
    signal input in;
    signal output out;
    var a[n];
    for (var i = 0; i < n; i++) {
    	a[i] = m + in;
    }
    var b[n];
    for (var i = 0; i < n; i++) {
    	b[i] = fun(a, n, m, m, m, m, m, m);
    }
    out <-- b[0];
}

component main = CallInLoop(2, 3);

//// Use the block labels to check that the loop is NOT unrolled
//CHECK-LABEL: define i256 @fun_{{[0-9]+}}
//CHECK-SAME: (i256* %[[ARG:[0-9]+]])
//CHECK-NOT: unrolled_loop{{.*}}:
//CHECK: loop.cond{{.*}}:
//CHECK: loop.body{{.*}}:
//CHECK: loop.end{{.*}}:
//CHECK-NOT: unrolled_loop{{.*}}:
//CHECK:   }

//signal_arena = { out, in }
//lvars = { m, n, a[0], a[1], i, b[0], b[1] }
//
//     var a[2];
//     i = 0;
//     	a[0] = 3 + in;
//     i = 1;
//     	a[1] = 3 + in;
//     i = 2;
//     var b[2];
//     i = 0;
//     	b[0] = fun(a, 2, 3, 3, 3, 3, 3, 3);
//     i = 1;
//     	b[1] = fun(a, 2, 3, 3, 3, 3, 3, 3);
//     i = 2;
//     out <-- b[0];
//
//CHECK-LABEL: define void @CallInLoop_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9]+]])
//CHECK: TODO: Code produced currently is incorrect! See https://veridise.atlassian.net/browse/VAN-611
