// CodaConfig

struct CodaConfig {
    mode: CodaCircuitMode,
}

impl Default for CodaConfig {
    fn default() -> Self {
        CodaConfig { mode: CodaCircuitMode::Normal }
    }
}

// CodaCircuitMode

enum CodaCircuitMode {
    Normal,
    Hoare,
}
