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

//CHECK-LABEL: define{{.*}} i256* @copy_{{[0-9]+}}
//CHECK-SAME: (i256* %[[ARENA:[0-9a-zA-Z_.]+]]){{.*}} {
//CHECK: %[[T1:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[ARENA]], i32 3
//CHECK: %[[T2:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[ARENA]], i32 0
//CHECK: call void @fr_copy_n(i256* %[[T2]], i256* %[[T1]], i32 3)
//CHECK: %[[T5:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[ARENA]], i32 3
//CHECK: ret i256* %[[T5]]
//CHECK: }

//CHECK-LABEL: define{{.*}} void @ArrayCopyTemplate_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARENA:[0-9a-zA-Z_.]+]]){{.*}} {
//CHECK:       call{{[0-9]+}}:
//CHECK-NEXT:    %[[ARENA_B:[0-9a-zA-Z_.]+]] = alloca [6 x i256], align 8
//CHECK-NEXT:    %[[T04:[0-9a-zA-Z_.]+]] = getelementptr [6 x i256], [6 x i256]* %[[ARENA_B]], i32 0, i32 0
//CHECK-NEXT:    %[[T05:[0-9a-zA-Z_.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:    call void @fr_copy_n(i256* %[[T05]], i256* %[[T04]], i32 3)
//CHECK-NEXT:    %[[T06:[0-9a-zA-Z_.]+]] = bitcast [6 x i256]* %[[ARENA_B]] to i256*
//CHECK-NEXT:    %[[C01:[0-9a-zA-Z_.]+]] = call i256* @copy_0(i256* %[[T06]])
//CHECK-NEXT:    %[[T07:[0-9a-zA-Z_.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:    call void @fr_copy_n(i256* %[[C01]], i256* %[[T07]], i32 3)
//CHECK-NEXT:    br label %prologue
//CHECK: }
