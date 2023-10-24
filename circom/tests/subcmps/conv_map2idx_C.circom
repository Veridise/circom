pragma circom 2.0.0;

// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template SegmentMulFix(nWindows) {
    signal input e[nWindows];
}

template EscalarMulFix() {
    //Needs at least 2 subcomp to trigger the crash
    component segments[2];
    for (var s = 0; s < 2; s++) {

        // s = 0, nseg = 9, nWindows = 9
        // s = 1, nseg = 4, nWindows = 6
        var nseg = (s == 0) ? 9 : 4;
        var nWindows = (s == 0) ? 9 : 6;

        segments[s] = SegmentMulFix(nWindows);

        // Needs this split loop to trigger the crash
        for (var i = 0; i < nseg; i++) {
            //Runs 9 times for s=0
            //Runs 4 times for s=1
            segments[s].e[i] <-- 999;
        }
        for (var i = nseg; i < nWindows; i++) {
            //Runs 0 times for s=0      //this is the case where the extracted body is generated but shouldn't be!
            //Runs 2 times for s=1
            segments[s].e[i] <-- 888;
        }
    }
}

component main = EscalarMulFix();

//CHECK-NOT: ..generated..loop.body.
//
//CHECK-LABEL: define{{.*}} void @EscalarMulFix_2_run([0 x i256]* %0)
//CHECK: store i256 999
//CHECK: store i256 999
//CHECK: store i256 999
//CHECK: store i256 999
//CHECK: store i256 999
//CHECK: store i256 999
//CHECK: store i256 999
//CHECK: store i256 999
//CHECK: store i256 999
//CHECK: store i256 999
//CHECK: store i256 999
//CHECK: store i256 999
//CHECK: store i256 999
//CHECK: store i256 888
//CHECK: store i256 888
