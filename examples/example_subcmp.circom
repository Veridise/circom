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
  // signal: SignalSummary { name: "a", visibility: "input", idx: 1, public: false }
  signal input a;

  // CreateCmp:
  //  • name: id1
  component id1 = Id1();
  // CreateCmp:
  //  • name: id2
  component id2 = Id2();

  // Store:
  // • dest_address_type: SubcmpSignal(Value(parse_as: U32, value: 0))
  // • dest: Location/Value(1, template_header: Some("Id1_0"))
  // • src: Load(Location/Value(1, template_header: None))
  id1.x <== a;

  // Store:
  // • dest_address_type: SubcmpSignal(Value(parse_as: U32, value: 1))
  // • dest: Location/Value(1, template_header: Some("Id2_1"))
  // • src: Load(Location/Value(1, template_header: None))
  id2.x <== a;

  // signal: SignalSummary { name: "b", visibility: "output", idx: 0, public: false }
  signal output b;

  // Store:
  // • dest_address_type: Signal
  // • dest: Location/Value(0, template_header: None)
  // • src: Load(Location/Value(0, template_header: Some("Id1_0")))
  b <== id1.y;
}

component main {public [a]} = Main();
