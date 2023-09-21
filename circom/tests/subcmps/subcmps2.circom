pragma circom 2.0.6;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*

template Sum(n) {
    signal input inp[n];
    signal output outp;

    var s = 0;

    for (var i = 0; i < n; i++) {
        s += inp[i];
    }

    outp <== s;
}

function nop(i) {
    return i;
}

template Caller() {
    signal input inp[4];
    signal output outp;

    component s = Sum(4);

    for (var i = 0; i < 4; i++) {
        s.inp[i] <== nop(inp[i]);
    }

    outp <== s.outp;
}

component main = Caller();

//CHECK-LABEL: define void @Caller_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %0)
//CHECK: %[[CALL_VAL:call\.nop_[0-3]]] = call i256 @nop_{{[0-3]}}(i256* %6)
//CHECK: %[[SUBCMP_PTR:.*]] = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 {{[0-3]}}
//CHECK: %[[SUBCMP:.*]] = load [0 x i256]*, [0 x i256]** %[[SUBCMP_PTR]]
//CHECK: %[[SUBCMP_INP:.*]] = getelementptr [0 x i256], [0 x i256]* %[[SUBCMP]], i32 0, i32 {{[1-4]}}
//CHECK: store i256 %[[CALL_VAL]], i256* %[[SUBCMP_INP]]

/*
define void @Sum_0_build({ [0 x i256]*, i32 }* %0) !dbg !9 {
main:
  %1 = alloca [5 x i256], align 8
  %2 = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 1
  store i32 4, i32* %2, align 4
  %3 = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 0
  %4 = bitcast [5 x i256]* %1 to [0 x i256]*
  store [0 x i256]* %4, [0 x i256]** %3, align 8
  ret void
}

define void @Sum_0_run([0 x i256]* %0) !dbg !11 {
prelude:
  %lvars = alloca [3 x i256], align 8
  %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
  br label %store1

store1:
  %1 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 0
  store i256 4, i256* %1, align 4
  br label %store2

store2:
  %2 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
  store i256 0, i256* %2, align 4
  br label %store3

store3:
  %3 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 2
  store i256 0, i256* %3, align 4
  br label %unrolled_loop4

unrolled_loop4:
  %4 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
  %5 = load i256, i256* %4, align 4
  %6 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
  %7 = load i256, i256* %6, align 4
  %call.fr_add = call i256 @fr_add(i256 %5, i256 %7)
  %8 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
  store i256 %call.fr_add, i256* %8, align 4
  %9 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 2
  store i256 1, i256* %9, align 4
  %10 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
  %11 = load i256, i256* %10, align 4
  %12 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 2
  %13 = load i256, i256* %12, align 4
  %call.fr_add1 = call i256 @fr_add(i256 %11, i256 %13)
  %14 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
  store i256 %call.fr_add1, i256* %14, align 4
  %15 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 2
  store i256 2, i256* %15, align 4
  %16 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
  %17 = load i256, i256* %16, align 4
  %18 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 3
  %19 = load i256, i256* %18, align 4
  %call.fr_add2 = call i256 @fr_add(i256 %17, i256 %19)
  %20 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
  store i256 %call.fr_add2, i256* %20, align 4
  %21 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 2
  store i256 3, i256* %21, align 4
  %22 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
  %23 = load i256, i256* %22, align 4
  %24 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 4
  %25 = load i256, i256* %24, align 4
  %call.fr_add3 = call i256 @fr_add(i256 %23, i256 %25)
  %26 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
  store i256 %call.fr_add3, i256* %26, align 4
  %27 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 2
  store i256 4, i256* %27, align 4
  br label %store5

store5:
  %28 = getelementptr [3 x i256], [3 x i256]* %lvars, i32 0, i32 1
  %29 = load i256, i256* %28, align 4
  %30 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
  store i256 %29, i256* %30, align 4
  %31 = load i256, i256* %30, align 4
  %constraint = alloca i1, align 1
  call void @__constraint_values(i256 %29, i256 %31, i1* %constraint)
  br label %prologue

prologue:
  ret void
}

define void @Caller_1_build({ [0 x i256]*, i32 }* %0) !dbg !18 {
main:
  %1 = alloca [5 x i256], align 8
  %2 = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 1
  store i32 4, i32* %2, align 4
  %3 = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 0
  %4 = bitcast [5 x i256]* %1 to [0 x i256]*
  store [0 x i256]* %4, [0 x i256]** %3, align 8
  ret void
}

define void @Caller_1_run([0 x i256]* %0) !dbg !20 {
prelude:
  %lvars = alloca [1 x i256], align 8
  %subcmps = alloca [1 x { [0 x i256]*, i32 }], align 8
  br label %create_cmp1

create_cmp1:
  %1 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0
  call void @Sum_0_build({ [0 x i256]*, i32 }* %1)
  br label %store2

store2:
  %2 = getelementptr [1 x i256], [1 x i256]* %lvars, i32 0, i32 0
  store i256 0, i256* %2, align 4
  br label %unrolled_loop3

unrolled_loop3:
  %nop_0_arena = alloca [1 x i256], align 8
  %3 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
  %4 = load i256, i256* %3, align 4
  %5 = getelementptr [1 x i256], [1 x i256]* %nop_0_arena, i32 0, i32 0
  store i256 %4, i256* %5, align 4
  %6 = bitcast [1 x i256]* %nop_0_arena to i256*
  %call.nop_0 = call i256 @nop_0(i256* %6)
  %7 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
  %8 = load [0 x i256]*, [0 x i256]** %7, align 8
  %9 = getelementptr [0 x i256], [0 x i256]* %8, i32 0, i32 1
  store i256 %call.nop_0, i256* %9, align 4
  %10 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
  %load.subcmp.counter = load i32, i32* %10, align 4
  %decrement.counter = sub i32 %load.subcmp.counter, 1
  store i32 %decrement.counter, i32* %10, align 4
  %11 = load i256, i256* %9, align 4
  %constraint = alloca i1, align 1
  call void @__constraint_values(i256 %call.nop_0, i256 %11, i1* %constraint)
  %12 = getelementptr [1 x i256], [1 x i256]* %lvars, i32 0, i32 0
  store i256 1, i256* %12, align 4
  %nop_0_arena1 = alloca [1 x i256], align 8
  %13 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 2
  %14 = load i256, i256* %13, align 4
  %15 = getelementptr [1 x i256], [1 x i256]* %nop_0_arena1, i32 0, i32 0
  store i256 %14, i256* %15, align 4
  %16 = bitcast [1 x i256]* %nop_0_arena1 to i256*
  %call.nop_02 = call i256 @nop_0(i256* %16)
  %17 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
  %18 = load [0 x i256]*, [0 x i256]** %17, align 8
  %19 = getelementptr [0 x i256], [0 x i256]* %18, i32 0, i32 2
  store i256 %call.nop_02, i256* %19, align 4
  %20 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
  %load.subcmp.counter3 = load i32, i32* %20, align 4
  %decrement.counter4 = sub i32 %load.subcmp.counter3, 1
  store i32 %decrement.counter4, i32* %20, align 4
  %21 = load i256, i256* %19, align 4
  %constraint5 = alloca i1, align 1
  call void @__constraint_values(i256 %call.nop_02, i256 %21, i1* %constraint5)
  %22 = getelementptr [1 x i256], [1 x i256]* %lvars, i32 0, i32 0
  store i256 2, i256* %22, align 4
  %nop_0_arena6 = alloca [1 x i256], align 8
  %23 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 3
  %24 = load i256, i256* %23, align 4
  %25 = getelementptr [1 x i256], [1 x i256]* %nop_0_arena6, i32 0, i32 0
  store i256 %24, i256* %25, align 4
  %26 = bitcast [1 x i256]* %nop_0_arena6 to i256*
  %call.nop_07 = call i256 @nop_0(i256* %26)
  %27 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
  %28 = load [0 x i256]*, [0 x i256]** %27, align 8
  %29 = getelementptr [0 x i256], [0 x i256]* %28, i32 0, i32 3
  store i256 %call.nop_07, i256* %29, align 4
  %30 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
  %load.subcmp.counter8 = load i32, i32* %30, align 4
  %decrement.counter9 = sub i32 %load.subcmp.counter8, 1
  store i32 %decrement.counter9, i32* %30, align 4
  %31 = load i256, i256* %29, align 4
  %constraint10 = alloca i1, align 1
  call void @__constraint_values(i256 %call.nop_07, i256 %31, i1* %constraint10)
  %32 = getelementptr [1 x i256], [1 x i256]* %lvars, i32 0, i32 0
  store i256 3, i256* %32, align 4
  %nop_0_arena11 = alloca [1 x i256], align 8
  %33 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 4
  %34 = load i256, i256* %33, align 4
  %35 = getelementptr [1 x i256], [1 x i256]* %nop_0_arena11, i32 0, i32 0
  store i256 %34, i256* %35, align 4
  %36 = bitcast [1 x i256]* %nop_0_arena11 to i256*
  %call.nop_012 = call i256 @nop_0(i256* %36)
  %37 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
  %38 = load [0 x i256]*, [0 x i256]** %37, align 8
  %39 = getelementptr [0 x i256], [0 x i256]* %38, i32 0, i32 4
  store i256 %call.nop_012, i256* %39, align 4
  %40 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 1
  %load.subcmp.counter13 = load i32, i32* %40, align 4
  %decrement.counter14 = sub i32 %load.subcmp.counter13, 1
  store i32 %decrement.counter14, i32* %40, align 4
  %41 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
  %42 = load [0 x i256]*, [0 x i256]** %41, align 8
  call void @Sum_0_run([0 x i256]* %42)
  %43 = load i256, i256* %39, align 4
  %constraint15 = alloca i1, align 1
  call void @__constraint_values(i256 %call.nop_012, i256 %43, i1* %constraint15)
  %44 = getelementptr [1 x i256], [1 x i256]* %lvars, i32 0, i32 0
  store i256 4, i256* %44, align 4
  br label %store4

store4:
  %45 = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
  %46 = load [0 x i256]*, [0 x i256]** %45, align 8
  %47 = getelementptr [0 x i256], [0 x i256]* %46, i32 0, i32 0
  %48 = load i256, i256* %47, align 4
  %49 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
  store i256 %48, i256* %49, align 4
  %50 = load i256, i256* %49, align 4
  %constraint16 = alloca i1, align 1
  call void @__constraint_values(i256 %48, i256 %50, i1* %constraint16)
  br label %prologue

prologue:
  ret void
}
*/
