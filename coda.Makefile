# basic

constants:
	cargo run -- coda/tests/constants.circom --summary --coda --coda-output coda/tests/constants.ml -o coda/tests/

variables:
	cargo run -- coda/tests/variables.circom --summary --coda --coda-output coda/tests/variables.ml -o coda/tests/

iteration:
	cargo run -- coda/tests/iteration.circom --summary --coda --coda-output coda/tests/iteration.ml -o coda/tests/

abstract:
	cargo run -- coda/tests/abstract.circom --summary --coda --coda-output coda/tests/abstract.ml -o coda/tests/

abstract_output_tuple:
	cargo run -- coda/tests/abstract_output_tuple.circom --summary --coda --coda-output coda/tests/abstract_output_tuple.ml -o coda/tests/

# subcomponents

subcomponents1:
	cargo run -- coda/tests/subcomponents/subcomponents1.circom --summary --coda --coda-output coda/tests/subcomponents/subcomponents1.ml -o coda/tests/subcomponents

subcomponents2:
	cargo run -- coda/tests/subcomponents/subcomponents2.circom --summary --coda --coda-output coda/tests/subcomponents/subcomponents2.ml -o coda/tests/subcomponents

subcomponents3:
	cargo run -- coda/tests/subcomponents/subcomponents3.circom --summary --coda --coda-output coda/tests/subcomponents/subcomponents3.ml -o coda/tests/subcomponents

# gates

xor:
	cargo run -- coda/tests/gates/xor_test.circom --summary -o coda/tests/gates/ --coda --coda-output /Users/henry/Documents/Coda/dsl/circuits/circomlib/xor.ml

# unirep

unirep_userStateTransition:
	cargo run -- coda/tests/unirep/userStateTransition_test.circom --summary -o coda/tests/unirep --coda --coda-output /Users/henry/Documents/Coda/dsl/circuits/unirep_auto/userStateTransition_auto.ml.gen

# semaphore

mux1:
	cargo run -- coda/tests/semaphore/mux1_test.circom --summary --coda --coda-output coda/tests/semaphore/mux1_test.ml -o coda/tests/semaphore


multiand:
	cargo run -- coda/tests/gates/multiand_test.circom --summary -o coda/tests/gates/ --coda --coda-output /Users/henry/Documents/Coda/dsl/circuits/circomlib/multiand.ml
	# cargo run -- coda/tests/gates/multiand_test.circom --summary --coda --coda-output coda/tests/gates/multiand_test.ml -o coda/tests/gates/


poseidon:
	cargo run -- coda/tests/semaphore/poseidon_test.circom --summary --coda --coda-output coda/tests/semaphore/poseidon_test.ml -o coda/tests/semaphore

tree:
	cargo run -- coda/tests/semaphore/tree_test.circom --summary --coda --coda-output coda/tests/semaphore/tree_test.ml -o coda/tests/semaphore

semaphore:
	# cargo run -- coda/tests/semaphore/semaphore.circom --summary --coda --coda-output coda/tests/semaphore/semaphore.ml -o coda/tests/semaphore
	cargo run -- coda/tests/semaphore/semaphore.circom --summary -o coda/tests/semaphore --coda --coda-output /Users/henry/Documents/Coda/dsl/circuits/semaphore_new/semaphore_new.ml.gen

# rln

rln:
	cargo run -- coda/tests/circom-rln/circuits/rln.circom --summary -o coda/tests/circom-rln/circuits/ --coda --coda-output /Users/henry/Documents/Coda/dsl/circuits/rln_auto/rln_auto.ml.gen

# darkforest

darkforest_init:
	cargo run -- coda/tests/darkforest/init/circuit.circom --summary -o coda/tests/darkforest/init/ --coda --coda-output /Users/henry/Documents/Coda/dsl/circuits/darkforest_auto/init_auto.ml.gen

# hydra-s1

hydra-s1:
	cargo run -- coda/tests/hydra_auto/circuits/hydra-s1.circom --summary -o coda/tests/hydra-s1/circuits/ --coda --coda-output /Users/henry/Documents/Coda/dsl/circuits/hydra_auto/hydra_auto.ml.gen
