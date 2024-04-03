#[derive(Copy, Clone, PartialEq, Eq, Debug, Ord, PartialOrd)]
pub enum ValueType {
    BigInt,
    U32,
}

impl ToString for ValueType {
    fn to_string(&self) -> String {
        match self {
            ValueType::U32 => "U32",
            ValueType::BigInt => "BigInt",
        }
        .to_string()
    }
}

#[derive(Copy, Clone, PartialEq, Eq, Debug, Ord, PartialOrd)]
pub struct InstrContext {
    pub size: usize,
}

impl std::fmt::Display for InstrContext {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:?}", self) // use Debug implementation
    }
}
