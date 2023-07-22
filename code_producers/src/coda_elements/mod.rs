pub struct CodaProgram {}

pub struct CodaCircuit {
    pub signals: Vec<CodaSignal>,
}

pub struct CodaSignal {
    pub name: String,
}

pub trait CodaCompile {
  fn coda_compile(&self) -> String;
}