pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*     // TEMPORARY: because EXTRACT_LOOP_BODY_TO_NEW_FUNC == false

template Add() {
    signal input in1;
    signal input in2;
    signal output out;
    out <-- in1 + in2;
}

template SubCmps0D(n) {
    signal input ins[n];
    signal output outs[n];

    component a[n];
    for (var i = 0; i < n; i++) {
        a[i] = Add();
        a[i].in1 <-- ins[i];
        a[i].in2 <-- ins[i];
        outs[i] <-- a[i].out;
    }
}

component main = SubCmps0D(3);

//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %subfix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]], i256* %subfix_[[X3:[0-9]+]],
//CHECK-SAME: i256* %fix_[[X4:[0-9]+]], i256* %fix_[[X5:[0-9]+]], i256* %subfix_[[X6:[0-9]+]], [0 x i256]* %sub_[[X6]], i256* %subc_[[X6]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr i256, i256* %fix_[[X2]], i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr i256, i256* %subfix_[[X1]], i32 0
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %sub_[[X6]], i32 0
//CHECK-NEXT:   call void @Add_0_run([0 x i256]* %sub_[[X6]])
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %4 = getelementptr i256, i256* %fix_[[X4]], i32 0
//CHECK-NEXT:   %5 = load i256, i256* %4, align 4
//CHECK-NEXT:   %6 = getelementptr i256, i256* %subfix_[[X3]], i32 0
//CHECK-NEXT:   store i256 %5, i256* %6, align 4
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %7 = getelementptr [0 x i256], [0 x i256]* %sub_[[X6]], i32 0
//CHECK-NEXT:   call void @Add_0_run([0 x i256]* %sub_[[X6]])
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %8 = getelementptr i256, i256* %subfix_[[X6]], i32 0
//CHECK-NEXT:   %9 = load i256, i256* %8, align 4
//CHECK-NEXT:   %10 = getelementptr i256, i256* %fix_[[X5]], i32 0
//CHECK-NEXT:   store i256 %9, i256* %10, align 4
//CHECK-NEXT:   br label %store6
//CHECK-EMPTY: 
//CHECK-NEXT: store6:
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %12 = load i256, i256* %11, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %12, i256 1)
//CHECK-NEXT:   %13 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 %call.fr_add, i256* %13, align 4
//CHECK-NEXT:   br label %return7
//CHECK-EMPTY: 
//CHECK-NEXT: return7:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @Add_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [0 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:   %2 = load i256, i256* %1, align 4
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 2
//CHECK-NEXT:   %4 = load i256, i256* %3, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %2, i256 %4)
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %call.fr_add, i256* %5, align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @SubCmps0D_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [2 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [3 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 3, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %create_cmp2
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp2:
//CHECK-NEXT:   %[[T02:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0
//CHECK-NEXT:   call void @Add_0_build({ [0 x i256]*, i32 }* %[[T02]])
//CHECK-NEXT:   %[[T03:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1
//CHECK-NEXT:   call void @Add_0_build({ [0 x i256]*, i32 }* %[[T03]])
//CHECK-NEXT:   %[[T04:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2
//CHECK-NEXT:   call void @Add_0_build({ [0 x i256]*, i32 }* %[[T04]])
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T05:[0-9]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T05]], align 4
//CHECK-NEXT:   br label %unrolled_loop4
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop4:
//CHECK-NEXT:   %[[T06:[0-9]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T07:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T08:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T07]], align 8
//CHECK-NEXT:   %[[T09:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T08]], i32 0
//CHECK-NEXT:   %[[T10:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T09]], i32 0, i256 1
//CHECK-NEXT:   %[[T11:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   %[[T12:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T13:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T12]], align 8
//CHECK-NEXT:   %[[T14:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T13]], i32 0
//CHECK-NEXT:   %[[T15:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T14]], i32 0, i256 2
//CHECK-NEXT:   %[[T16:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   %[[T17:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   %[[T18:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T19:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T18]], align 8
//CHECK-NEXT:   %[[T20:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T19]], i32 0
//CHECK-NEXT:   %[[T21:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T20]], i32 0, i256 0
//CHECK-NEXT:   %[[T22:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T23:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T22]], align 8
//CHECK-NEXT:   %[[T24:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T23]], i32 0
//CHECK-NEXT:   %[[T25:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %[[T26:[0-9]+]] = bitcast i32* %[[T25]] to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T06]], [0 x i256]* %0, i256* %[[T10]], i256* %[[T11]], i256* %[[T15]], i256* %[[T16]], i256* %[[T17]], i256* %[[T21]], [0 x i256]* %[[T24]], i256* %[[T26]])
//CHECK-NEXT:   %[[T27:[0-9]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T28:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T29:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T28]], align 8
//CHECK-NEXT:   %[[T30:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T29]], i32 0
//CHECK-NEXT:   %[[T31:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T30]], i32 0, i256 1
//CHECK-NEXT:   %[[T32:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 4
//CHECK-NEXT:   %[[T33:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T34:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T33]], align 8
//CHECK-NEXT:   %[[T35:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T34]], i32 0
//CHECK-NEXT:   %[[T36:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T35]], i32 0, i256 2
//CHECK-NEXT:   %[[T37:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 4
//CHECK-NEXT:   %[[T38:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %[[T39:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T40:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T39]], align 8
//CHECK-NEXT:   %[[T41:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T40]], i32 0
//CHECK-NEXT:   %[[T42:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T41]], i32 0, i256 0
//CHECK-NEXT:   %[[T43:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T44:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T43]], align 8
//CHECK-NEXT:   %[[T45:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T44]], i32 0
//CHECK-NEXT:   %[[T46:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %[[T47:[0-9]+]] = bitcast i32* %[[T46]] to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T27]], [0 x i256]* %0, i256* %[[T31]], i256* %[[T32]], i256* %[[T36]], i256* %[[T37]], i256* %[[T38]], i256* %[[T42]], [0 x i256]* %[[T45]], i256* %[[T47]])
//CHECK-NEXT:   %[[T48:[0-9]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T49:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %[[T50:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T49]], align 8
//CHECK-NEXT:   %[[T51:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T50]], i32 0
//CHECK-NEXT:   %[[T52:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T51]], i32 0, i256 1
//CHECK-NEXT:   %[[T53:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 5
//CHECK-NEXT:   %[[T54:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %[[T55:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T54]], align 8
//CHECK-NEXT:   %[[T56:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T55]], i32 0
//CHECK-NEXT:   %[[T57:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T56]], i32 0, i256 2
//CHECK-NEXT:   %[[T58:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 5
//CHECK-NEXT:   %[[T59:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   %[[T60:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %[[T61:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T60]], align 8
//CHECK-NEXT:   %[[T62:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T61]], i32 0
//CHECK-NEXT:   %[[T63:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T62]], i32 0, i256 0
//CHECK-NEXT:   %[[T64:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %[[T65:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T64]], align 8
//CHECK-NEXT:   %[[T66:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T65]], i32 0
//CHECK-NEXT:   %[[T67:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 1
//CHECK-NEXT:   %[[T68:[0-9]+]] = bitcast i32* %[[T67]] to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T48]], [0 x i256]* %0, i256* %[[T52]], i256* %[[T53]], i256* %[[T57]], i256* %[[T58]], i256* %[[T59]], i256* %[[T63]], [0 x i256]* %[[T66]], i256* %[[T68]])
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
