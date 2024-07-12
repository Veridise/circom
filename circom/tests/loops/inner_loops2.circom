pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template InnerLoops(n) {
    signal input a[n];
    var b[n];

    // Manually unrolled loop from inner_loops.circom
    //for (var i = 0; i < n; i++) {

    var i = 0;
    for (var j = 0; j <= i; j++) {
        b[i] = a[i - j];
    }
    i++; // 1
    for (var j = 0; j <= i; j++) {
        b[i] = a[i - j];
    }
    i++; // 2
    for (var j = 0; j <= i; j++) {
        b[i] = a[i - j];
    }
    i++; // 3
    for (var j = 0; j <= i; j++) {
        b[i] = a[i - j];
    }
    i++; // 4
    for (var j = 0; j <= i; j++) {
        b[i] = a[i - j];
    }
    i++; // 5
}

component main = InnerLoops(5);

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_5:[0-9a-zA-Z_\.]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %sig_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_5]]:
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_0, i32 0
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T00]], align 4
//CHECK-NEXT:   store i256 %[[T01]], i256* %[[T02]], align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T03]], align 4
//CHECK-NEXT:   %[[C01:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T04]], i256 1)
//CHECK-NEXT:   store i256 %[[C01]], i256* %[[T05]], align 4
//CHECK-NEXT:   br label %return{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: return{{[0-9]+}}:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_4:[0-9a-zA-Z_\.]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %sig_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_4]]:
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_0, i32 0
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T00]], align 4
//CHECK-NEXT:   store i256 %[[T01]], i256* %[[T02]], align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T03]], align 4
//CHECK-NEXT:   %[[C01:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T04]], i256 1)
//CHECK-NEXT:   store i256 %[[C01]], i256* %[[T05]], align 4
//CHECK-NEXT:   br label %return{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: return{{[0-9]+}}:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_3:[0-9a-zA-Z_\.]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %sig_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_3]]:
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_0, i32 0
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T00]], align 4
//CHECK-NEXT:   store i256 %[[T01]], i256* %[[T02]], align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T03]], align 4
//CHECK-NEXT:   %[[C01:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T04]], i256 1)
//CHECK-NEXT:   store i256 %[[C01]], i256* %[[T05]], align 4
//CHECK-NEXT:   br label %return{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: return{{[0-9]+}}:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_2:[0-9a-zA-Z_\.]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %sig_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_2]]:
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_0, i32 0
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T00]], align 4
//CHECK-NEXT:   store i256 %[[T01]], i256* %[[T02]], align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T03]], align 4
//CHECK-NEXT:   %[[C01:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T04]], i256 1)
//CHECK-NEXT:   store i256 %[[C01]], i256* %[[T05]], align 4
//CHECK-NEXT:   br label %return{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: return{{[0-9]+}}:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @InnerLoops_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK:      unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr [8 x i256], [8 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T02]], align 4
//CHECK-NEXT:   store i256 %[[T03]], i256* %[[T01]], align 4
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr [8 x i256], [8 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   store i256 1, i256* %[[T04]], align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = getelementptr [8 x i256], [8 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 1, i256* %[[T10]], align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = getelementptr [8 x i256], [8 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   store i256 0, i256* %[[T11]], align 4
//CHECK-NEXT:   br label %unrolled_loop{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T12]], [0 x i256]* %0, i256* %[[T13]])
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_\.]+]] = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_2]]([0 x i256]* %[[T14]], [0 x i256]* %0, i256* %[[T15]])
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_\.]+]] = getelementptr [8 x i256], [8 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 2, i256* %[[T16]], align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %[[T17:[0-9a-zA-Z_\.]+]] = getelementptr [8 x i256], [8 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   store i256 0, i256* %[[T17]], align 4
//CHECK-NEXT:   br label %unrolled_loop{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %[[T18:[0-9a-zA-Z_\.]+]] = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T19:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_3]]([0 x i256]* %[[T18]], [0 x i256]* %0, i256* %[[T19]])
//CHECK-NEXT:   %[[T20:[0-9a-zA-Z_\.]+]] = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T21:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_3]]([0 x i256]* %[[T20]], [0 x i256]* %0, i256* %[[T21]])
//CHECK-NEXT:   %[[T22:[0-9a-zA-Z_\.]+]] = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T23:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_3]]([0 x i256]* %[[T22]], [0 x i256]* %0, i256* %[[T23]])
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %[[T24:[0-9a-zA-Z_\.]+]] = getelementptr [8 x i256], [8 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 3, i256* %[[T24]], align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %[[T25:[0-9a-zA-Z_\.]+]] = getelementptr [8 x i256], [8 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   store i256 0, i256* %[[T25]], align 4
//CHECK-NEXT:   br label %unrolled_loop{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %[[T26:[0-9a-zA-Z_\.]+]] = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T27:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_4]]([0 x i256]* %[[T26]], [0 x i256]* %0, i256* %[[T27]])
//CHECK-NEXT:   %[[T28:[0-9a-zA-Z_\.]+]] = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T29:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_4]]([0 x i256]* %[[T28]], [0 x i256]* %0, i256* %[[T29]])
//CHECK-NEXT:   %[[T30:[0-9a-zA-Z_\.]+]] = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T31:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_4]]([0 x i256]* %[[T30]], [0 x i256]* %0, i256* %[[T31]])
//CHECK-NEXT:   %[[T32:[0-9a-zA-Z_\.]+]] = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T33:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_4]]([0 x i256]* %[[T32]], [0 x i256]* %0, i256* %[[T33]])
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %[[T34:[0-9a-zA-Z_\.]+]] = getelementptr [8 x i256], [8 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 4, i256* %[[T34]], align 4
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %[[T35:[0-9a-zA-Z_\.]+]] = getelementptr [8 x i256], [8 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   store i256 0, i256* %[[T35]], align 4
//CHECK-NEXT:   br label %unrolled_loop{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop{{[0-9]+}}:
//CHECK-NEXT:   %[[T36:[0-9a-zA-Z_\.]+]] = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T37:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 4
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_5]]([0 x i256]* %[[T36]], [0 x i256]* %0, i256* %[[T37]])
//CHECK-NEXT:   %[[T38:[0-9a-zA-Z_\.]+]] = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T39:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_5]]([0 x i256]* %[[T38]], [0 x i256]* %0, i256* %[[T39]])
//CHECK-NEXT:   %[[T40:[0-9a-zA-Z_\.]+]] = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T41:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_5]]([0 x i256]* %[[T40]], [0 x i256]* %0, i256* %[[T41]])
//CHECK-NEXT:   %[[T42:[0-9a-zA-Z_\.]+]] = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T43:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_5]]([0 x i256]* %[[T42]], [0 x i256]* %0, i256* %[[T43]])
//CHECK-NEXT:   %[[T44:[0-9a-zA-Z_\.]+]] = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T45:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_5]]([0 x i256]* %[[T44]], [0 x i256]* %0, i256* %[[T45]])
//CHECK-NEXT:   br label %store{{[0-9]+}}
//CHECK-EMPTY: 
//CHECK-NEXT: store{{[0-9]+}}:
//CHECK-NEXT:   %[[T46:[0-9a-zA-Z_\.]+]] = getelementptr [8 x i256], [8 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 5, i256* %[[T46]], align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
