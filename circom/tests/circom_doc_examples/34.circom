// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llzk -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*

pragma circom 2.2.0;

template IsZero() {
    signal input in;
    signal output out;

    signal inv;

    inv <-- in!=0 ? 1/in : 0;

    out <== -in*inv +1;
    in*out === 0;
}

template IsEqual() {
    signal input in[2];
    signal output out;

    component isz = IsZero();

    in[1] - in[0] ==> isz.in;

    isz.out ==> out;
}

bus PointN(dim){
    signal x[dim];
}

bus Line(dim){
    PointN(dim) start;
    PointN(dim) end;
}

bus Figure(num_sides, dim){
    Line(dim) side[num_sides];
}

bus Triangle2D(){
    Figure(3,2) {well_defined} triangle;
}

bus Square3D(){
    Figure(4,3) {well_defined} square;
}

template well_defined_figure(num_sides, dimension){
    input Figure(num_sides,dimension) t;
    output Figure(num_sides,dimension) {well_defined} correct_t;
    var all_equals = 0;
    var isequal = 0;
    for(var i = 0; i < num_sides; i=i+1){
        for(var j = 0; j < dimension; j=j+1){
            isequal = IsEqual()([t.side[i].end.x[j],t.side[(i+1)%num_sides].start.x[j]]);
            all_equals += isequal;
        }
    }
    all_equals === num_sides;
    correct_t <== t;
}

component main = well_defined_figure(3,2);
//CHECK-LABEL:  module attributes {veridise.lang = "llzk"} {
