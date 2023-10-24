pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// Like SubCmps1 but simpler (no constraints and fewer operations)
template IsZero() {
    signal input in;
    signal output out;
    out <-- -in;
}

template SubCmps0B(n) {
    signal input ins[n];
    signal output outs[n];
    var temp;
    component zeros[n];
    for (var i = 0; i < n; i++) {
        zeros[i] = IsZero();
        zeros[i].in <-- ins[i];     //load(fix)+store(subcmp)
        outs[i] <-- zeros[i].out;   //load(subcmp)+store(fix)
        temp = zeros[i].out;
                                    //increment iteration variable
    }
}

component main = SubCmps0B(2);

//CHECK-LABEL: define void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %subfix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]], i256* %fix_[[X3:[0-9]+]],
//CHECK-SAME: i256* %subfix_[[X4:[0-9]+]], i256* %subfix_[[X5:[0-9]+]], [0 x i256]* %sub_[[X5]], i256* %subc_[[X5]]){{.*}} {
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
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %sub_[[X5]], i32 0
//CHECK-NEXT:   call void @IsZero_0_run([0 x i256]* %sub_[[X5]])
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %4 = getelementptr i256, i256* %subfix_[[X4]], i32 0
//CHECK-NEXT:   %5 = load i256, i256* %4, align 4
//CHECK-NEXT:   %6 = getelementptr i256, i256* %fix_[[X3]], i32 0
//CHECK-NEXT:   store i256 %5, i256* %6, align 4
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %7 = getelementptr i256, i256* %subfix_[[X5]], i32 0
//CHECK-NEXT:   %8 = load i256, i256* %7, align 4
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 %8, i256* %9, align 4
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %10 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %11 = load i256, i256* %10, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %11, i256 1)
//CHECK-NEXT:   %12 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 %call.fr_add, i256* %12, align 4
//CHECK-NEXT:   br label %return6
//CHECK-EMPTY: 
//CHECK-NEXT: return6:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @IsZero_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [0 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:   %2 = load i256, i256* %1, align 4
//CHECK-NEXT:   %call.fr_neg = call i256 @fr_neg(i256 %2)
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %call.fr_neg, i256* %3, align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define void @SubCmps0B_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [3 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [2 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 2, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %create_cmp2
//CHECK-EMPTY: 
//CHECK-NEXT: create_cmp2:
//CHECK-NEXT:   %[[T02:[0-9]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0
//CHECK-NEXT:   call void @IsZero_0_build({ [0 x i256]*, i32 }* %[[T02]])
//CHECK-NEXT:   %[[T03:[0-9]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1
//CHECK-NEXT:   call void @IsZero_0_build({ [0 x i256]*, i32 }* %[[T03]])
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T04:[0-9]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T04]], align 4
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %[[T05:[0-9]+]] = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 0, i256* %[[T05]], align 4
//CHECK-NEXT:   br label %unrolled_loop5
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop5:
//CHECK-NEXT:   %[[T06:[0-9]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T07:[0-9]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T08:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T07]], align 8
//CHECK-NEXT:   %[[T09:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T08]], i32 0
//CHECK-NEXT:   %[[T10:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T09]], i32 0, i256 1
//CHECK-NEXT:   %[[T11:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   %[[T12:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   %[[T13:[0-9]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T14:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T13]], align 8
//CHECK-NEXT:   %[[T15:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T14]], i32 0
//CHECK-NEXT:   %[[T16:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T15]], i32 0, i256 0
//CHECK-NEXT:   %[[T17:[0-9]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T18:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T17]], align 8
//CHECK-NEXT:   %[[T19:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T18]], i32 0
//CHECK-NEXT:   %[[T20:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T19]], i32 0, i256 0
//CHECK-NEXT:   %[[T21:[0-9]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T22:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T21]], align 8
//CHECK-NEXT:   %[[T23:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T22]], i32 0
//CHECK-NEXT:   %[[T24:[0-9]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %[[T25:[0-9]+]] = bitcast i32* %[[T24]] to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T06]], [0 x i256]* %0, i256* %[[T10]], i256* %[[T11]], i256* %[[T12]], i256* %[[T16]], i256* %[[T20]], [0 x i256]* %[[T23]], i256* %[[T25]])
//CHECK-NEXT:   %[[T26:[0-9]+]] = bitcast [3 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T27:[0-9]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T28:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T27]], align 8
//CHECK-NEXT:   %[[T29:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T28]], i32 0
//CHECK-NEXT:   %[[T30:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T29]], i32 0, i256 1
//CHECK-NEXT:   %[[T31:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   %[[T32:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %[[T33:[0-9]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T34:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T33]], align 8
//CHECK-NEXT:   %[[T35:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T34]], i32 0
//CHECK-NEXT:   %[[T36:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T35]], i32 0, i256 0
//CHECK-NEXT:   %[[T37:[0-9]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T38:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T37]], align 8
//CHECK-NEXT:   %[[T39:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T38]], i32 0
//CHECK-NEXT:   %[[T40:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T39]], i32 0, i256 0
//CHECK-NEXT:   %[[T41:[0-9]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T42:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T41]], align 8
//CHECK-NEXT:   %[[T43:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T42]], i32 0
//CHECK-NEXT:   %[[T44:[0-9]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %[[T45:[0-9]+]] = bitcast i32* %[[T44]] to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T26]], [0 x i256]* %0, i256* %[[T30]], i256* %[[T31]], i256* %[[T32]], i256* %[[T36]], i256* %[[T40]], [0 x i256]* %[[T43]], i256* %[[T45]])
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
