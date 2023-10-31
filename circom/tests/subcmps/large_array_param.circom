pragma circom 2.0.0;

// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function create_large_array(t) {
    if (t == 2) {
        return [
            11,
            22,
            33,
            44
        ];
    } else if (t == 3) {
        return [
            11,
            22,
            33,
            44,
            55,
            66,
            77,
            88,
            99
        ];
    } else {
        assert(0);
        return [0];
    }
}

template Mixer(t, S, r) {
    signal input inp;
    signal output out;

    var lc = 0;
    for (var i = 0; i < t; i++) {
        lc += S[t*r+i] * inp;
    }
    out <== lc;
}

template Main(t) {
    signal input inp;
    signal output out;

    var S[t*t] = create_large_array(t);

    component mix[t];
    var lc = 0;
    for (var r = 0; r < t; r++) {
        mix[r] = Mixer(t, S, r);
        mix[r].inp <-- inp;
        lc += mix[r].out;
    }
    out <-- lc;
}

component main = Main(2);

//CHECK-LABEL: define{{.*}} void @..generated..array.param.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars){{.*}} {
//CHECK-NEXT: ..generated..array.param.[[$F_ID_1]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 11, i256* %0, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %1 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 22, i256* %1, align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 33, i256* %2, align 4
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %3 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 44, i256* %3, align 4
//CHECK-NEXT:   br label %return5
//CHECK-EMPTY: 
//CHECK-NEXT: return5:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//There is only 1 produced, no duplicates
//CHECK-NOT:  define{{.*}} void @..generated..array.param.
//
//CHECK-LABEL: define{{.*}} void @Mixer_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [8 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY: 
//CHECK-NEXT: call1:
//CHECK-NEXT:   %1 = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..array.param.[[$F_ID_1]]([0 x i256]* %1)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %2 = getelementptr [8 x i256], [8 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 0, i256* %2, align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %3 = getelementptr [8 x i256], [8 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 2, i256* %3, align 4
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %4 = getelementptr [8 x i256], [8 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 0, i256* %4, align 4
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %5 = getelementptr [8 x i256], [8 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   store i256 0, i256* %5, align 4
//CHECK-NEXT:   br label %unrolled_loop6
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop6:
//
//CHECK-LABEL: define{{.*}} void @Mixer_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [8 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY: 
//CHECK-NEXT: call1:
//CHECK-NEXT:   %1 = bitcast [8 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   call void @..generated..array.param.[[$F_ID_1]]([0 x i256]* %1)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %2 = getelementptr [8 x i256], [8 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 1, i256* %2, align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %3 = getelementptr [8 x i256], [8 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 2, i256* %3, align 4
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %4 = getelementptr [8 x i256], [8 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 0, i256* %4, align 4
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %5 = getelementptr [8 x i256], [8 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   store i256 0, i256* %5, align 4
//CHECK-NEXT:   br label %unrolled_loop6
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop6:
