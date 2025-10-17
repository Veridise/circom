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

template Num2Bits(n) {
    signal input in;
    signal output out[n];
    var lc1=0;

    var e2=1;
    for (var i = 0; i<n; i++) {
        out[i] <-- (in >> i) & 1;
        out[i] * (out[i] -1 ) === 0;
        lc1 += out[i] * e2;
        e2 = e2+e2;
    }

    lc1 === in;
}

template LessThan(n) {
    assert(n <= 252);
    signal input in[2];
    signal output out;

    component n2b = Num2Bits(n+1);

    n2b.in <== in[0]+ (1<<n) - in[1];

    out <== 1-n2b.out[n];
}

bus Book() {
    signal {maxvalue} title[50];
    signal {maxvalue} author[50];
    signal {maxvalue} sold_copies;
    signal {maxvalue} year;
}

template BestSeller2024() {
    input Book() book;
    output Book() {best_seller2024} best_book;
    signal check_copies <== LessThan(book.sold_copies.maxvalue)([1000000,book.sold_copies]);
    check_copies === 1;
    signal check_2024 <== IsEqual()([book.year,2024]);
    check_2024 === 1;
    best_book <== book;
}

template Caller() {
    input signal title[50];
    input signal author[50];
    input signal sold_copies;
    input signal year;

    Book() b;
    b.title <== title;
    b.author <== author;
    b.sold_copies <== sold_copies;
    b.year <== year;

    Book seller <== BestSeller2024()(b);
    output signal sold <== seller.sold_copies;
}

component main = Caller();
// CHECK: TODO
