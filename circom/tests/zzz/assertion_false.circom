pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s 2>&1 | FileCheck %s

template UCO() {
	for(var i = 0; i < 100; i++){
		1 === 0;
	}
}

component main = UCO();

//CHECK: False assert reached
//CHECK: previous errors were found
