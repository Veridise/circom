pragma circom 2.0.0;

// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template Sum(N) {
  signal input inp[N];
}

template Foo(N) {
  signal input inp[N];
  signal input out[N];

  component c = Sum(N);
  for (var i = N; i <= N; i++) {
    // The store here generates an array copy call rather than a simple store.
    c.inp <== inp;
  }
}

component main = Foo(2);

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+\.F]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %subsig_0, [0 x i256]* %sub_0, i256* %subc_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY:
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %subsig_0, i32 0
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 0
//CHECK-NEXT:   call void @fr_copy_n(i256* %[[T03]], i256* %[[T02]], i32 2)
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 0
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T04]], align 4
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %subsig_0, i32 0
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T06]], align 4
//CHECK-NEXT:   %constraint_0 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T05]], i256 %[[T07]], i1* %constraint_0)
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 1
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T08]], align 4
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %subsig_0, i32 1
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T10]], align 4
//CHECK-NEXT:   %constraint_1 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T09]], i256 %[[T11]], i1* %constraint_1)
//CHECK-NEXT:   br label %store2
