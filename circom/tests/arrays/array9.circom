pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function copy(inp) {
    var ret[3] = inp;
    return ret;
}

template ArrayCopyTemplate() {
    var inp[3];
    var outp[3] = copy(inp);
}

component main = ArrayCopyTemplate();

//CHECK-LABEL: define{{.*}} void @copy_{{[0-9]+}}
//CHECK-SAME: (i256* %[[ARENA:.*]])
//CHECK: %[[TEMP1:.*]] = getelementptr i256, i256* %{{.*}}[[ARENA]], i32 3
//CHECK: %[[TEMP2:.*]] = getelementptr i256, i256* %{{.*}}[[ARENA]], i32 0
//CHECK: call void @fr_copy_n(i256* %{{.*}}[[TEMP2]], i256* %{{.*}}[[TEMP1]], i32 3)
//CHECK: ret void
//CHECK: }

//CHECK-LABEL: define{{.*}} void @ArrayCopyTemplate_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %{{.*}})
//CHECK: %lvars = alloca [6 x i256]
//CHECK: %[[TEMP:.*]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 3
//CHECK: call void @fr_copy_n(i256* %{{.*}}, i256* %{{.*}}[[TEMP]], i32 3)
//CHECK: }
