pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// This test contains inner loops with different iteration counts. Further, one is
//  independent of the outer loop induction variable and the other loop depends on it.
//
// lvars = [ N, a[0], a[1], a[2], a[3], i, j ]
template InnerConditional12(N) {
    signal output out;

    var a[N];
    for (var i = 0; i < N; i++) {
        if (i < 2) {
            // runs when i∈{0,1}
            for (var j = 0; j < N; j++) {
                a[i] += 999;
            }
        } else {
            // runs when i∈{2,3}
            for (var j = 0; j < i; j++) {
                a[i] += 888;
            }
        }
    }
    out <-- a[0] + a[1];
}

component main = InnerConditional12(4);

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME:  [[$F_ID_4:[0-9a-zA-Z_\.]+]]([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %subsig_[[X1:[0-9]+]], i256* %subsig_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_4]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subsig_[[X1]], i32 0
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subsig_[[X2]], i32 0
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T01]], align 4
//CHECK-NEXT:   %[[T98:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T02]], i256 999)
//CHECK-NEXT:   store i256 %[[T98]], i256* %[[T00]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T04]], align 4
//CHECK-NEXT:   %[[T99:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T05]], i256 1)
//CHECK-NEXT:   store i256 %[[T99]], i256* %[[T03]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME:  [[$F_ID_5:[0-9a-zA-Z_\.]+]]([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %subsig_[[X1:[0-9]+]], i256* %subsig_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_5]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subsig_[[X1]], i32 0
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subsig_[[X2]], i32 0
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T01]], align 4
//CHECK-NEXT:   %[[T98:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T02]], i256 888)
//CHECK-NEXT:   store i256 %[[T98]], i256* %[[T00]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T04]], align 4
//CHECK-NEXT:   %[[T99:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T05]], i256 1)
//CHECK-NEXT:   store i256 %[[T99]], i256* %[[T03]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME:  [[$F_ID_1:[0-9a-zA-Z_\.]+\.T]]([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %var_[[X1:[0-9]+]], i256* %var_[[X2:[0-9]+]], i256* %var_[[X3:[0-9]+]], i256* %var_[[X4:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %fold_true1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_true1:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 0, i256* %[[T00]], align 4
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_[[X1]], i32 0
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T01]] to [0 x i256]*
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T02]], i32 0, i256 0
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_[[X2]], i32 0
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T04]] to [0 x i256]*
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T05]], i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_4]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %[[T03]], i256* %[[T06]])
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_[[X1]], i32 0
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T07]] to [0 x i256]*
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T08]], i32 0, i256 0
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_[[X2]], i32 0
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T10]] to [0 x i256]*
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T11]], i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_4]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %[[T09]], i256* %[[T12]])
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_[[X1]], i32 0
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T13]] to [0 x i256]*
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T14]], i32 0, i256 0
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_[[X2]], i32 0
//CHECK-NEXT:   %[[T17:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T16]] to [0 x i256]*
//CHECK-NEXT:   %[[T18:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T17]], i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_4]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %[[T15]], i256* %[[T18]])
//CHECK-NEXT:   %[[T19:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_[[X1]], i32 0
//CHECK-NEXT:   %[[T20:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T19]] to [0 x i256]*
//CHECK-NEXT:   %[[T21:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T20]], i32 0, i256 0
//CHECK-NEXT:   %[[T22:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_[[X2]], i32 0
//CHECK-NEXT:   %[[T23:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T22]] to [0 x i256]*
//CHECK-NEXT:   %[[T24:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T23]], i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_4]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %[[T21]], i256* %[[T24]])
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T25:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %[[T26:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %[[T27:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T26]], align 4
//CHECK-NEXT:   %[[T98:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T27]], i256 1)
//CHECK-NEXT:   store i256 %[[T98]], i256* %[[T25]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME:  [[$F_ID_2:[0-9a-zA-Z_\.]+\.F]]([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %var_[[X1:[0-9]+]], i256* %var_[[X2:[0-9]+]], i256* %var_[[X3:[0-9]+]], i256* %var_[[X4:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2]]:
//CHECK-NEXT:   br label %fold_false1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_false1:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 0, i256* %[[T00]], align 4
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_[[X3]], i32 0
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T01]] to [0 x i256]*
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T02]], i32 0, i256 0
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_[[X4]], i32 0
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T04]] to [0 x i256]*
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T05]], i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_5]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %[[T03]], i256* %[[T06]])
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_[[X3]], i32 0
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T07]] to [0 x i256]*
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T08]], i32 0, i256 0
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_[[X4]], i32 0
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T10]] to [0 x i256]*
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T11]], i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_5]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %[[T09]], i256* %[[T12]])
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T14]], align 4
//CHECK-NEXT:   %[[T98:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T15]], i256 1)
//CHECK-NEXT:   store i256 %[[T98]], i256* %[[T13]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }

//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME:  [[$F_ID_3:[0-9a-zA-Z_\.]+\.F]]([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %var_[[X1:[0-9]+]], i256* %var_[[X2:[0-9]+]], i256* %var_[[X3:[0-9]+]], i256* %var_[[X4:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_3]]:
//CHECK-NEXT:   br label %fold_false1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_false1:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 0, i256* %[[T00]], align 4
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_[[X3]], i32 0
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T01]] to [0 x i256]*
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T02]], i32 0, i256 0
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_[[X4]], i32 0
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T04]] to [0 x i256]*
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T05]], i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_5]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %[[T03]], i256* %[[T06]])
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_[[X3]], i32 0
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T07]] to [0 x i256]*
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T08]], i32 0, i256 0
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_[[X4]], i32 0
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T10]] to [0 x i256]*
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T11]], i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_5]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %[[T09]], i256* %[[T12]])
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_[[X3]], i32 0
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T13]] to [0 x i256]*
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T14]], i32 0, i256 0
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_[[X4]], i32 0
//CHECK-NEXT:   %[[T17:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T16]] to [0 x i256]*
//CHECK-NEXT:   %[[T18:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T17]], i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_5]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %[[T15]], i256* %[[T18]])
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T19:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %[[T20:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %[[T21:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T20]], align 4
//CHECK-NEXT:   %[[T98:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T21]], i256 1)
//CHECK-NEXT:   store i256 %[[T98]], i256* %[[T19]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @InnerConditional12_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK:      unrolled_loop7:
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T08]], i32 0, i256 1
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T10]], i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T07]], [0 x i256]* %0, i256* %[[T09]], i256* %[[T11]], i256* null, i256* null)
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T13]], i32 0, i256 2
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T15]], i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T12]], [0 x i256]* %0, i256* %[[T14]], i256* %[[T16]], i256* null, i256* null)
//CHECK-NEXT:   %[[T17:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T18:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T19:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T18]], i32 0, i256 3
//CHECK-NEXT:   %[[T20:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T21:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T20]], i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T17]], [0 x i256]* %0, i256* null, i256* null, i256* %[[T19]], i256* %[[T21]])
//CHECK-NEXT:   %[[T22:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T23:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T24:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T23]], i32 0, i256 4
//CHECK-NEXT:   %[[T25:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T26:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T25]], i32 0, i256 4
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_3]]([0 x i256]* %[[T22]], [0 x i256]* %0, i256* null, i256* null, i256* %[[T24]], i256* %[[T26]])
//CHECK-NEXT:   br label %store8
