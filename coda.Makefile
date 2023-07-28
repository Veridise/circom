constants:
	cargo run -- coda/tests/constants.circom --summary --coda --coda-output coda/tests/constants.ml -o coda/tests/

gates:
	cargo run -- coda/tests/gates.circom --summary --coda --coda-output coda/tests/gates.ml -o coda/tests/

subcomponent:
	cargo run -- coda/tests/subcomponent.circom --summary --coda --coda-output coda/tests/subcomponent.ml -o coda/tests/

mux1:
	# cargo run -- coda/tests/semaphore/mux1_test.circom --summary 
	cargo run -- coda/tests/semaphore/mux1_test.circom --summary --coda --coda-output coda/tests/semaphore/mux1_test.ml -o coda/tests/semaphore
