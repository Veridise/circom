pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck --match-full-lines --enable-var-scope %s

template A(n) {
  signal input inp[n];
  signal output out[n];

  for ( var i = 0; i < n; i++ ) {
    out[i] <-- inp[i];
  }
}

component main = A(3);

//Variables are not used for the debug info numbering because a CHECK-LABEL directive
//	cannot contain any variable uses or definitions and the "--match-full-lines" option
//	is used so those lines cannot be split into two directives with a CHECK-SAME to
//	define a variable. The only alternatives are to lose the extra check given by matching
//	full lines or to remove the "--match-full-lines" option and surround each check with
//	{{^}} and {{$}} but it gets messy.

//CHECK-LABEL:    define{{.*}} void @..generated..loop.body.{{[0-9a-zA-Z_\.]+}}([0 x i256]* %lvars, [0 x i256]* %signals, i256* %sig_{{[0-9]+}}, i256* %sig_{{[0-9]+}}){{.*}} !dbg !4 {
//CHECK-NEXT:     [[$F_ID_1:..generated..loop.body.[0-9a-zA-Z_\.]+]]:
//CHECK-COUNT-01:   {{.*}}, !dbg !7
//CHECK-EMPTY:
//CHECK-NEXT:     [[L01:store[0-9]*]]:{{[[:space:]]}}; preds = %[[$F_ID_1]]
//CHECK-COUNT-05:   {{.*}}, !dbg !8
//CHECK-EMPTY:
//CHECK-NEXT:     [[L02:store[0-9]*]]:{{[[:space:]]}}; preds = %[[L01]]
//CHECK-COUNT-06:   {{.*}}, !dbg !7
//CHECK-EMPTY:
//CHECK-NEXT:     return{{[0-9]*}}:{{[[:space:]]}}; preds = %[[L02]]
//CHECK-NEXT:       ret void, !dbg !7
//CHECK-NEXT:     }

//CHECK-LABEL:    define{{.*}} void @A_0_build({ [0 x i256]*, i32 }* %{{[[:alnum:]_]+}}){{.*}} !dbg !9 {
//CHECK-NEXT:     [[L1:main]]:
//CHECK-COUNT-06:   {{.*}}, !dbg !10
//CHECK-NEXT:       ret void, !dbg !10
//CHECK-NEXT:     }

//CHECK-LABEL:    define{{.*}} void @A_0_run([0 x i256]* %{{[[:alnum:]_]+}}){{.*}} !dbg !11 {
//CHECK-NEXT:     [[L01:prelude]]:
//CHECK-COUNT-03:   {{.*}}, !dbg !12
//CHECK-EMPTY:
//CHECK-NEXT:     [[L02:store[0-9]*]]:{{[[:space:]]}}; preds = %[[L01]]
//CHECK-COUNT-03:   {{.*}}, !dbg !12
//CHECK-EMPTY:
//CHECK-NEXT:     [[L03:store[0-9]*]]:{{[[:space:]]}}; preds = %[[L02]]
//CHECK-COUNT-03:   {{.*}}, !dbg !13
//CHECK-EMPTY:
//CHECK-NEXT:     [[L04:unrolled_loop[0-9]*]]:{{[[:space:]]}}; preds = %[[L03]]
//CHECK-COUNT-03:   {{.*}}, !dbg !13
//CHECK-NEXT:       call void @[[$F_ID_1]]([0 x i256]* %{{[[:alnum:]_]+}}, [0 x i256]* %{{[[:alnum:]_]+}}, i256* %{{[[:alnum:]_]+}}, i256* %{{[[:alnum:]_]+}}), !dbg !13
//CHECK-COUNT-03:   {{.*}}, !dbg !13
//CHECK-NEXT:       call void @[[$F_ID_1]]([0 x i256]* %{{[[:alnum:]_]+}}, [0 x i256]* %{{[[:alnum:]_]+}}, i256* %{{[[:alnum:]_]+}}, i256* %{{[[:alnum:]_]+}}), !dbg !13
//CHECK-COUNT-03:   {{.*}}, !dbg !13
//CHECK-NEXT:       call void @[[$F_ID_1]]([0 x i256]* %{{[[:alnum:]_]+}}, [0 x i256]* %{{[[:alnum:]_]+}}, i256* %{{[[:alnum:]_]+}}, i256* %{{[[:alnum:]_]+}}), !dbg !13
//CHECK-NEXT:       br label %prologue, !dbg !13
//CHECK-EMPTY:
//CHECK-NEXT:     [[L05:prologue]]:{{[[:space:]]}}; preds = %[[L04]]
//CHECK-NEXT:       ret void, !dbg !13
//CHECK-NEXT:     }

//CHECK-LABEL:    !llvm.dbg.cu = !{!1}
//CHECK:          !1 = distinct !DICompileUnit({{.*}}file: !2{{.*}})
//CHECK:          !2 = !DIFile(filename:{{.*}}loop_and_block.circom{{.*}})
//CHECK:          !4 = distinct !DISubprogram(name: "A", linkageName: "[[$F_ID_1]]", scope: null, file: !2, line: 9, {{.*}}unit: !1{{.*}})
//CHECK:          !7 = !DILocation(line: 9, scope: !4)
//CHECK:          !8 = !DILocation(line: 10, scope: !4)
//CHECK:          !9 = distinct !DISubprogram(name: "A", linkageName: "A_0_build", scope: null, file: !2, line: 5, {{.*}}unit: !1{{.*}})
//CHECK:          !10 = !DILocation(line: 5, scope: !9)
//CHECK:          !11 = distinct !DISubprogram(name: "A", linkageName: "A_0_run", scope: null, file: !2, line: 5, {{.*}}unit: !1{{.*}})
//CHECK:          !12 = !DILocation(line: 5, scope: !11)
//CHECK:          !13 = !DILocation(line: 9, scope: !11)
