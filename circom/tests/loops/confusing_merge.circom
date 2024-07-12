pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// This test demonstrates the need for the "src-loc" attribute on functions to prevent the LLVM
//  "merge_functions_pass" from merging the extracted loop body functions for the two loops below.
template Foo(N) {
  signal input inp[N];
  signal output outp[N];

  signal internal[N];

  for (var i = 0; i < N; i++) {
    internal[i] <== inp[i];
  }

  for (var i = 0; i < N; i++) {
    internal[i] ==> outp[i];
  }
}

component main = Foo(3);

// Ensure that 2 loop.body functions are generated and there are calls to both in the "run" function.
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9a-zA-Z_\.]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %sig_0, i256* %sig_1){{.*}} {
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_2:[0-9a-zA-Z_\.]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %sig_0, i256* %sig_1){{.*}} {
//
//CHECK-LABEL: define{{.*}} void @Foo_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK: call void @..generated..loop.body.[[$F_ID_1]]({{.*}})
//CHECK: call void @..generated..loop.body.[[$F_ID_1]]({{.*}})
//CHECK: call void @..generated..loop.body.[[$F_ID_1]]({{.*}})
//CHECK: call void @..generated..loop.body.[[$F_ID_2]]({{.*}})
//CHECK: call void @..generated..loop.body.[[$F_ID_2]]({{.*}})
//CHECK: call void @..generated..loop.body.[[$F_ID_2]]({{.*}})
