pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template InnerConditional7(N) {
    signal output out;

    var a[N];
    // NOTE: When processing the outer loop, the statements indexed with 'j' are determined
    //  NOT safe to move into a new function since 'j' is unknown. That results in the outer
    //  loop unrolling without extrating the body to a new function. Then the three copies
    //  of the inner loop are processed and their bodies are extracted to new functions and
    //  replaced with calls to those functions before unrolling. So it ends up creating
    //  three slightly different functions for this innermost body, one for each iteration
    //  of the outer loop. Within each of those functions, 'i' is a known fixed value.
    for (var i = 0; i < N; i++) {
        // Values of 'a' at the header per iteration:
        // i=0: [0, 0, 0, 0]
        // i=1: [-111, -111, -111]
        // i=2: [-222, -222, -222]
        // NOTE: Technically there are no negative values, it's instead wrapped modulo the field prime
        for (var j = 0; j < N; j++) {
            if (i > 1) {
                a[j] += 999;
            } else {
                a[j] -= 111;
            }
        }
    }
    // At this point, 'a[x] = 777' for all 'x', so 'out = 1554'
    out <-- a[0] + a[1];
}

component main = InnerConditional7(3);

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9a-zA-Z_\.]+\.F}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %var_[[X1:[0-9]+]], i256* %var_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9a-zA-Z_\.]+\.F]]:
//CHECK-NEXT:   br label %fold_false1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_false1:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_[[X1]], i32 0
//CHECK-NEXT:   store i256 21888242871839275222246405745257275088548364400416034343698204186575808495506, i256* %[[T02]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T03]], align 4
//CHECK-NEXT:   %[[C02:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T04]], i256 1)
//CHECK-NEXT:   store i256 %[[C02]], i256* %[[T05]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9a-zA-Z_\.]+\.F}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %var_[[X1:[0-9]+]], i256* %var_[[X2:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2:[0-9a-zA-Z_\.]+\.F]]:
//CHECK-NEXT:   br label %fold_false1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_false1:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_[[X1]], i32 0
//CHECK-NEXT:   store i256 21888242871839275222246405745257275088548364400416034343698204186575808495395, i256* %[[T00]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T02]], align 4
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T03]], i256 1)
//CHECK-NEXT:   store i256 %[[T04]], i256* %[[T01]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9a-zA-Z_\.]+\.T}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME: i256* %var_[[X1:[0-9]+]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_3:[0-9a-zA-Z_\.]+\.T]]:
//CHECK-NEXT:   br label %fold_true1
//CHECK-EMPTY: 
//CHECK-NEXT: fold_true1:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %var_[[X1]], i32 0
//CHECK-NEXT:   store i256 777, i256* %[[T00]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T01]], align 4
//CHECK-NEXT:   %[[C01:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T02]], i256 1)
//CHECK-NEXT:   store i256 %[[C01]], i256* %[[T03]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @InnerConditional7_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [6 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 3, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T02]], align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 0, i256* %[[T03]], align 4
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 0, i256* %[[T04]], align 4
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %[[T05]], align 4
//CHECK-NEXT:   br label %unrolled_loop6
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop6:
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 0, i256* %[[T06]], align 4
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T08]], i32 0, i256 1
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T10]], i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T07]], [0 x i256]* %0, i256* %[[T09]], i256* %[[T11]])
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T13]], i32 0, i256 2
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T15]], i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T12]], [0 x i256]* %0, i256* %[[T14]], i256* %[[T16]])
//CHECK-NEXT:   %[[T17:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T18:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T19:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T18]], i32 0, i256 3
//CHECK-NEXT:   %[[T20:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T21:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T20]], i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T17]], [0 x i256]* %0, i256* %[[T19]], i256* %[[T21]])
//CHECK-NEXT:   %[[T22:[0-9a-zA-Z_\.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %[[T22]], align 4
//CHECK-NEXT:   %[[T23:[0-9a-zA-Z_\.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 0, i256* %[[T23]], align 4
//CHECK-NEXT:   %[[T24:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T25:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T26:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T25]], i32 0, i256 1
//CHECK-NEXT:   %[[T27:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T28:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T27]], i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T24]], [0 x i256]* %0, i256* %[[T26]], i256* %[[T28]])
//CHECK-NEXT:   %[[T29:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T30:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T31:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T30]], i32 0, i256 2
//CHECK-NEXT:   %[[T32:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T33:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T32]], i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T29]], [0 x i256]* %0, i256* %[[T31]], i256* %[[T33]])
//CHECK-NEXT:   %[[T34:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T35:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T36:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T35]], i32 0, i256 3
//CHECK-NEXT:   %[[T37:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T38:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T37]], i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T34]], [0 x i256]* %0, i256* %[[T36]], i256* %[[T38]])
//CHECK-NEXT:   %[[T39:[0-9a-zA-Z_\.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 2, i256* %[[T39]], align 4
//CHECK-NEXT:   %[[T40:[0-9a-zA-Z_\.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 0, i256* %[[T40]], align 4
//CHECK-NEXT:   %[[T41:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T42:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T43:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T42]], i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_3]]([0 x i256]* %[[T41]], [0 x i256]* %0, i256* %[[T43]])
//CHECK-NEXT:   %[[T44:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T45:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T46:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T45]], i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_3]]([0 x i256]* %[[T44]], [0 x i256]* %0, i256* %[[T46]])
//CHECK-NEXT:   %[[T47:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T48:[0-9a-zA-Z_\.]+]] = bitcast [6 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T49:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[T48]], i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_3]]([0 x i256]* %[[T47]], [0 x i256]* %0, i256* %[[T49]])
//CHECK-NEXT:   %[[T50:[0-9a-zA-Z_\.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 3, i256* %[[T50]], align 4
//CHECK-NEXT:   br label %store7
//CHECK-EMPTY: 
//CHECK-NEXT: store7:
//CHECK-NEXT:   %[[T51:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 1554, i256* %[[T51]], align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
