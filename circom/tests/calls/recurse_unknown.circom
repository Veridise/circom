pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function factorial(x) {
    if (x == 0 || x == 1) return 1;
    return x * factorial(x - 1);
}

template Caller() {
    signal input inp;
    signal output outp;
    outp <-- factorial(inp);
}

component main = Caller();

//CHECK-LABEL: define{{.*}} i256 @factorial_{{[0-9]+}}(i256* %0){{.*}} {
//CHECK-NEXT: factorial_0:
//CHECK-NEXT:   br label %branch1
//CHECK-EMPTY: 
//CHECK-NEXT: branch1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T01]], align 4
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = call i1 @fr_eq(i256 %[[T02]], i256 0)
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T04]], align 4
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = call i1 @fr_eq(i256 %[[T05]], i256 1)
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = call i1 @fr_logic_or(i1 %[[T03]], i1 %[[T06]])
//CHECK-NEXT:   br i1 %[[T07]], label %if.then, label %if.else
//CHECK-EMPTY: 
//CHECK-NEXT: if.then:
//CHECK-NEXT:   ret i256 1
//CHECK-EMPTY: 
//CHECK-NEXT: if.else:
//CHECK-NEXT:   br label %if.merge
//CHECK-EMPTY: 
//CHECK-NEXT: if.merge:
//CHECK-NEXT:   br label %call5
//CHECK-EMPTY: 
//CHECK-NEXT: call5:
//CHECK-NEXT:   %[[A01:[0-9a-zA-Z_\.]+]] = alloca [2 x i256], align 8
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = getelementptr [2 x i256], [2 x i256]* %[[A01]], i32 0, i32 0
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T09]], align 4
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = call i256 @fr_sub(i256 %[[T10]], i256 1)
//CHECK-NEXT:   store i256 %[[T11]], i256* %[[T08]], align 4
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = bitcast [2 x i256]* %[[A01]] to i256*
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_\.]+]] = call i256 @factorial_0(i256* %[[T12]])
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 1
//CHECK-NEXT:   store i256 %[[T13]], i256* %[[T14]], align 4
//CHECK-NEXT:   br label %return6
//CHECK-EMPTY: 
//CHECK-NEXT: return6:
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T15]], align 4
//CHECK-NEXT:   %[[T17:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 1
//CHECK-NEXT:   %[[T18:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T17]], align 4
//CHECK-NEXT:   %[[T19:[0-9a-zA-Z_\.]+]] = call i256 @fr_mul(i256 %[[T16]], i256 %[[T18]])
//CHECK-NEXT:   ret i256 %[[T19]]
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @Caller_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [0 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY: 
//CHECK-NEXT: call1:
//CHECK-NEXT:   %[[A01:[0-9a-zA-Z_\.]+]] = alloca [2 x i256], align 8
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr [2 x i256], [2 x i256]* %[[A01]], i32 0, i32 0
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T02]], align 4
//CHECK-NEXT:   store i256 %[[T03]], i256* %[[T01]], align 4
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = bitcast [2 x i256]* %[[A01]] to i256*
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = call i256 @factorial_0(i256* %[[T04]])
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %[[T05]], i256* %[[T06]], align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
