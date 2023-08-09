pragma circom 2.0.3;

// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s

template GetWeight(A) {
    signal input inp;
}

template ComputeValue() {
    component getWeights[2];

    getWeights[0] = GetWeight(0);
    getWeights[0].inp <-- 888;

    getWeights[1] = GetWeight(1);
    getWeights[1].inp <-- 999;
}

component main = ComputeValue();
