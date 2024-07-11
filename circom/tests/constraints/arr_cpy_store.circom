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

//CHECK-LABEL: define{{.*}} void @Foo_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK:      unrolled_loop4:
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[T04]], align 8
//CHECK-NEXT:   %[[DST_PTR:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T05]], i32 0, i32 0
//CHECK-NEXT:   %[[SRC_PTR:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   %[[COPY_SRC_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 0
//CHECK-NEXT:   %[[COPY_DST_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 0
//CHECK-NEXT:   %[[COPY_VAL_0:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_0]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_0]], i256* %[[COPY_DST_0]], align 4
//CHECK-NEXT:   %[[COPY_VAL_01:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_0]], align 4
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_DST_0]], align 4
//CHECK-NEXT:   %[[CONSTRAINT_1:[0-9a-zA-Z_\.]+]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[COPY_VAL_01]], i256 %[[T02]], i1* %[[CONSTRAINT_1]])
//CHECK-NEXT:   %[[COPY_SRC_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 1
//CHECK-NEXT:   %[[COPY_DST_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 1
//CHECK-NEXT:   %[[COPY_VAL_1:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_1]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_1]], i256* %[[COPY_DST_1]], align 4
//CHECK-NEXT:   %[[COPY_VAL_12:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_1]], align 4
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_DST_1]], align 4
//CHECK-NEXT:   %[[CONSTRAINT_3:[0-9a-zA-Z_\.]+]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[COPY_VAL_12]], i256 %[[T03]], i1* %[[CONSTRAINT_3]])
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = load i32, i32* %[[T10]], align 4
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_\.]+]] = sub i32 %[[T12]], 2
//CHECK-NEXT:   store i32 %[[T13]], i32* %[[T10]], align 4
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 3, i256* %[[T11]], align 4
//CHECK-NEXT:   br label %prologue
