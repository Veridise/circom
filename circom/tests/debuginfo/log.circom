pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck --match-full-lines --enable-var-scope %s

template A() {
  log(1658);
}

component main = A();

//Variables are not used for the debug info numbering because a CHECK-LABEL directive
//	cannot contain any variable uses or definitions and the "--match-full-lines" option
//	is used so those lines cannot be split into two directives with a CHECK-SAME to
//	define a variable. The only alternatives are to lose the extra check given by matching
//	full lines or to remove the "--match-full-lines" option and surround each check with
//	{{^}} and {{$}} but it gets messy.

//CHECK-LABEL:    define{{.*}} void @A_0_build({ [0 x i256]*, i32 }* %{{[[:alnum:]_]+}}) !dbg !4 {
//CHECK-NEXT:     [[L1:main]]:
//CHECK-COUNT-05:   {{.*}}, !dbg !7
//CHECK-NEXT:       ret void, !dbg !7
//CHECK-NEXT:     }

//CHECK-LABEL:    define{{.*}} void @A_0_run([0 x i256]* %{{[[:alnum:]_]+}}) !dbg !8 {
//CHECK-NEXT:     [[L1:prelude]]:
//CHECK-COUNT-03:   {{.*}}, !dbg !9
//CHECK-EMPTY:
//CHECK-NEXT:     [[L2:log[0-9]*]]:{{[[:space:]]}}; preds = %{{.*}}[[L1]]
//CHECK-COUNT-01:   {{.*}}, !dbg !10
//CHECK-EMPTY:
//CHECK-NEXT:     [[L3:prologue]]:{{[[:space:]]}}; preds = %{{.*}}[[L2]]
//CHECK-NEXT:       ret void, !dbg !10
//CHECK-NEXT:     }

//CHECK-LABEL:    !llvm.dbg.cu = !{!1}
//CHECK:          !1 = distinct !DICompileUnit({{.*}}file: !2{{.*}})
//CHECK:          !2 = !DIFile(filename:{{.*}}log.circom{{.*}})
//CHECK:          !4 = distinct !DISubprogram(name: "A", linkageName: "A_0_build", scope: null, file: !2, line: 5, {{.*}}unit: !1{{.*}})
//CHECK:          !7 = !DILocation(line: 5, scope: !4)
//CHECK:          !8 = distinct !DISubprogram(name: "A", linkageName: "A_0_run", scope: null, file: !2, line: 5, {{.*}}unit: !1{{.*}})
//CHECK:          !9 = !DILocation(line: 5, scope: !8)
//CHECK:          !10 = !DILocation(line: 6, scope: !8)
