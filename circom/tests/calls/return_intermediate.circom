pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function Fn(a, b) {
  return a * b;
}

template Foo() {
  signal input inp[2];
  signal output outp[1];

  //NOTE: Using a single statement with the '<==' operator produces a CallBucket
  //  with ReturnType::Final but splitting into separate statements cause the
  //  second one to produce a CallBucket with ReturnType::Intermediate
  outp[0] <-- Fn(inp[0], inp[1]);
  outp[0] === Fn(inp[0], inp[1]);
}

component main = Foo();

//CHECK:   %[[V2:[0-9a-zA-Z_\.]+]] = call i256 @Fn_0(i256* %[[V1:[0-9a-zA-Z_\.]+]])
//CHECK:   %[[V3:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK:   store i256 %[[V2]], i256* %[[V3]], align 4

//CHECK:   %[[V5:[0-9a-zA-Z_\.]+]] = call i256 @Fn_0(i256* %[[V4:[0-9a-zA-Z_\.]+]])
//CHECK:   %[[V6:[0-9a-zA-Z_\.]+]] = call i1 @fr_eq(i256 %10, i256 %[[V5]])
//CHECK:   call void @__assert(i1 %[[V6]])
