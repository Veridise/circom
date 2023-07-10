/// Emulates a lit test
fn lit_test(content: &str) -> Result<(), Box<dyn std::error::Error>> {
    todo!()
    // Write the content to a temporary file
    // Create a temporary file for the test
    // Get the path where the cargo binary is and override PATH with it
    // Get the RUN statement in the test
    // If there is none fail the test
    // If there is load a shell with the command
    // replacing %s with the temporary file with the contents
    // and %t with the temporary file
    // Remove %t. Could be anything so `rm -rf` it.
    // Check the status of the test
}

// build.rs generates this file with the discovered circom tests in this crate
include!(concat!(env!("OUT_DIR"), "/discovered_tests.in"));