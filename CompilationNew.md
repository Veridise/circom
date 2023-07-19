# Compilation (new, without CodaProducer)

```mermaid
graph
compile["compilation_user::compile(config, program_archive, prime)"] -- "if config.coda_flag" 
-->
write_coda["compiler_interface::write_coda(circuit, summary_file, coda_file)"]
-->
produce_coda["circuit.produce_coda(self, summary_root, writer)"]
-->
```