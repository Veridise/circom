pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function identity(n) {	//returns scalar
   return n;
}

function short_div(n) {	//returns scalar
    var ret;
    if (n != 0) {
	    ret = identity(n);
    }
    return ret;
}

function long_div(n) {	//returns array[1], effectively scalar
    var out[1];
    out[0] = short_div(n);
    return out;
}

template BigModOld(n) {
    var r[1] = long_div(n);
}

component main = BigModOld(2);

//CHECK-LABEL: define{{.*}} i256 @long_div_
//CHECK-SAME: [[$F_ID_L:[0-9a-zA-Z_\.]+]](i256* %[[ARENA:.*]]){{.*}} {
//CHECK: %[[TEMP1:.*]] = call i256 @short_div_[[$F_ID_S:[0-9a-zA-Z_\.]+]](i256* %{{[0-9a-zA-Z_\.]+}})
//CHECK: %[[TEMP2:.*]] = getelementptr i256, i256* %{{.*}}[[ARENA]], i32 1
//CHECK: store i256 %{{.*}}[[TEMP1]], i256* %{{.*}}[[TEMP2]]
//CHECK: %[[TEMP3:.*]] = getelementptr i256, i256* %{{.*}}[[ARENA]], i32 1
//CHECK: %[[TEMP4:.*]] = load i256, i256* %{{.*}}[[TEMP3]]
//CHECK: ret i256 %{{.*}}[[TEMP4]]
//CHECK: }

//CHECK-LABEL: define{{.*}} i256 @identity_
//CHECK-SAME: [[$F_ID_I:[0-9a-zA-Z_\.]+]](i256* %[[ARENA:.*]]){{.*}} {
//CHECK: }

//CHECK-LABEL: define{{.*}} i256 @short_div_
//CHECK-SAME: [[$F_ID_S]](i256* %[[ARENA:.*]]){{.*}} {
//CHECK: %[[TEMP1:.*]] = call i256 @identity_[[$F_ID_I]](i256* %{{[0-9a-zA-Z_\.]+}})
//CHECK: %[[TEMP2:.*]] = getelementptr i256, i256* %{{.*}}[[ARENA]], i32 1
//CHECK: store i256 %{{.*}}[[TEMP1]], i256* %{{.*}}[[TEMP2]]
//CHECK: %[[TEMP3:.*]] = getelementptr i256, i256* %{{.*}}[[ARENA]], i32 1
//CHECK: %[[TEMP4:.*]] = load i256, i256* %{{.*}}[[TEMP3]]
//CHECK: ret i256 %{{.*}}[[TEMP4]]
//CHECK: }
