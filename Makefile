coda-test:
	cargo run -- --coda --summary -o coda/circomlib coda/circomlib/gates_test_and.circom
	cargo run -- --coda --summary -o coda/circomlib coda/circomlib/gates_test_nand.circom
	cargo run -- --coda --summary -o coda/circomlib coda/circomlib/gates_test_nor.circom
	cargo run -- --coda --summary -o coda/circomlib coda/circomlib/gates_test_not.circom
	cargo run -- --coda --summary -o coda/circomlib coda/circomlib/gates_test_or.circom
	cargo run -- --coda --summary -o coda/circomlib coda/circomlib/gates_test_xor.circom
