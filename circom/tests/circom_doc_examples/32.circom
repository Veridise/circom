// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llzk -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*

pragma circom 2.2.0;

bus Point(){
    signal x;
    signal y;
}

template Edwards2Montgomery() {
    input Point() { edwards_point } in ;
    output Point() { montgomery_point } out ;

    out.x <-- (1 + in.y ) / (1 - in.y ) ;
    out.y <-- out.x / in.x ;

    out.x * (1 - in.y ) === (1 + in.y ) ;
    out.y * in.x === out.x ;
}

template Caller() {
    input signal a, b;
    output Point() conv;

    Point() p;
    p.x <== a;
    p.y <== b;

    conv <== Edwards2Montgomery()(p);
}

component main = Caller();
// CHECK: TODO
