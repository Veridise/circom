pragma circom 2.0.6;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s

template SMTProcessorSM() {
  signal input prev_new1;
  signal input prev_na;
}

template SMTProcessor(nLevels) {
    signal input enabled;

    component sm[nLevels];
    for (var i=0; i<nLevels; i++) {
        sm[i] = SMTProcessorSM();
        if (i==0) {
            sm[i].prev_new1 <-- 0;
            sm[i].prev_na <-- 1 - enabled;
        } else {
            sm[i].prev_new1 <-- 0;
            sm[i].prev_na <-- 0;
        }
    }
}

component main = SMTProcessor(2);
