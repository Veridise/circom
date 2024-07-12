pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template accumulate() {
    signal input i;
    signal output o;
    var r = 0;
    while (r < i) {
        r++;
    }
    o <-- r;
}

template UnknownLoopOOB() {
    signal input m; // Could be out of bounds
    signal input n[2];
    signal output y;

    component a = accumulate();
    a.i <-- m;
    y <-- n[a.o];
}

component main = UnknownLoopOOB();

//// Use the block labels to check that the loop is NOT unrolled
//CHECK-LABEL: define{{.*}} void @accumulate_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9]+]]){{.*}} {
//CHECK-NOT: unrolled_loop{{.*}}:
//CHECK: loop.cond{{.*}}:
//CHECK: loop.body{{.*}}:
//CHECK: loop.end{{.*}}:
//CHECK-NOT: unrolled_loop{{.*}}:
//CHECK:   }

//// Use the block labels to check that no loop related blocks are present
//CHECK-LABEL: define{{.*}} void @UnknownLoopOOB_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9]+]]){{.*}} {
//CHECK-NOT: {{.*}}loop{{.*}}:
//CHECK:   }
