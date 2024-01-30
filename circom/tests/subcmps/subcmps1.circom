pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template IsZero() {
    signal input in;        // subcmp signal 1
    signal output out;      // subcmp signal 0

    signal inv;

    inv <-- in != 0 ? 1 / in : 0;

    out <== -in * inv + 1;
    in * out === 0;
}

// Simple circuit that returns what signals are equal to 0
template SubCmps1(n) {
    signal input ins[n];
    signal output outs[n];

    component zeros[n];
    var i;
    for (i = 0; i < n; i++) {
        zeros[i] = IsZero();
        zeros[i].in <== ins[i];
        outs[i] <== zeros[i].out;
    }
}

component main = SubCmps1(3);

// %0 (i.e. signal arena) = [ outs[0], outs[1], outs[2], ins[0], ins[1], ins[2] ]
// %lvars =  [ n, i ]
// %subcmps = [ IsZero[0]{signals=[out,in,inv]}, IsZero[1]{SAME} ]
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+\.T}}([0 x i256]* %lvars, [0 x i256]* %signals, 
//CHECK-SAME: i256* %subsig_[[X1:[0-9]+]], i256* %sig_[[X2:[0-9]+]], i256* %sig_[[X3:[0-9]+]],
//CHECK-SAME: i256* %subsig_[[X4:[0-9]+]], [0 x i256]* %sub_[[X4]], i256* %subc_[[X4]]){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID:[0-9]+\.T]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr i256, i256* %sig_[[X2]], i32 0
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %2 = getelementptr i256, i256* %subsig_[[X1]], i32 0
//CHECK-NEXT:   store i256 %1, i256* %2, align 4
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %1, i256 %3, i1* %constraint)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %4 = load i256, i256* %subc_[[X4]], align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %4, i256 1)
//CHECK-NEXT:   %5 = getelementptr i256, i256* %subc_[[X4]], i32 0
//CHECK-NEXT:   store i256 %call.fr_sub, i256* %5, align 4
//CHECK-NEXT:   br label %fold_true3
//CHECK-EMPTY: 
//CHECK-NEXT: fold_true3:
//CHECK-NEXT:   call void @IsZero_0_run([0 x i256]* %sub_[[X4]])
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %6 = getelementptr i256, i256* %subsig_[[X4]], i32 0
//CHECK-NEXT:   %7 = load i256, i256* %6, align 4
//CHECK-NEXT:   %8 = getelementptr i256, i256* %sig_[[X3]], i32 0
//CHECK-NEXT:   store i256 %7, i256* %8, align 4
//CHECK-NEXT:   %9 = load i256, i256* %8, align 4
//CHECK-NEXT:   %constraint1 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %7, i256 %9, i1* %constraint1)
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %10 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %11 = load i256, i256* %10, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %11, i256 1)
//CHECK-NEXT:   %12 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 %call.fr_add, i256* %12, align 4
//CHECK-NEXT:   br label %return6
//CHECK-EMPTY: 
//CHECK-NEXT: return6:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @SubCmps1_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK:      unrolled_loop5:
//CHECK-NEXT:   %[[T07:[0-9]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T08:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T09:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T08]], align 8
//CHECK-NEXT:   %[[T10:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T09]], i32 0
//CHECK-NEXT:   %[[T11:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T10]], i32 0, i256 1
//CHECK-NEXT:   %[[T12:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   %[[T13:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   %[[T14:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T15:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T14]], align 8
//CHECK-NEXT:   %[[T16:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T15]], i32 0
//CHECK-NEXT:   %[[T17:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T16]], i32 0, i256 0
//CHECK-NEXT:   %[[T18:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[T19:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T18]], align 8
//CHECK-NEXT:   %[[T20:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T19]], i32 0
//CHECK-NEXT:   %[[T21:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
//CHECK-NEXT:   %[[T22:[0-9]+]] = bitcast i32* %[[T21]] to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID]]([0 x i256]* %[[T07]], [0 x i256]* %0, i256* %[[T11]], i256* %[[T12]], i256* %[[T13]], i256* %[[T17]], [0 x i256]* %[[T20]], i256* %[[T22]])
//CHECK-NEXT:   %[[T28:[0-9]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T29:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T30:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T29]], align 8
//CHECK-NEXT:   %[[T31:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T30]], i32 0
//CHECK-NEXT:   %[[T32:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T31]], i32 0, i256 1
//CHECK-NEXT:   %[[T33:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 4
//CHECK-NEXT:   %[[T34:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   %[[T35:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T36:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T35]], align 8
//CHECK-NEXT:   %[[T37:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T36]], i32 0
//CHECK-NEXT:   %[[T38:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T37]], i32 0, i256 0
//CHECK-NEXT:   %[[T39:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 0
//CHECK-NEXT:   %[[T40:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T39]], align 8
//CHECK-NEXT:   %[[T41:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T40]], i32 0
//CHECK-NEXT:   %[[T42:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 1, i32 1
//CHECK-NEXT:   %[[T43:[0-9]+]] = bitcast i32* %[[T42]] to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID]]([0 x i256]* %[[T28]], [0 x i256]* %0, i256* %[[T32]], i256* %[[T33]], i256* %[[T34]], i256* %[[T38]], [0 x i256]* %[[T41]], i256* %[[T43]])
//CHECK-NEXT:   %[[T49:[0-9]+]] = bitcast [2 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T50:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %[[T51:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T50]], align 8
//CHECK-NEXT:   %[[T52:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T51]], i32 0
//CHECK-NEXT:   %[[T53:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T52]], i32 0, i256 1
//CHECK-NEXT:   %[[T54:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 5
//CHECK-NEXT:   %[[T55:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   %[[T56:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %[[T57:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T56]], align 8
//CHECK-NEXT:   %[[T58:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T57]], i32 0
//CHECK-NEXT:   %[[T59:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T58]], i32 0, i256 0
//CHECK-NEXT:   %[[T60:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 0
//CHECK-NEXT:   %[[T61:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[T60]], align 8
//CHECK-NEXT:   %[[T62:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[T61]], i32 0
//CHECK-NEXT:   %[[T63:[0-9]+]] = getelementptr [3 x { [0 x i256]*, i32 }], [3 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 2, i32 1
//CHECK-NEXT:   %[[T64:[0-9]+]] = bitcast i32* %[[T63]] to i256*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID]]([0 x i256]* %[[T49]], [0 x i256]* %0, i256* %[[T53]], i256* %[[T54]], i256* %[[T55]], i256* %[[T59]], [0 x i256]* %[[T62]], i256* %[[T64]])
//CHECK-NEXT:   br label %prologue
