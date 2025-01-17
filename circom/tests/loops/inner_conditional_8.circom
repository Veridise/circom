pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// like inner_conditional_7 but with 'i' and 'j' uses swapped (and a larger constant)
template InnerConditional8(N) {
    signal output out;

    var a[N];
    for (var i = 0; i < N; i++) {
        // Values of 'a' at the header per iteration:
        // i=0: [0, 0, 0, 0]
        // i=1: [1776, 0, 0, 0]
        // i=2: [1776, 1776, 0, 0]
        // i=3: [1776, 1776, 1776, 0]
        for (var j = 0; j < N; j++) {
            if (j > 1) {
                a[i] += 999;
            } else {
                a[i] -= 111;
            }
        }
    }
    // At this point, 'a[x] = 1776' for all 'x', so 'out = 3552'
    out <-- a[0] + a[1];
}

component main = InnerConditional8(4);

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9a-zA-Z_\.]+]]([0 x i256]* %lvars, [0 x i256]* %signals, 
//CHECK-SAME: i256* %var_[[X1:[0-9]+]], i256* %var_[[X2:[0-9]+]], i256* %var_[[X3:[0-9]+]], i256* %var_[[X4:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 0, i256* %[[T00]], align 4
//CHECK-NEXT:   br label %unrolled_loop2
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop2:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_0, i32 0
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T01]] to [0 x i256]*
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T02]], i32 0, i256 0
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_1, i32 0
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T04]] to [0 x i256]*
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T05]], i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2:[0-9a-zA-Z_\.]+\.F]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %[[T03]], i256* %[[T06]], i256* null, i256* null)
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_0, i32 0
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T07]] to [0 x i256]*
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T08]], i32 0, i256 0
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_1, i32 0
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T10]] to [0 x i256]*
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T11]], i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %[[T09]], i256* %[[T12]], i256* null, i256* null)
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_2, i32 0
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T13]] to [0 x i256]*
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T14]], i32 0, i256 0
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_3, i32 0
//CHECK-NEXT:   %[[T17:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T16]] to [0 x i256]*
//CHECK-NEXT:   %[[T18:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T17]], i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_3:[0-9a-zA-Z_\.]+\.T]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* null, i256* null, i256* %[[T15]], i256* %[[T18]])
//CHECK-NEXT:   %[[T19:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_2, i32 0
//CHECK-NEXT:   %[[T20:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T19]] to [0 x i256]*
//CHECK-NEXT:   %[[T21:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T20]], i32 0, i256 0
//CHECK-NEXT:   %[[T22:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_3, i32 0
//CHECK-NEXT:   %[[T23:[0-9a-zA-Z_\.]+]] = bitcast i256* %[[T22]] to [0 x i256]*
//CHECK-NEXT:   %[[T24:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T23]], i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_3]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* null, i256* null, i256* %[[T21]], i256* %[[T24]])
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T25:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %[[T26:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %[[T27:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T26]], align 4
//CHECK-NEXT:   %[[C05:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T27]], i256 1)
//CHECK-NEXT:   store i256 %[[C05]], i256* %[[T25]], align 4
//CHECK-NEXT:   br label %return4
//CHECK-EMPTY: 
//CHECK-NEXT: return4:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_2]]([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %subsig_[[X1:[0-9]+]], i256* %subsig_[[X2:[0-9]+]], i256* %subsig_[[X3:[0-9]+]], i256* %subsig_[[X4:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2]]:
//CHECK-NEXT:   br label %fold_false1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_false1:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subsig_[[X1]], i32 0
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subsig_[[X2]], i32 0
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T01]], align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %[[T02]], i256 111)
//CHECK-NEXT:   store i256 %call.fr_sub, i256* %[[T00]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T04]], align 4
//CHECK-NEXT:   %[[T98:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T05]], i256 1)
//CHECK-NEXT:   store i256 %[[T98]], i256* %[[T03]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_3]]([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %subsig_[[X1:[0-9]+]], i256* %subsig_[[X2:[0-9]+]], i256* %subsig_[[X3:[0-9]+]], i256* %subsig_[[X4:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_3]]:
//CHECK-NEXT:   br label %fold_true1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_true1:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subsig_[[X3]], i32 0
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %subsig_[[X4]], i32 0
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
//CHECK-LABEL: define{{.*}} void @InnerConditional8_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [7 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 4, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T02]], align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 0, i256* %[[T03]], align 4
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 0, i256* %[[T04]], align 4
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %[[T05]], align 4
//CHECK-NEXT:   br label %store6
//CHECK-EMPTY: 
//CHECK-NEXT: store6:
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr [7 x i256], [7 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 0, i256* %[[T06]], align 4
//CHECK-NEXT:   br label %unrolled_loop7
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop7:
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T08]], i32 0, i256 1
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T10]], i32 0, i256 1
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T12]], i32 0, i256 1
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T14]], i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T07]], [0 x i256]* %0, i256* %[[T09]], i256* %[[T11]], i256* %[[T13]], i256* %[[T15]])
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T17:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T18:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T17]], i32 0, i256 2
//CHECK-NEXT:   %[[T19:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T20:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T19]], i32 0, i256 2
//CHECK-NEXT:   %[[T21:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T22:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T21]], i32 0, i256 2
//CHECK-NEXT:   %[[T23:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T24:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T23]], i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T16]], [0 x i256]* %0, i256* %[[T18]], i256* %[[T20]], i256* %[[T22]], i256* %[[T24]])
//CHECK-NEXT:   %[[T25:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T26:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T27:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T26]], i32 0, i256 3
//CHECK-NEXT:   %[[T28:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T29:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T28]], i32 0, i256 3
//CHECK-NEXT:   %[[T30:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T31:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T30]], i32 0, i256 3
//CHECK-NEXT:   %[[T32:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T33:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T32]], i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T25]], [0 x i256]* %0, i256* %[[T27]], i256* %[[T29]], i256* %[[T31]], i256* %[[T33]])
//CHECK-NEXT:   %[[T34:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T35:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T36:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T35]], i32 0, i256 4
//CHECK-NEXT:   %[[T37:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T38:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T37]], i32 0, i256 4
//CHECK-NEXT:   %[[T39:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T40:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T39]], i32 0, i256 4
//CHECK-NEXT:   %[[T41:[0-9a-zA-Z_\.]+]] = bitcast [7 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T42:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T41]], i32 0, i256 4
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T34]], [0 x i256]* %0, i256* %[[T36]], i256* %[[T38]], i256* %[[T40]], i256* %[[T42]])
//CHECK-NEXT:   br label %store8
//CHECK-EMPTY: 
//CHECK-NEXT: store8:
//CHECK-NEXT:   %[[T43:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 3552, i256* %[[T43]], align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
