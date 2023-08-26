pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s

template nbits() {
    signal input in;
    signal output out;
    var n = 1;
    var r = 0;
    while (n-1 < in) {
        r++;
        n *= 2;
    }
    out <-- r;
}

template UnknownLoopComponent() {
    signal input num;
    signal output bits;

    component nb = nbits();
    nb.in <-- num;
    bits <-- nb.out;
}

component main = UnknownLoopComponent();

//// Use the block labels to check that the loop is NOT unrolled
//CHECK-LABEL: define void @nbits_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9]+]])
//CHECK-NOT: unrolled_loop{{.*}}:
//CHECK: loop.cond{{.*}}:
//CHECK: loop.body{{.*}}:
//CHECK: loop.end{{.*}}:
//CHECK-NOT: unrolled_loop{{.*}}:
//CHECK:   }

//// Use the block labels to check that no loop related blocks are present
//CHECK-LABEL: define void @UnknownLoopComponent_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9]+]])
//CHECK-NOT: {{.*}}loop{{.*}}:
//CHECK:   }
