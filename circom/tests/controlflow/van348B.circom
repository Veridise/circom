//Ensure all blocks have terminators when control flow does not continue past any branch
//	of the if statement (and the merge block after should not even be generated).
//	This case adds additional complexity due to nesting of if statements.

pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s

function short_div(n) {
   if (n > 1) {
      if (n > 5) {
         return 2;
      } else {
         return 1;
      }
   } else {
       return 0;
   }
}

function long_div(){
    var out[1];
    out[0] = short_div(8);
    return out;
}

template BigModOld() {
    var longdiv[1] = long_div();
}

component main = BigModOld();
