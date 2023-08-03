constants:
	cargo run -- coda/tests/constants.circom --summary --coda --coda-output coda/tests/constants.ml -o coda/tests/

gates:
	cargo run -- coda/tests/gates.circom --summary --coda --coda-output coda/tests/gates.ml -o coda/tests/

variables:
	cargo run -- coda/tests/variables.circom --summary --coda --coda-output coda/tests/variables.ml -o coda/tests/

subcomponents1:
	cargo run -- coda/tests/subcomponents/subcomponents1.circom --summary --coda --coda-output coda/tests/subcomponents/subcomponents1.ml -o coda/tests/subcomponents

mux1:
	cargo run -- coda/tests/semaphore/mux1_test.circom --summary --coda --coda-output coda/tests/semaphore/mux1_test.ml -o coda/tests/semaphore

multiand_test:
	cargo run -- coda/tests/multiand_test.circom --summary --coda --coda-output coda/tests/multiand_test.ml -o coda/tests/

poseidon:
	cargo run -- coda/tests/semaphore/poseidon_test.circom --summary --coda --coda-output coda/tests/semaphore/poseidon_test.ml -o coda/tests/semaphore

semaphore:
	cargo run -- coda/tests/semaphore/semaphore.circom --summary --coda --coda-output coda/tests/semaphore/semaphore.ml -o coda/tests/semaphore
