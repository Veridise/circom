# basic

constants:
	cargo run -- coda/tests/constants.circom --summary --coda --coda-output coda/tests/constants.ml -o coda/tests/

variables:
	cargo run -- coda/tests/variables.circom --summary --coda --coda-output coda/tests/variables.ml -o coda/tests/

# subcomponents


subcomponents1:
	cargo run -- coda/tests/subcomponents/subcomponents1.circom --summary --coda --coda-output coda/tests/subcomponents/subcomponents1.ml -o coda/tests/subcomponents

subcomponents2:
	cargo run -- coda/tests/subcomponents/subcomponents2.circom --summary --coda --coda-output coda/tests/subcomponents/subcomponents2.ml -o coda/tests/subcomponents

# gates

xor:
	cargo run -- coda/tests/gates/xor_test.circom --summary -o coda/tests/gates/ --coda --coda-output /Users/henry/Documents/Coda/dsl/circuits/circomlib/xor.ml

multiand:
	cargo run -- coda/tests/gates/multiand_test.circom --summary -o coda/tests/gates/ --coda --coda-output /Users/henry/Documents/Coda/dsl/circuits/circomlib/multiand.ml

# semaphore

mux1:
	cargo run -- coda/tests/semaphore/mux1_test.circom --summary --coda --coda-output coda/tests/semaphore/mux1_test.ml -o coda/tests/semaphore

multiand_test:
	cargo run -- coda/tests/multiand_test.circom --summary --coda --coda-output coda/tests/multiand_test.ml -o coda/tests/

poseidon:
	cargo run -- coda/tests/semaphore/poseidon_test.circom --summary --coda --coda-output coda/tests/semaphore/poseidon_test.ml -o coda/tests/semaphore

tree:
	cargo run -- coda/tests/semaphore/tree_test.circom --summary --coda --coda-output coda/tests/semaphore/tree_test.ml -o coda/tests/semaphore

semaphore:
	# cargo run -- coda/tests/semaphore/semaphore.circom --summary --coda --coda-output coda/tests/semaphore/semaphore.ml -o coda/tests/semaphore
	cargo run -- coda/tests/semaphore/semaphore.circom --summary -o coda/tests/semaphore --coda --coda-output /Users/henry/Documents/Coda/dsl/circuits/semaphore_new/semaphore_new.ml
