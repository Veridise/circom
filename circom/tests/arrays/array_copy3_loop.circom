pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// Vector copy version of `array_copy3_vec.circom` test.
template Array3(n) {
    signal input inp[n][n];
    signal output out[n][n];

    for(var i = 0; i < n; i++) {
        for(var j = 0; j < n; j++) {
            out[i][j] <== inp[i][j];
        }
    }
}

component main = Array3(5);

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals, i256* %sig_0, i256* %sig_1){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9]+]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_0, i32 0
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_1, i32 0
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T01]], align 4
//CHECK-NEXT:   store i256 %[[T02]], i256* %[[T00]], align 4
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T00]], align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T02]], i256 %[[T03]], i1* %constraint)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T05]], align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %[[T06]], i256 1)
//CHECK-NEXT:   store i256 %call.fr_add, i256* %[[T04]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @Array3_0_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9a-zA-Z_\.]+]]){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [3 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 5, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T02]], align 4
//CHECK-NEXT:   br label %unrolled_loop3
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop3:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 0, i256* %[[T03]], align 4
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 0
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 25
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T04]], [0 x i256]* %[[ARG]], i256* %[[T05]], i256* %[[T06]])
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 1
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 26
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T07]], [0 x i256]* %[[ARG]], i256* %[[T08]], i256* %[[T09]])
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 2
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 27
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T10]], [0 x i256]* %[[ARG]], i256* %[[T11]], i256* %[[T12]])
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 3
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 28
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T13]], [0 x i256]* %[[ARG]], i256* %[[T14]], i256* %[[T15]])
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T17:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 4
//CHECK-NEXT:   %[[T18:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 29
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T16]], [0 x i256]* %[[ARG]], i256* %[[T17]], i256* %[[T18]])
//CHECK-NEXT:   %[[T19:[0-9a-zA-Z_\.]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 1, i256* %[[T19]], align 4
//CHECK-NEXT:   %[[T20:[0-9a-zA-Z_\.]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 0, i256* %[[T20]], align 4
//CHECK-NEXT:   %[[T21:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T22:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 5
//CHECK-NEXT:   %[[T23:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 30
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T21]], [0 x i256]* %[[ARG]], i256* %[[T22]], i256* %[[T23]])
//CHECK-NEXT:   %[[T24:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T25:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 6
//CHECK-NEXT:   %[[T26:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 31
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T24]], [0 x i256]* %[[ARG]], i256* %[[T25]], i256* %[[T26]])
//CHECK-NEXT:   %[[T27:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T28:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 7
//CHECK-NEXT:   %[[T29:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 32
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T27]], [0 x i256]* %[[ARG]], i256* %[[T28]], i256* %[[T29]])
//CHECK-NEXT:   %[[T30:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T31:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 8
//CHECK-NEXT:   %[[T32:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 33
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T30]], [0 x i256]* %[[ARG]], i256* %[[T31]], i256* %[[T32]])
//CHECK-NEXT:   %[[T33:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T34:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 9
//CHECK-NEXT:   %[[T35:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 34
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T33]], [0 x i256]* %[[ARG]], i256* %[[T34]], i256* %[[T35]])
//CHECK-NEXT:   %[[T36:[0-9a-zA-Z_\.]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 2, i256* %[[T36]], align 4
//CHECK-NEXT:   %[[T37:[0-9a-zA-Z_\.]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 0, i256* %[[T37]], align 4
//CHECK-NEXT:   %[[T38:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T39:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 10
//CHECK-NEXT:   %[[T40:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 35
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T38]], [0 x i256]* %[[ARG]], i256* %[[T39]], i256* %[[T40]])
//CHECK-NEXT:   %[[T41:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T42:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 11
//CHECK-NEXT:   %[[T43:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 36
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T41]], [0 x i256]* %[[ARG]], i256* %[[T42]], i256* %[[T43]])
//CHECK-NEXT:   %[[T44:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T45:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 12
//CHECK-NEXT:   %[[T46:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 37
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T44]], [0 x i256]* %[[ARG]], i256* %[[T45]], i256* %[[T46]])
//CHECK-NEXT:   %[[T47:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T48:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 13
//CHECK-NEXT:   %[[T49:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 38
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T47]], [0 x i256]* %[[ARG]], i256* %[[T48]], i256* %[[T49]])
//CHECK-NEXT:   %[[T50:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T51:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 14
//CHECK-NEXT:   %[[T52:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 39
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T50]], [0 x i256]* %[[ARG]], i256* %[[T51]], i256* %[[T52]])
//CHECK-NEXT:   %[[T53:[0-9a-zA-Z_\.]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 3, i256* %[[T53]], align 4
//CHECK-NEXT:   %[[T54:[0-9a-zA-Z_\.]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 0, i256* %[[T54]], align 4
//CHECK-NEXT:   %[[T55:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T56:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 15
//CHECK-NEXT:   %[[T57:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 40
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T55]], [0 x i256]* %[[ARG]], i256* %[[T56]], i256* %[[T57]])
//CHECK-NEXT:   %[[T58:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T59:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 16
//CHECK-NEXT:   %[[T60:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 41
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T58]], [0 x i256]* %[[ARG]], i256* %[[T59]], i256* %[[T60]])
//CHECK-NEXT:   %[[T61:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T62:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 17
//CHECK-NEXT:   %[[T63:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 42
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T61]], [0 x i256]* %[[ARG]], i256* %[[T62]], i256* %[[T63]])
//CHECK-NEXT:   %[[T64:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T65:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 18
//CHECK-NEXT:   %[[T66:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 43
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T64]], [0 x i256]* %[[ARG]], i256* %[[T65]], i256* %[[T66]])
//CHECK-NEXT:   %[[T67:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T68:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 19
//CHECK-NEXT:   %[[T69:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 44
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T67]], [0 x i256]* %[[ARG]], i256* %[[T68]], i256* %[[T69]])
//CHECK-NEXT:   %[[T70:[0-9a-zA-Z_\.]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 4, i256* %[[T70]], align 4
//CHECK-NEXT:   %[[T71:[0-9a-zA-Z_\.]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 0, i256* %[[T71]], align 4
//CHECK-NEXT:   %[[T72:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T73:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 20
//CHECK-NEXT:   %[[T74:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 45
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T72]], [0 x i256]* %[[ARG]], i256* %[[T73]], i256* %[[T74]])
//CHECK-NEXT:   %[[T75:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T76:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 21
//CHECK-NEXT:   %[[T77:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 46
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T75]], [0 x i256]* %[[ARG]], i256* %[[T76]], i256* %[[T77]])
//CHECK-NEXT:   %[[T78:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T79:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 22
//CHECK-NEXT:   %[[T80:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 47
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T78]], [0 x i256]* %[[ARG]], i256* %[[T79]], i256* %[[T80]])
//CHECK-NEXT:   %[[T81:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T82:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 23
//CHECK-NEXT:   %[[T83:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 48
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T81]], [0 x i256]* %[[ARG]], i256* %[[T82]], i256* %[[T83]])
//CHECK-NEXT:   %[[T84:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T85:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 24
//CHECK-NEXT:   %[[T86:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i256 49
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T84]], [0 x i256]* %[[ARG]], i256* %[[T85]], i256* %[[T86]])
//CHECK-NEXT:   %[[T87:[0-9a-zA-Z_\.]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 5, i256* %[[T87]], align 4
//CHECK-NEXT:   br label %prologue
