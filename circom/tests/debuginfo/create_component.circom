pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck --match-full-lines --enable-var-scope %s

template B(n) {
  signal input in;
}

template A(n) {
  signal input in;
  component x = B(n * n);
  x.in <-- in;
}

component main = A(5);

//Variables are not used for the debug info numbering because a CHECK-LABEL directive
//	cannot contain any variable uses or definitions and the "--match-full-lines" option
//	is used so those lines cannot be split into two directives with a CHECK-SAME to
//	define a variable. The only alternatives are to lose the extra check given by matching
//	full lines or to remove the "--match-full-lines" option and surround each check with
//	{{^}} and {{$}} but it gets messy.

//CHECK-LABEL:    define{{.*}} void @B_0_build({ [0 x i256]*, i32 }* %{{[[:alnum:]_]+}}) !dbg !4 {
//CHECK-NEXT:     [[L1:main]]:
//CHECK-COUNT-06:   {{.*}}, !dbg !7
//CHECK-NEXT:       ret void, !dbg !7
//CHECK-NEXT:     }

//CHECK-LABEL:    define{{.*}} void @B_0_run([0 x i256]* %{{[[:alnum:]_]+}}) !dbg !8 {
//CHECK-NEXT:     [[L1:prelude]]:
//CHECK-COUNT-03:   {{.*}}, !dbg !9
//CHECK-EMPTY:
//CHECK-NEXT:     [[L2:store[0-9]*]]:{{[[:space:]]}}; preds = %[[L1]]
//CHECK-COUNT-03:   {{.*}}, !dbg !9
//CHECK-EMPTY:
//CHECK-NEXT:     [[L3:prologue]]:{{[[:space:]]}}; preds = %[[L2]]
//CHECK-NEXT:       ret void, !dbg !9
//CHECK-NEXT:     }

//CHECK-LABEL:    define{{.*}} void @A_1_build({ [0 x i256]*, i32 }* %{{[[:alnum:]_]+}}) !dbg !10 {
//CHECK-NEXT:     [[L1:main]]:
//CHECK-COUNT-06:   {{.*}}, !dbg !11
//CHECK-NEXT:       ret void, !dbg !11
//CHECK-NEXT:     }

//CHECK-LABEL:    define{{.*}} void @A_1_run([0 x i256]* %{{[[:alnum:]_]+}}) !dbg !12 {
//CHECK-NEXT:     [[L1:prelude]]:
//CHECK-COUNT-03:   {{.*}}, !dbg !13
//CHECK-EMPTY:
//CHECK-NEXT:     [[L2:store[0-9]*]]:{{[[:space:]]}}; preds = %[[L1]]
//CHECK-COUNT-03:   {{.*}}, !dbg !13
//CHECK-EMPTY:
//CHECK-NEXT:     [[L3:create_cmp[0-9]*]]:{{[[:space:]]}}; preds = %[[L2]]
//CHECK-COUNT-03:   {{.*}}, !dbg !13
//CHECK-EMPTY:
//CHECK-NEXT:     [[L4:store[0-9]*]]:{{[[:space:]]}}; preds = %[[L3]]
//CHECK-COUNT-14:   {{.*}}, !dbg !14
//CHECK-EMPTY:
//CHECK-NEXT:     [[L5:prologue]]:{{[[:space:]]}}; preds = %[[L4]]
//CHECK-NEXT:       ret void, !dbg !14
//CHECK-NEXT:     }

//CHECK-LABEL:    !llvm.dbg.cu = !{!1}
//CHECK:          !1 = distinct !DICompileUnit({{.*}}file: !2{{.*}})
//CHECK:          !2 = !DIFile(filename:{{.*}}create_component.circom{{.*}})
//CHECK:          !4 = distinct !DISubprogram(name: "B", linkageName: "B_0_build", scope: null, file: !2, line: 5, {{.*}}unit: !1{{.*}})
//CHECK:          !7 = !DILocation(line: 5, scope: !4)
//CHECK:          !8 = distinct !DISubprogram(name: "B", linkageName: "B_0_run", scope: null, file: !2, line: 5, {{.*}}unit: !1{{.*}})
//CHECK:          !9 = !DILocation(line: 5, scope: !8)
//CHECK:          !10 = distinct !DISubprogram(name: "A", linkageName: "A_1_build", scope: null, file: !2, line: 9, {{.*}}unit: !1{{.*}})
//CHECK:          !11 = !DILocation(line: 9, scope: !10)
//CHECK:          !12 = distinct !DISubprogram(name: "A", linkageName: "A_1_run", scope: null, file: !2, line: 9, {{.*}}unit: !1{{.*}})
//CHECK:          !13 = !DILocation(line: 9, scope: !12)
//CHECK:          !14 = !DILocation(line: 12, scope: !12)
