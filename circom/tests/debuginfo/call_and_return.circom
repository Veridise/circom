pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck --match-full-lines --enable-var-scope %s

template C() {
  signal input in;
  signal output out;
  out <-- negative(in);
}

function negative(n){
  if (n < 0) {
    return 1;
  } else {
    return 0;
  }
}

component main = C();

//Variables are not used for the debug info numbering because a CHECK-LABEL directive
//	cannot contain any variable uses or definitions and the "--match-full-lines" option
//	is used so those lines cannot be split into two directives with a CHECK-SAME to
//	define a variable. The only alternatives are to lose the extra check given by matching
//	full lines or to remove the "--match-full-lines" option and surround each check with
//	{{^}} and {{$}} but it gets messy.

//CHECK-LABEL:    define{{.*}} i256 @negative_0(i256* %{{[[:alnum:]_]+}}) !dbg !4 {
//CHECK-NEXT:     [[L1:[[:alnum:]_]+]]:
//CHECK-COUNT-01:   {{.*}}, !dbg !7
//CHECK-EMPTY:
//CHECK-NEXT:     [[L2:branch[0-9]*]]:{{[[:space:]]}}; preds = %{{.*}}[[L1]]
//CHECK-COUNT-04:   {{.*}}, !dbg !8
//CHECK-EMPTY:
//CHECK-NEXT:     [[L3:if.then[0-9]*]]:{{[[:space:]]}}; preds = %{{.*}}[[L2]]
//CHECK-NEXT:       ret i256 1, !dbg !9
//CHECK-EMPTY:
//CHECK-NEXT:     [[L4:if.else[0-9]*]]:{{[[:space:]]}}; preds = %{{.*}}[[L2]]
//CHECK-NEXT:       ret i256 0, !dbg !10
//CHECK-EMPTY:
//CHECK-NEXT:     [[L5:if.merge[0-9]*]]:{{[[:space:]]}}; No predecessors!
//CHECK-NEXT:       unreachable, !dbg !10
//CHECK-NEXT:     }

//CHECK-LABEL:    define{{.*}} void @C_0_build({ [0 x i256]*, i32 }* %{{[[:alnum:]_]+}}) !dbg !11 {
//CHECK-NEXT:     [[L1:main]]:
//CHECK-COUNT-06:   {{.*}}, !dbg !12
//CHECK-NEXT:       ret void, !dbg !12
//CHECK-NEXT:     }

//CHECK-LABEL:    define{{.*}} void @C_0_run([0 x i256]* %{{[[:alnum:]_]+}}) !dbg !13 {
//CHECK-NEXT:     [[L1:prelude]]:
//CHECK-COUNT-03:   {{.*}}, !dbg !14
//CHECK-EMPTY:
//CHECK-NEXT:     [[L2:call[0-9]*]]:{{[[:space:]]}}; preds = %{{.*}}[[L1]]
//CHECK-COUNT-10:   {{.*}}, !dbg !15
//CHECK-EMPTY:
//CHECK-NEXT:     [[L3:prologue]]:{{[[:space:]]}}; preds = %{{.*}}[[L2]]
//CHECK-NEXT:       ret void, !dbg !15
//CHECK-NEXT:     }

//CHECK-LABEL:    !llvm.dbg.cu = !{!1}
//CHECK:          !1 = distinct !DICompileUnit({{.*}}file: !2{{.*}})
//CHECK:          !2 = !DIFile(filename:{{.*}}call_and_return.circom{{.*}})
//CHECK:          !4 = distinct !DISubprogram(name: "negative", linkageName: "negative_0", scope: null, file: !2, line: 11, {{.*}}unit: !1{{.*}})
//CHECK:          !7 = !DILocation(line: 11, scope: !4)
//CHECK:          !8 = !DILocation(line: 12, scope: !4)
//CHECK:          !9 = !DILocation(line: 13, scope: !4)
//CHECK:          !10 = !DILocation(line: 15, scope: !4)
//CHECK:          !11 = distinct !DISubprogram(name: "C", linkageName: "C_0_build", scope: null, file: !2, line: 5, {{.*}}unit: !1{{.*}})
//CHECK:          !12 = !DILocation(line: 5, scope: !11)
//CHECK:          !13 = distinct !DISubprogram(name: "C", linkageName: "C_0_run", scope: null, file: !2, line: 5, {{.*}}unit: !1{{.*}})
//CHECK:          !14 = !DILocation(line: 5, scope: !13)
//CHECK:          !15 = !DILocation(line: 8, scope: !13)
