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

//CHECK-LABEL: define{{.*}} i256 @noEarlyReturnFn_0(i256* %0){{.*}} {
//CHECK-NEXT: noEarlyReturnFn_0:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1
//CHECK-NEXT:   %1 = getelementptr i256, i256* %0, i32 1
//CHECK-NEXT:   store i256 0, i256* %1, align 4
//CHECK-NEXT:   br label %loop2
//CHECK-EMPTY: 
//CHECK-NEXT: loop2
//CHECK-NEXT:   br label %loop.cond
//CHECK-EMPTY: 
//CHECK-NEXT: loop.cond
//CHECK-NEXT:   %2 = getelementptr i256, i256* %0, i32 1
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   %call.fr_lt = call i1 @fr_lt(i256 %3, i256 6)
//CHECK-NEXT:   br i1 %call.fr_lt, label %loop.body, label %loop.end
//CHECK-EMPTY: 
//CHECK-NEXT: loop.body
//CHECK-NEXT:   %4 = getelementptr i256, i256* %0, i32 1
//CHECK-NEXT:   %5 = load i256, i256* %4, align 4
//CHECK-NEXT:   %call.fr_eq = call i1 @fr_eq(i256 %5, i256 99)
//CHECK-NEXT:   br i1 %call.fr_eq, label %if.then, label %if.else
//CHECK-EMPTY: 
//CHECK-NEXT: loop.end
//CHECK-NEXT:   br label %return9
//CHECK-EMPTY: 
//CHECK-NEXT: if.then
//CHECK-NEXT:   br label %if.merge
//CHECK-EMPTY: 
//CHECK-NEXT: if.else
//CHECK-NEXT:   br label %if.merge
//CHECK-EMPTY: 
//CHECK-NEXT: if.merge
//CHECK-NEXT:   %6 = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %7 = load i256, i256* %6, align 4
//CHECK-NEXT:   %call.fr_eq1 = call i1 @fr_eq(i256 %7, i256 0)
//CHECK-NEXT:   call void @__assert(i1 %call.fr_eq1)
//CHECK-NEXT:   %8 = getelementptr i256, i256* %0, i32 1
//CHECK-NEXT:   %9 = getelementptr i256, i256* %0, i32 1
//CHECK-NEXT:   %10 = load i256, i256* %9, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %10, i256 1)
//CHECK-NEXT:   store i256 %call.fr_add, i256* %8, align 4
//CHECK-NEXT:   br label %loop.cond
//CHECK-EMPTY: 
//CHECK-NEXT: return9
//CHECK-NEXT:   %call.fr_neg = call i256 @fr_neg(i256 1)
//CHECK-NEXT:   ret i256 %call.fr_neg
//CHECK-NEXT: }

//CHECK-LABEL: define{{.*}} i256 @earlyReturnFn_1(i256* %0){{.*}} {
//CHECK-NEXT: earlyReturnFn_1:
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
