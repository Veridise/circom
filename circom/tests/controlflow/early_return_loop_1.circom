pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function earlyReturnFn(in) {
    for (var i = 0; i < 6; i++) {
        if (i == 0) {
            return in;
        }
        assert(0 == 1); // This should be removed because of the early return above
    }
    return -1;
}

function noEarlyReturnFn(in) {
    for (var i = 0; i < 6; i++) {
        if (i == 99) {
            return in;
        }
        assert(in == 0);
    }
    return -1;
}


template EarlyReturn() {
    signal input inp;
    signal output outp[2];

    outp[0] <== noEarlyReturnFn(inp);
    outp[1] <== earlyReturnFn(inp);
}

component main = EarlyReturn();

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9]+]]:
//CHECK-NEXT:   br label %branch1
//CHECK-EMPTY: 
//CHECK-NEXT: branch1:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %1 = load i256, i256* %0, align 4
//CHECK-NEXT:   %call.fr_eq = call i1 @fr_eq(i256 %1, i256 99)
//CHECK-NEXT:   br i1 %call.fr_eq, label %if.then, label %if.else
//CHECK-EMPTY: 
//CHECK-NEXT: if.then:
//CHECK-NEXT:   br label %if.merge
//CHECK-EMPTY: 
//CHECK-NEXT: if.else:
//CHECK-NEXT:   br label %if.merge
//CHECK-EMPTY: 
//CHECK-NEXT: if.merge:
//CHECK-NEXT:   br label %assert5
//CHECK-EMPTY: 
//CHECK-NEXT: assert5:
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %call.fr_eq1 = call i1 @fr_eq(i256 %3, i256 0)
//CHECK-NEXT:   call void @__assert(i1 %call.fr_eq1)
//CHECK-NEXT:   br label %store6
//CHECK-EMPTY: 
//CHECK-NEXT: store6:
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   %6 = load i256, i256* %5, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %6, i256 1)
//CHECK-NEXT:   store i256 %call.fr_add, i256* %4, align 4
//CHECK-NEXT:   br label %return7
//CHECK-EMPTY: 
//CHECK-NEXT: return7:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }

//CHECK-LABEL: define{{.*}} i256 @noEarlyReturnFn_{{[0-9]+}}(i256* %0){{.*}} {
//CHECK-NEXT: noEarlyReturnFn_[[$F_ID_2:[0-9]+]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr i256, i256* %0, i32 1
//CHECK-NEXT:   store i256 0, i256* %1, align 4
//CHECK-NEXT:   br label %unrolled_loop2
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop2:
//CHECK-NEXT:   %2 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %2, [0 x i256]* null)
//CHECK-NEXT:   %3 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %3, [0 x i256]* null)
//CHECK-NEXT:   %4 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %4, [0 x i256]* null)
//CHECK-NEXT:   %5 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %5, [0 x i256]* null)
//CHECK-NEXT:   %6 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %6, [0 x i256]* null)
//CHECK-NEXT:   %7 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %7, [0 x i256]* null)
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   %call.fr_neg = call i256 @fr_neg(i256 1)
//CHECK-NEXT:   ret i256 %call.fr_neg
//CHECK-NEXT: }

//CHECK-LABEL: define{{.*}} i256 @earlyReturnFn_{{[0-9]+}}(i256* %0){{.*}} {
//CHECK-NEXT: earlyReturnFn_[[$F_ID_3:[0-9]+]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr i256, i256* %0, i32 1
//CHECK-NEXT:   store i256 0, i256* %1, align 4
//CHECK-NEXT:   br label %loop2
//CHECK-EMPTY: 
//CHECK-NEXT: loop2:
//CHECK-NEXT:   br label %loop.cond
//CHECK-EMPTY: 
//CHECK-NEXT: loop.cond:
//CHECK-NEXT:   %2 = getelementptr i256, i256* %0, i32 1
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %call.fr_lt = call i1 @fr_lt(i256 %3, i256 6)
//CHECK-NEXT:   br i1 %call.fr_lt, label %loop.body, label %loop.end
//CHECK-EMPTY: 
//CHECK-NEXT: loop.body:
//CHECK-NEXT:   %4 = getelementptr i256, i256* %0, i32 1
//CHECK-NEXT:   %5 = load i256, i256* %4, align 4
//CHECK-NEXT:   %call.fr_eq = call i1 @fr_eq(i256 %5, i256 0)
//CHECK-NEXT:   br i1 %call.fr_eq, label %if.then, label %if.else
//CHECK-EMPTY: 
//CHECK-NEXT: loop.end:
//CHECK-NEXT:   br label %nop9
//CHECK-EMPTY: 
//CHECK-NEXT: if.then:
//CHECK-NEXT:   %6 = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %7 = load i256, i256* %6, align 4
//CHECK-NEXT:   ret i256 %7
//CHECK-EMPTY: 
//CHECK-NEXT: if.else:
//CHECK-NEXT:   br label %if.merge
//CHECK-EMPTY: 
//CHECK-NEXT: if.merge:
//CHECK-NEXT:   br label %loop.cond
//CHECK-EMPTY: 
//CHECK-NEXT: nop9:
//CHECK-NEXT:   unreachable
//CHECK-NEXT: }

//CHECK-LABEL: define{{.*}} void @EarlyReturn_0_run([0 x i256]* %0){{.*}} {
//CHECK: %[[CV_1:[0-9a-zA-Z_.]+]] = call i256 @noEarlyReturnFn_[[$F_ID_2]](i256* %{{[0-9]+}})
//CHECK: %[[CV_2:[0-9a-zA-Z_.]+]] = call i256 @earlyReturnFn_[[$F_ID_3]](i256* %{{[0-9]+}})
