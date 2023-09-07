pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template Num2Bits(n) {
    signal input in;
    signal output out[n];
    var lc1=0;

    var e2=1;
    for (var i = 0; i<n; i++) {
        out[i] <-- (in >> i) & 1;
        out[i] * (out[i] -1 ) === 0;
        lc1 += out[i] * e2;
        e2 = e2+e2;
    }

    lc1 === in;
}

template LessThan(n) {
    assert(n <= 252);
    signal input in[2];
    signal output out;

    component n2b = Num2Bits(n+1);

    n2b.in <== in[0]+ (1<<n) - in[1];

    out <== 1-n2b.out[n];
}

// Pointless loop
template CountDown(n) {
    signal input in;
    signal output out;

    var counter = n + 1;

    while (counter > in) {
        n--;
    }

    in === counter;

    out <-- counter;
}

template UnknownLoopIndex(n) {
    signal input idx;
    signal input choices[n];
    signal output out;

    component lt = LessThan(n);
    lt.in[0] <== idx;
    lt.in[1] <== n;
    lt.out === 1;

    component c = CountDown(n);
    c.in <== idx;

    // This constraint will be unknown (error[T20462])
    // out <== choices[c.out];
    out <-- choices[c.out];
}

component main = UnknownLoopIndex(100);

//// Use the block labels to check that the loop is unrolled
//CHECK-LABEL: define void @Num2Bits_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9]+]])
//CHECK-NOT: loop.cond{{.*}}:
//CHECK-NOT: loop.body{{.*}}:
//CHECK-NOT: loop.end{{.*}}:
//CHECK: unrolled_loop{{.*}}:
//CHECK-NOT: loop.cond{{.*}}:
//CHECK-NOT: loop.body{{.*}}:
//CHECK-NOT: loop.end{{.*}}:
//CHECK:   }

//// Use the block labels to check that no loop related blocks are present
//CHECK-LABEL: define void @LessThan_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9]+]])
//CHECK-NOT: {{.*}}loop{{.*}}:
//CHECK:   }

//// Use the block labels to check that the loop is NOT unrolled
//CHECK-LABEL: define void @CountDown_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9]+]])
//CHECK-NOT: unrolled_loop{{.*}}:
//CHECK: loop.cond{{.*}}:
//CHECK: loop.body{{.*}}:
//CHECK: loop.end{{.*}}:
//CHECK-NOT: unrolled_loop{{.*}}:
//CHECK:   }

//// Use the block labels to check that no loop related blocks are present
//CHECK-LABEL: define void @UnknownLoopIndex_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9]+]])
//CHECK-NOT: {{.*}}loop{{.*}}:
//CHECK:   }
