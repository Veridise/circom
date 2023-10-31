pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// Like SubCmps1 but simpler (no constraints and fewer operations)
template IsZero() {
    signal input in;
    signal output out;
    out <-- -in;
}

template SubCmps0A(n) {
    signal input ins[n];
    signal output outs[n];
    
    component zeros[n];
    for (var i = 0; i < n; i++) {
        zeros[i] = IsZero();
        zeros[i].in <-- ins[i];     //load(fix)+store(subcmp)
        outs[i] <-- zeros[i].out;   //load(subcmp)+store(fix)
                                    //increment iteration variable
    }
}

component main = SubCmps0A(2);

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+\.T}}([0 x i256]* %lvars, [0 x i256]* %signals, 
//CHECK-SAME: i256* %subfix_[[X1:[0-9]+]], i256* %fix_[[X2:[0-9]+]], i256* %fix_[[X3:[0-9]+]],
//CHECK-SAME: i256* %subfix_[[X4:[0-9]+]], [0 x i256]* %sub_[[X4]], i256* %subc_[[X4]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9]+\.T]]:
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
//CHECK-NEXT:   %3 = load i256, i256* %subc_[[X4]], align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %3, i256 1)
//CHECK-NEXT:   %4 = getelementptr i256, i256* %subc_[[X4]], i32 0
//CHECK-NEXT:   store i256 %call.fr_sub, i256* %4, align 4
//CHECK-NEXT:   br label %fold_true3
//CHECK-EMPTY: 
//CHECK-NEXT: fold_true3:
//CHECK-NEXT:   call void @IsZero_0_run([0 x i256]* %sub_[[X4]])
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %5 = getelementptr i256, i256* %subfix_[[X4]], i32 0
//CHECK-NEXT:   %6 = load i256, i256* %5, align 4
//CHECK-NEXT:   %7 = getelementptr i256, i256* %fix_[[X3]], i32 0
//CHECK-NEXT:   store i256 %6, i256* %7, align 4
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %9 = load i256, i256* %8, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %9, i256 1)
//CHECK-NEXT:   %10 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 %call.fr_add, i256* %10, align 4
//CHECK-NEXT:   br label %return6
//CHECK-EMPTY: 
//CHECK-NEXT: return6:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @IsZero_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
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
//CHECK-LABEL: define{{.*}} void @SubCmps0A_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [2 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [2 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 0
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
//CHECK-NEXT:   %[[T04:[0-9]+]] = getelementptr [2 x i256], [2 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 0, i256* %[[T04]], align 4
//CHECK-NEXT:   br label %unrolled_loop4
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop4:
//CHECK-NEXT:   %[[T05:[0-9]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T06:[0-9]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T07:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T06]], align 8
//CHECK-NEXT:   %[[T08:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T07]], i32 0
//CHECK-NEXT:   %[[T09:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T08]], i32 0, i256 1
//CHECK-NEXT:   %[[T10:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   %[[T11:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   %[[T12:[0-9]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T13:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T12]], align 8
//CHECK-NEXT:   %[[T14:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T13]], i32 0
//CHECK-NEXT:   %[[T15:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T14]], i32 0, i256 0
//CHECK-NEXT:   %[[T16:[0-9]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T17:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T16]], align 8
//CHECK-NEXT:   %[[T18:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T17]], i32 0
//CHECK-NEXT:   %[[T19:[0-9]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %[[T20:[0-9]+]] = bitcast i32* %[[T19]] to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T05]], [0 x i256]* %0, i256* %[[T09]], i256* %[[T10]], i256* %[[T11]], i256* %[[T15]], [0 x i256]* %[[T18]], i256* %[[T20]])
//CHECK-NEXT:   %[[T21:[0-9]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T22:[0-9]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T23:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T22]], align 8
//CHECK-NEXT:   %[[T24:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T23]], i32 0
//CHECK-NEXT:   %[[T25:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T24]], i32 0, i256 1
//CHECK-NEXT:   %[[T26:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   %[[T27:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %[[T28:[0-9]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T29:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T28]], align 8
//CHECK-NEXT:   %[[T30:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T29]], i32 0
//CHECK-NEXT:   %[[T31:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T30]], i32 0, i256 0
//CHECK-NEXT:   %[[T32:[0-9]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T33:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T32]], align 8
//CHECK-NEXT:   %[[T34:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T33]], i32 0
//CHECK-NEXT:   %[[T35:[0-9]+]] = getelementptr [2 x { [0 x i256]*, i32 }], [2 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %[[T36:[0-9]+]] = bitcast i32* %[[T35]] to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T21]], [0 x i256]* %0, i256* %[[T25]], i256* %[[T26]], i256* %[[T27]], i256* %[[T31]], [0 x i256]* %[[T34]], i256* %[[T36]])
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
