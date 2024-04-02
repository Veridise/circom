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
//CHECK-NEXT:   %[[DST_PTR:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %subsig_0, i32 0
//CHECK-NEXT:   %[[SRC_PTR:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %signals, i32 0, i32 0
//CHECK-NEXT:   %[[COPY_SRC_0:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 0
//CHECK-NEXT:   %[[COPY_DST_0:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 0
//CHECK-NEXT:   %[[COPY_VAL_0:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_0]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_0]], i256* %[[COPY_DST_0]], align 4
//CHECK-NEXT:   %[[COPY_VAL_01:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_0]], align 4
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_DST_0]], align 4
//CHECK-NEXT:   %[[CONSTRAINT_1:[0-9a-zA-Z_.]+]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[COPY_VAL_01]], i256 %[[T02]], i1* %[[CONSTRAINT_1]])
//CHECK-NEXT:   %[[COPY_SRC_1:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 1
//CHECK-NEXT:   %[[COPY_DST_1:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 1
//CHECK-NEXT:   %[[COPY_VAL_1:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_1]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_1]], i256* %[[COPY_DST_1]], align 4
//CHECK-NEXT:   %[[COPY_VAL_12:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_1]], align 4
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_DST_1]], align 4
//CHECK-NEXT:   %[[CONSTRAINT_3:[0-9a-zA-Z_.]+]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[COPY_VAL_12]], i256 %[[T03]], i1* %[[CONSTRAINT_3]])
//CHECK-NEXT:   br label %store2
