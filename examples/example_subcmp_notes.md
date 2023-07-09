========================================================
Signal output b
Signal input a
Store:
  • dest_address_type: Signal
  • dest: Location/Value(0, template_header: None)
  • src: Load(Location/Value(1, template_header: None))
========================================================

========================================================
Signal output y
Signal input x
Store:
  • dest_address_type: Signal
  • dest: Location/Value(0, template_header: None)
  • src: Load(Location/Value(1, template_header: None))
========================================================

========================================================
Signal output y
Signal input x
CreateCmp:
   • name: id1
CreateCmp:
   • name: id2
Store:
  • dest_address_type: SubcmpSignal(Value(parse_as: U32, value: 0))
  • dest: Location/Value(1, template_header: Some("Id1_0"))
  • src: Load(Location/Value(1, template_header: None))
Store:
  • dest_address_type: SubcmpSignal(Value(parse_as: U32, value: 1))
  • dest: Location/Value(1, template_header: Some("Id2_1"))
  • src: Load(Location/Value(1, template_header: None))
Store:
  • dest_address_type: Signal
  • dest: Location/Value(0, template_header: None)
  • src: Load(Location/Value(0, template_header: Some("Id1_0")))
========================================================
