pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck --match-full-lines --enable-var-scope %s

template B() {
  signal input in1;
  signal input in2;
  signal output out;

  var x;
  if (in1 > 0) {
    x = in1;
  } else {
    x = in2;
  }
  out <-- x;
}

component main = B();

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
//CHECK-COUNT-03:   {{.*}}, !dbg !10
//CHECK-EMPTY:
//CHECK-NEXT:     [[L3:branch[0-9]*]]:{{[[:space:]]}}; preds = %[[L2]]
//CHECK-COUNT-04:   {{.*}}, !dbg !11
//CHECK-EMPTY:
//CHECK-NEXT:     [[L4:if.then[0-9]*]]:{{[[:space:]]}}; preds = %[[L3]]
//CHECK-COUNT-05:   {{.*}}, !dbg !12
//CHECK-EMPTY:
//CHECK-NEXT:     [[L5:if.else[0-9]*]]:{{[[:space:]]}}; preds = %[[L3]]
//CHECK-COUNT-05:   {{.*}}, !dbg !13
//CHECK-EMPTY:
//CHECK-NEXT:     [[L6:if.merge[0-9]*]]:{{[[:space:]]}}; preds = %[[L5]], %[[L4]]
//CHECK-COUNT-01:   {{.*}}, !dbg !13
//CHECK-EMPTY:
//CHECK-NEXT:     [[L7:store[0-9]*]]:{{[[:space:]]}}; preds = %[[L6]]
//CHECK-COUNT-05:   {{.*}}, !dbg !14
//CHECK-EMPTY:
//CHECK-NEXT:     [[L8:prologue]]:{{[[:space:]]}}; preds = %[[L7]]
//CHECK-NEXT:       ret void, !dbg !14
//CHECK-NEXT:     }

//CHECK-LABEL:    !llvm.dbg.cu = !{!1}
//CHECK:          !1 = distinct !DICompileUnit({{.*}}file: !2{{.*}})
//CHECK:          !2 = !DIFile(filename:{{.*}}branch.circom{{.*}})
//CHECK:          !4 = distinct !DISubprogram(name: "B", linkageName: "B_0_build", scope: null, file: !2, line: 5, {{.*}}unit: !1{{.*}})
//CHECK:          !7 = !DILocation(line: 5, scope: !4)
//CHECK:          !8 = distinct !DISubprogram(name: "B", linkageName: "B_0_run", scope: null, file: !2, line: 5, {{.*}}unit: !1{{.*}})
//CHECK:          !9 = !DILocation(line: 5, scope: !8)
//CHECK:          !10 = !DILocation(line: 10, scope: !8)
//CHECK:          !11 = !DILocation(line: 11, scope: !8)
//CHECK:          !12 = !DILocation(line: 12, scope: !8)
//CHECK:          !13 = !DILocation(line: 14, scope: !8)
//CHECK:          !14 = !DILocation(line: 16, scope: !8)
