pragma circom 2.1.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// %0 (i.e. arena) = [ a[0][0], a[0][1], a[1][0], a[1][1], a[2][0], a[2][1], agg, i, j ]
function sum(a) {
    var agg = 0;
    for (var i = 0; i < 3; i++) {
        for (var j = 0; j < 2; j++) {
            agg += a[i][j];
        }
    }
    return agg;
}

template CallArgTest() {
    signal input x[3][2];
    signal output y;

    y <-- sum(x);
}

component main = CallArgTest();

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}
//CHECK-SAME: ([0 x i256]* %lvars, [0 x i256]* %signals, i256* %[[V0:var_[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9]+]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T02]], align 4
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[V0]], i32 0
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T04]], align 4
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T03]], i256 %[[T05]])
//CHECK-NEXT:   store i256 %[[T06]], i256* %[[T01]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 8
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 8
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T08]], align 4
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T09]], i256 1)
//CHECK-NEXT:   store i256 %[[T10]], i256* %[[T07]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }

//CHECK-LABEL: define{{.*}} i256 @sum_{{[0-9\.]+}}
//CHECK-SAME: (i256* %[[T00:[0-9a-zA-Z_\.]+]]){{.*}} {
//CHECK-NEXT: [[$FUN_NAME:sum_[0-9\.]+]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY:
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 6
//CHECK-NEXT:   store i256 0, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY:
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 7
//CHECK-NEXT:   store i256 0, i256* %[[T02]], align 4
//CHECK-NEXT:   br label %unrolled_loop3
//CHECK-EMPTY:
//CHECK-NEXT: unrolled_loop3:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 8
//CHECK-NEXT:   store i256 0, i256* %[[T03]], align 4
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T05]], i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T04]], [0 x i256]* null, i256* %[[T06]])
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T08]], i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T07]], [0 x i256]* null, i256* %[[T09]])
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 7
//CHECK-NEXT:   store i256 1, i256* %[[T10]], align 4
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 8
//CHECK-NEXT:   store i256 0, i256* %[[T11]], align 4
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_\.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T13]], i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T12]], [0 x i256]* null, i256* %[[T14]])
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_\.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_\.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %[[T17:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T16]], i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T15]], [0 x i256]* null, i256* %[[T17]])
//CHECK-NEXT:   %[[T18:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 7
//CHECK-NEXT:   store i256 2, i256* %[[T18]], align 4
//CHECK-NEXT:   %[[T19:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 8
//CHECK-NEXT:   store i256 0, i256* %[[T19]], align 4
//CHECK-NEXT:   %[[T20:[0-9a-zA-Z_\.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %[[T21:[0-9a-zA-Z_\.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %[[T22:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T21]], i32 0, i256 4
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T20]], [0 x i256]* null, i256* %[[T22]])
//CHECK-NEXT:   %[[T23:[0-9a-zA-Z_\.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %[[T24:[0-9a-zA-Z_\.]+]] = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %[[T25:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T24]], i32 0, i256 5
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T23]], [0 x i256]* null, i256* %[[T25]])
//CHECK-NEXT:   %[[T26:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 7
//CHECK-NEXT:   store i256 3, i256* %[[T26]], align 4
//CHECK-NEXT:   br label %return4
//CHECK-EMPTY:
//CHECK-NEXT: return4:
//CHECK-NEXT:   %[[T33:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 6
//CHECK-NEXT:   %[[T34:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T33]], align 4
//CHECK-NEXT:   ret i256 %[[T34]]
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @CallArgTest_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [0 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY:
//CHECK-NEXT: call1:
//CHECK-NEXT:   %[[$FUN_NAME]]_arena = alloca [9 x i256], align 8
//CHECK-NEXT:   %[[SRC_PTR:[0-9a-zA-Z_\.]+]] = getelementptr [9 x i256], [9 x i256]* %[[$FUN_NAME]]_arena, i32 0, i32 0
//CHECK-NEXT:   %[[DST_PTR:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:   %[[CPY_SRC_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 0
//CHECK-NEXT:   %[[CPY_DST_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 0
//CHECK-NEXT:   %[[CPY_VAL_0:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_0]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_0]], i256* %[[CPY_DST_0]], align 4
//CHECK-NEXT:   %[[CPY_SRC_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 1
//CHECK-NEXT:   %[[CPY_DST_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 1
//CHECK-NEXT:   %[[CPY_VAL_1:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_1]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_1]], i256* %[[CPY_DST_1]], align 4
//CHECK-NEXT:   %[[CPY_SRC_2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 2
//CHECK-NEXT:   %[[CPY_DST_2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 2
//CHECK-NEXT:   %[[CPY_VAL_2:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_2]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_2]], i256* %[[CPY_DST_2]], align 4
//CHECK-NEXT:   %[[CPY_SRC_3:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 3
//CHECK-NEXT:   %[[CPY_DST_3:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 3
//CHECK-NEXT:   %[[CPY_VAL_3:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_3]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_3]], i256* %[[CPY_DST_3]], align 4
//CHECK-NEXT:   %[[CPY_SRC_4:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 4
//CHECK-NEXT:   %[[CPY_DST_4:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 4
//CHECK-NEXT:   %[[CPY_VAL_4:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_4]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_4]], i256* %[[CPY_DST_4]], align 4
//CHECK-NEXT:   %[[CPY_SRC_5:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 5
//CHECK-NEXT:   %[[CPY_DST_5:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 5
//CHECK-NEXT:   %[[CPY_VAL_5:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_5]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_5]], i256* %[[CPY_DST_5]], align 4
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = bitcast [9 x i256]* %[[$FUN_NAME]]_arena to i256*
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = call i256 @[[$FUN_NAME]](i256* %[[T03]])
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %[[T05]], i256* %[[T04]], align 4
//CHECK-NEXT:   br label %prologue
