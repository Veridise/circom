; ModuleID = 'examples/example1_ll/example1.ll'
source_filename = "examples/example1_ll/example1.ll"

define i256 @fr_add(i256 %0, i256 %1) {
fr_add:
  %2 = add i256 %0, %1
  ret i256 %2
}

define i256 @fr_sub(i256 %0, i256 %1) {
fr_sub:
  %2 = sub i256 %0, %1
  ret i256 %2
}

define i256 @fr_mul(i256 %0, i256 %1) {
fr_mul:
  %2 = mul i256 %0, %1
  ret i256 %2
}

define i256 @fr_div(i256 %0, i256 %1) {
fr_div:
  %2 = sdiv i256 1, %1
  %3 = mul i256 %0, %2
  ret i256 %3
}

define i256 @fr_intdiv(i256 %0, i256 %1) {
fr_intdiv:
  %2 = sdiv i256 %0, %1
  ret i256 %2
}

define i256 @fr_mod(i256 %0, i256 %1) {
fr_mod:
  %2 = srem i256 %0, %1
  ret i256 %2
}

define i1 @fr_eq(i256 %0, i256 %1) {
fr_eq:
  %2 = icmp eq i256 %0, %1
  ret i1 %2
}

define i1 @fr_neq(i256 %0, i256 %1) {
fr_neq:
  %2 = icmp ne i256 %0, %1
  ret i1 %2
}

define i1 @fr_lt(i256 %0, i256 %1) {
fr_lt:
  %2 = icmp slt i256 %0, %1
  ret i1 %2
}

define i1 @fr_gt(i256 %0, i256 %1) {
fr_gt:
  %2 = icmp sgt i256 %0, %1
  ret i1 %2
}

define i1 @fr_le(i256 %0, i256 %1) {
fr_le:
  %2 = icmp sle i256 %0, %1
  ret i1 %2
}

define i1 @fr_ge(i256 %0, i256 %1) {
fr_ge:
  %2 = icmp sge i256 %0, %1
  ret i1 %2
}

define i256 @fr_neg(i256 %0) {
fr_neg:
  %1 = sub i256 0, %0
  ret i256 %1
}

define i256 @fr_shl(i256 %0, i256 %1) {
fr_shl:
  %2 = shl i256 %0, %1
  ret i256 %2
}

define i256 @fr_shr(i256 %0, i256 %1) {
fr_shr:
  %2 = ashr i256 %0, %1
  ret i256 %2
}

define i256 @fr_bit_and(i256 %0, i256 %1) {
fr_bit_and:
  %2 = and i256 %0, %1
  ret i256 %2
}

define i256 @fr_bit_or(i256 %0, i256 %1) {
fr_bit_or:
  %2 = or i256 %0, %1
  ret i256 %2
}

define i256 @fr_bit_xor(i256 %0, i256 %1) {
fr_bit_xor:
  %2 = xor i256 %0, %1
  ret i256 %2
}

define i256 @fr_bit_flip(i256 %0) {
fr_bit_flip:
  %1 = xor i256 %0, -1
  ret i256 %1
}

define i1 @fr_logic_and(i1 %0, i1 %1) {
fr_logic_and:
  %2 = and i1 %0, %1
  ret i1 %2
}

define i1 @fr_logic_or(i1 %0, i1 %1) {
fr_logic_or:
  %2 = or i1 %0, %1
  ret i1 %2
}

define i1 @fr_logic_not(i1 %0) {
fr_logic_not:
  %1 = xor i1 %0, true
  ret i1 %1
}

define i32 @fr_cast_to_addr(i256 %0) {
fr_cast_to_addr:
  %1 = trunc i256 %0 to i32
  ret i32 %1
}

define i256 @fr_pow(i256 %0, i256 %1) {
fr_pow:
  %call.fr_lt = call i1 @fr_lt(i256 %1, i256 0)
  %abv = alloca i256, align 8
  br i1 %call.fr_lt, label %if.then.pow.abs, label %if.else.pow.abs

if.then.pow.abs:                                  ; preds = %fr_pow
  %2 = sub i256 0, %1
  store i256 %2, i256* %abv, align 4
  br label %if.merge.pow.abs

if.else.pow.abs:                                  ; preds = %fr_pow
  store i256 %1, i256* %abv, align 4
  br label %if.merge.pow.abs

if.merge.pow.abs:                                 ; preds = %if.else.pow.abs, %if.then.pow.abs
  %res = alloca i256, align 8
  store i256 1, i256* %res, align 4
  %i = alloca i256, align 8
  store i256 0, i256* %i, align 4
  br label %loop.cond.pow

loop.cond.pow:                                    ; preds = %loop.body.pow, %if.merge.pow.abs
  %3 = load i256, i256* %i, align 4
  %4 = load i256, i256* %abv, align 4
  %5 = icmp slt i256 %3, %4
  br i1 %5, label %loop.body.pow, label %loop.end.pow

loop.body.pow:                                    ; preds = %loop.cond.pow
  %6 = load i256, i256* %res, align 4
  %call.fr_mul = call i256 @fr_mul(i256 %6, i256 %0)
  store i256 %call.fr_mul, i256* %res, align 4
  %7 = load i256, i256* %i, align 4
  %8 = add i256 %7, 1
  store i256 %8, i256* %i, align 4
  br label %loop.cond.pow

loop.end.pow:                                     ; preds = %loop.cond.pow
  br i1 %call.fr_lt, label %if.then.pow.inv, label %if.merge.pow.inv

if.then.pow.inv:                                  ; preds = %loop.end.pow
  %9 = load i256, i256* %res, align 4
  %10 = sdiv i256 1, %9
  store i256 %10, i256* %res, align 4
  br label %if.merge.pow.inv

if.merge.pow.inv:                                 ; preds = %if.then.pow.inv, %loop.end.pow
  %11 = load i256, i256* %res, align 4
  ret i256 %11
}

define void @__constraint_values(i256 %0, i256 %1, i1* %2) {
main:
  %3 = icmp eq i256 %0, %1
  store i1 %3, i1* %2, align 1
  ret void
}

define void @__constraint_value(i1 %0, i1* %1) {
main:
  store i1 %0, i1* %1, align 1
  ret void
}

declare void @__abort()

define void @__assert(i1 %0) {
main:
  br i1 %0, label %end, label %if.assert.fails

if.assert.fails:                                  ; preds = %main
  call void @__abort()
  br label %end

end:                                              ; preds = %if.assert.fails, %main
  ret void
}

define void @Multiplier2_0_build({ [0 x i256]*, i32 }* %0) {
main:
  %1 = alloca [3 x i256], align 8
  %2 = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 1
  store i32 2, i32* %2, align 4
  %3 = getelementptr { [0 x i256]*, i32 }, { [0 x i256]*, i32 }* %0, i32 0, i32 0
  %4 = bitcast [3 x i256]* %1 to [0 x i256]*
  store [0 x i256]* %4, [0 x i256]** %3, align 8
  ret void
}

define void @Multiplier2_0_run([0 x i256]* %0) {
prelude:
  %lvars = alloca [0 x i256], align 8
  %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
  br label %store1

store1:                                           ; preds = %prelude
  %1 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
  %2 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
  %3 = load i256, i256* %2, align 4
  %4 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 2
  %5 = load i256, i256* %4, align 4
  %call.fr_mul = call i256 @fr_mul(i256 %3, i256 %5)
  store i256 %call.fr_mul, i256* %1, align 4
  %6 = load i256, i256* %1, align 4
  %constraint = alloca i1, align 1, !constraint !0
  call void @__constraint_values(i256 %call.fr_mul, i256 %6, i1* %constraint)
  br label %prologue

prologue:                                         ; preds = %store1
  ret void
}

!0 = !{!"constraint"}
