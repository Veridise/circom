# Circom to Coda

`example_intermediate_signal`:

``circom
pragma circom 2.0.0;

template Example1() {
    signal input x1;
    signal input x2;
    signal tmp;
    signal output y;
    tmp <== x1;
    y <== tmp * x2;
}

component main {public [x1, x2]} = Example1();
```

transpiles to

```ml
let template___Example1 = Hoare_circuit
    { name= "Example1"
    ; inputs= [("x1", field); ("x2", field)]
    ; outputs= [("y", field)]
    ; preconditions= []
    ; postcondition= []
    ; body=
        let tmp = ((var "x1")) in
        let y = (((var "tmp") * (var "x2"))) in
        ((y)) }

let generator___Example1 x1 x2 =
    let tmp = (x1) in
    let y = ((tmp * x2)) in
    ((y))
```

`example_subcmp`

```circom
pragma circom 2.0.0;

template Id1() {
  signal input x;
  signal output y;
  y <== x;
}

template Id2() {
  signal input x;
  signal output y;
  y <== x;
}

template Main() {
  signal input a;
  component id1 = Id1();
  component id2 = Id2();
  id1.x <== a;
  id2.x <== a;
  signal output b;
  b <== id1.y;
}

component main {public [a]} = Main();
```

```ml
let template___Id1 = Hoare_circuit
    { name= "Id1"
    ; inputs= [("a", field)]
    ; outputs= [("b", field)]
    ; preconditions= []
    ; postcondition= []
    ; body=
        let b = var "a" in
        b)
    }

let generator___Id1 a = let
    b = a in
    b

let template___Id2 = Hoare_circuit { name= "Id2"; inputs= [("x", field)]; outputs= [("y", field)]; preconditions= []; postcondition= []; body= let y = ((var "x")) in ((y)) }

let generator___Id2 x = let y = (x) in ((y))

let template___Main = Hoare_circuit { name= "Main"; inputs= [("x", field)]; outputs= [("y", field)]; preconditions= []; postcondition= []; body= let (subcomponent___id1___b) = template___Main  in let (subcomponent___id2___y) = template___Id1  in let subcomponent___id1___a = ((var "x")) in (let subcomponent___id2___x = ((var "x")) in (let y = (subcomponent___id1___b) in ((y)))) }

let generator___Main x =
    let subcomponent___id1___b = template___Main in // the offset is wrong, needs +1
    let subcomponent___id2___y = template___Id1 in // the offset is wrong, needs +1
    let subcomponent___id1___a = x in
    let subcomponent___id2___x = x in
    let y = subcomponent___id1___b in
    y
```
