pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck --match-full-lines --enable-var-scope %s

template A(n) {
  signal input in1;
  signal input in2;
  signal input in3[2];
  var outs[10];

  outs[0] = in1 + in2;
  outs[1] = in1 >> in2;
  outs[2] = in1 < in2;
  outs[3] = in1 == in2;
  outs[4] = in1 && in2;
  outs[5] = in1 & in2;
  outs[6] = -in2;
  outs[7] = ~in2;
  outs[8] = !in2;
  outs[9] = in3[n];
}

component main = A(1);

//Variables are not used for the debug info numbering because a CHECK-LABEL directive
//	cannot contain any variable uses or definitions and the "--match-full-lines" option
//	is used so those lines cannot be split into two directives with a CHECK-SAME to
//	define a variable. The only alternatives are to lose the extra check given by matching
//	full lines or to remove the "--match-full-lines" option and surround each check with
//	{{^}} and {{$}} but it gets messy.

//CHECK-LABEL:    define{{.*}} void @A_0_build({ [0 x i256]*, i32 }* %{{[[:alnum:]_]+}}){{.*}} !dbg !4 {
//CHECK-NEXT:     [[L1:main]]:
//CHECK-COUNT-06:   {{.*}}, !dbg !7
//CHECK-NEXT:       ret void, !dbg !7
//CHECK-NEXT:     }

//CHECK-LABEL:    define{{.*}} void @A_0_run([0 x i256]* %{{[[:alnum:]_]+}}){{.*}} !dbg !8 {
//CHECK-NEXT:     [[L01:prelude]]:
//CHECK-COUNT-03:   {{.*}}, !dbg !9
//CHECK-EMPTY:
//CHECK-NEXT:     [[L02:store[0-9]*]]:{{[[:space:]]}}; preds = %[[L01]]
//CHECK-COUNT-03:   {{.*}}, !dbg !9
//CHECK-EMPTY:
//CHECK-NEXT:     [[L03:store[0-9]*]]:{{[[:space:]]}}; preds = %[[L02]]
//CHECK-COUNT-03:   {{.*}}, !dbg !10
//CHECK-EMPTY:
//CHECK-NEXT:     [[L04:store[0-9]*]]:{{[[:space:]]}}; preds = %[[L03]]
//CHECK-COUNT-03:   {{.*}}, !dbg !10
//CHECK-EMPTY:
//CHECK-NEXT:     [[L05:store[0-9]*]]:{{[[:space:]]}}; preds = %[[L04]]
//CHECK-COUNT-03:   {{.*}}, !dbg !10
//CHECK-EMPTY:
//CHECK-NEXT:     [[L06:store[0-9]*]]:{{[[:space:]]}}; preds = %[[L05]]
//CHECK-COUNT-03:   {{.*}}, !dbg !10
//CHECK-EMPTY:
//CHECK-NEXT:     [[L07:store[0-9]*]]:{{[[:space:]]}}; preds = %[[L06]]
//CHECK-COUNT-03:   {{.*}}, !dbg !10
//CHECK-EMPTY:
//CHECK-NEXT:     [[L08:store[0-9]*]]:{{[[:space:]]}}; preds = %[[L07]]
//CHECK-COUNT-03:   {{.*}}, !dbg !10
//CHECK-EMPTY:
//CHECK-NEXT:     [[L09:store[0-9]*]]:{{[[:space:]]}}; preds = %[[L08]]
//CHECK-COUNT-03:   {{.*}}, !dbg !10
//CHECK-EMPTY:
//CHECK-NEXT:     [[L10:store[0-9]*]]:{{[[:space:]]}}; preds = %[[L09]]
//CHECK-COUNT-03:   {{.*}}, !dbg !10
//CHECK-EMPTY:
//CHECK-NEXT:     [[L11:store[0-9]*]]:{{[[:space:]]}}; preds = %[[L10]]
//CHECK-COUNT-03:   {{.*}}, !dbg !10
//CHECK-EMPTY:
//CHECK-NEXT:     [[L12:store[0-9]*]]:{{[[:space:]]}}; preds = %[[L11]]
//CHECK-COUNT-03:   {{.*}}, !dbg !10
//CHECK-EMPTY:
//CHECK-NEXT:     [[L13:store[0-9]*]]:{{[[:space:]]}}; preds = %[[L12]]
//CHECK-COUNT-08:   {{.*}}, !dbg !11
//CHECK-EMPTY:
//CHECK-NEXT:     [[L14:store[0-9]*]]:{{[[:space:]]}}; preds = %[[L13]]
//CHECK-COUNT-08:   {{.*}}, !dbg !12
//CHECK-EMPTY:
//CHECK-NEXT:     [[L15:store[0-9]*]]:{{[[:space:]]}}; preds = %[[L14]]
//CHECK-COUNT-09:   {{.*}}, !dbg !13
//CHECK-EMPTY:
//CHECK-NEXT:     [[L16:store[0-9]*]]:{{[[:space:]]}}; preds = %[[L15]]
//CHECK-COUNT-09:   {{.*}}, !dbg !14
//CHECK-EMPTY:
//CHECK-NEXT:     [[L17:store[0-9]*]]:{{[[:space:]]}}; preds = %[[L16]]
//CHECK-COUNT-11:   {{.*}}, !dbg !15
//CHECK-EMPTY:
//CHECK-NEXT:     [[L18:store[0-9]*]]:{{[[:space:]]}}; preds = %[[L17]]
//CHECK-COUNT-08:   {{.*}}, !dbg !16
//CHECK-EMPTY:
//CHECK-NEXT:     [[L19:store[0-9]*]]:{{[[:space:]]}}; preds = %[[L18]]
//CHECK-COUNT-06:   {{.*}}, !dbg !17
//CHECK-EMPTY:
//CHECK-NEXT:     [[L20:store[0-9]*]]:{{[[:space:]]}}; preds = %[[L19]]
//CHECK-COUNT-06:   {{.*}}, !dbg !18
//CHECK-EMPTY:
//CHECK-NEXT:     [[L21:store[0-9]*]]:{{[[:space:]]}}; preds = %[[L20]]
//CHECK-COUNT-08:   {{.*}}, !dbg !19
//CHECK-EMPTY:
//CHECK-NEXT:     [[L22:store[0-9]*]]:{{[[:space:]]}}; preds = %[[L21]]
//CHECK-COUNT-05:   {{.*}}, !dbg !20
//CHECK-EMPTY:
//CHECK-NEXT:     [[L23:prologue]]:{{[[:space:]]}}; preds = %[[L22]]
//CHECK-NEXT:       ret void, !dbg !20
//CHECK-NEXT:     }

//CHECK-LABEL:    !llvm.dbg.cu = !{!1}
//CHECK:          !1 = distinct !DICompileUnit({{.*}}file: !2{{.*}})
//CHECK:          !2 = !DIFile(filename:{{.*}}compute.circom{{.*}})
//CHECK:          !4 = distinct !DISubprogram(name: "A", linkageName: "A_0_build", scope: null, file: !2, line: 5, {{.*}}unit: !1{{.*}})
//CHECK:          !7 = !DILocation(line: 5, scope: !4)
//CHECK:          !8 = distinct !DISubprogram(name: "A", linkageName: "A_0_run", scope: null, file: !2, line: 5, {{.*}}unit: !1{{.*}})
//CHECK:          !9 = !DILocation(line: 5, scope: !8)
//CHECK:          !10 = !DILocation(line: 9, scope: !8)
//CHECK:          !11 = !DILocation(line: 11, scope: !8)
//CHECK:          !12 = !DILocation(line: 12, scope: !8)
//CHECK:          !13 = !DILocation(line: 13, scope: !8)
//CHECK:          !14 = !DILocation(line: 14, scope: !8)
//CHECK:          !15 = !DILocation(line: 15, scope: !8)
//CHECK:          !16 = !DILocation(line: 16, scope: !8)
//CHECK:          !17 = !DILocation(line: 17, scope: !8)
//CHECK:          !18 = !DILocation(line: 18, scope: !8)
//CHECK:          !19 = !DILocation(line: 19, scope: !8)
//CHECK:          !20 = !DILocation(line: 20, scope: !8)
