pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function earlyReturnFn(inp, n, m, k, a) {
    if (n == 0) {
        return inp;
        var dividend[5];
        for (var i = m; i >= 0; i--) {
            if (i == m) {
                dividend[k] = 0;
                for (var j = 0; j < k; j++) {
                    dividend[j] = a[j + m];
                }
            } else {
                for (var j = k; j >= 0; j--) {
                    dividend[j] = a[j + i];
                }
            }
        }
    }
    return 0;
}

template EarlyReturn() {
    signal input inp;
    signal input a[10];
    signal output outp;

    outp <== earlyReturnFn(inp, 0, inp, inp, a);
}

component main = EarlyReturn();

//CHECK-LABEL: define{{.*}} i256 @earlyReturnFn_0(i256* %0){{.*}} {
//CHECK-NEXT: earlyReturnFn_0:
//CHECK-NEXT:   br label %branch1
//CHECK-EMPTY: 
//CHECK-NEXT: branch1:
//CHECK-NEXT:   %1 = getelementptr i256, i256* %0, i32 1
//CHECK-NEXT:   %2 = load i256, i256* %1, align 4
//CHECK-NEXT:   %call.fr_eq = call i1 @fr_eq(i256 %2, i256 0)
//CHECK-NEXT:   br i1 %call.fr_eq, label %if.then, label %if.else
//CHECK-EMPTY: 
//CHECK-NEXT: if.then:
//CHECK-NEXT:   %3 = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %4 = load i256, i256* %3, align 4
//CHECK-NEXT:   ret i256 %4
//CHECK-EMPTY: 
//CHECK-NEXT: if.else:
//CHECK-NEXT:   br label %if.merge
//CHECK-EMPTY: 
//CHECK-NEXT: if.merge:
//CHECK-NEXT:   br label %nop5
//CHECK-EMPTY: 
//CHECK-NEXT: nop5:
//CHECK-NEXT:   unreachable
//CHECK-NEXT: }
