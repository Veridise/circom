pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function Recurse(i, n) {
    if (n == 0) {
        return i;
    }
    return Recurse(i, n-1);
}

template FnAssign() {
    signal input inp;
    signal output outp;

    outp <== Recurse(inp, 20);
}

component main = FnAssign();

//CHECK-LABEL: define{{.*}} i256 @Recurse_{{[0-9]+}}(i256* %0){{.*}} {
//CHECK-NEXT: [[$F_ID_1:Recurse_[0-9]+]]:
//CHECK-NEXT:   br label %branch1
//CHECK-EMPTY: 
//CHECK-NEXT: branch1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 1
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T01]], align 4
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = call i1 @fr_eq(i256 %[[T02]], i256 0)
//CHECK-NEXT:   br i1 %[[T03]], label %if.then, label %if.else
//CHECK-EMPTY: 
//CHECK-NEXT: if.then:
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T04]], align 4
//CHECK-NEXT:   ret i256 %[[T05]]
//CHECK-EMPTY: 
//CHECK-NEXT: if.else:
//CHECK-NEXT:   br label %if.merge
//CHECK-EMPTY: 
//CHECK-NEXT: if.merge:
//CHECK-NEXT:   br label %call5
//CHECK-EMPTY: 
//CHECK-NEXT: call5:
//CHECK-NEXT:   %[[A01:[0-9a-zA-Z_.]+]] = alloca [3 x i256], align 8
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = getelementptr [3 x i256], [3 x i256]* %[[A01]], i32 0, i32 0
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T07]], align 4
//CHECK-NEXT:   store i256 %[[T08]], i256* %[[T06]], align 4
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_.]+]] = getelementptr [3 x i256], [3 x i256]* %[[A01]], i32 0, i32 1
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 1
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T10]], align 4
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_.]+]] = call i256 @fr_sub(i256 %[[T11]], i256 1)
//CHECK-NEXT:   store i256 %[[T12]], i256* %[[T09]], align 4
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_.]+]] = bitcast [3 x i256]* %[[A01]] to i256*
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_.]+]] = call i256 @[[$F_ID_1]](i256* %[[T13]])
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 2
//CHECK-NEXT:   store i256 %[[T14]], i256* %[[T15]], align 4
//CHECK-NEXT:   br label %return6
//CHECK-EMPTY: 
//CHECK-NEXT: return6:
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 2
//CHECK-NEXT:   %[[T17:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T16]], align 4
//CHECK-NEXT:   ret i256 %[[T17]]
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} i256 @Recurse_{{[0-9]+\.F}}(i256* %0){{.*}} {
//CHECK-NEXT: [[$F_ID_2:Recurse_[0-9]+\.F]]:
//CHECK-NEXT:   br label %fold_false1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_false1:
//CHECK-NEXT:   br label %call2
//CHECK-EMPTY: 
//CHECK-NEXT: call2:
//CHECK-NEXT:   %[[A01:[0-9a-zA-Z_.]+]] = alloca [3 x i256], align 8
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = getelementptr [3 x i256], [3 x i256]* %[[A01]], i32 0, i32 0
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T07]], align 4
//CHECK-NEXT:   store i256 %[[T08]], i256* %[[T06]], align 4
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_.]+]] = getelementptr [3 x i256], [3 x i256]* %[[A01]], i32 0, i32 1
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 1
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T10]], align 4
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_.]+]] = call i256 @fr_sub(i256 %[[T11]], i256 1)
//CHECK-NEXT:   store i256 %[[T12]], i256* %[[T09]], align 4
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_.]+]] = bitcast [3 x i256]* %[[A01]] to i256*
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_.]+]] = call i256 @[[$F_ID_1]](i256* %[[T13]])
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 2
//CHECK-NEXT:   store i256 %[[T14]], i256* %[[T15]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 2
//CHECK-NEXT:   %[[T17:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T16]], align 4
//CHECK-NEXT:   ret i256 %[[T17]]
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @FnAssign_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [0 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY: 
//CHECK-NEXT: call1
//CHECK-NEXT:   %[[A01:[0-9a-zA-Z_.]+]] = alloca [3 x i256], align 8
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = getelementptr [3 x i256], [3 x i256]* %[[A01]], i32 0, i32 0
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T02]], align 4
//CHECK-NEXT:   store i256 %[[T03]], i256* %[[T01]], align 4
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = getelementptr [3 x i256], [3 x i256]* %[[A01]], i32 0, i32 1
//CHECK-NEXT:   store i256 20, i256* %[[T04]], align 4
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = bitcast [3 x i256]* %[[A01]] to i256*
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = call i256 @[[$F_ID_1]].F(i256* %[[T05]])
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %[[T06]], i256* %[[T07]], align 4
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T07]], align 4
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_.]+]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T06]], i256 %[[T08]], i1* %[[T09]])
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
