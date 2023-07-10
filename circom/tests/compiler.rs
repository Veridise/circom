use std::error::Error;
use std::path::Path;
use assert_cmd::prelude::*;
use predicates::prelude::*;
use assert_fs::prelude::*;
use std::process::Command;

const CIRCOM: &str = "circom";

#[test]
fn should_compile() -> Result<(), Box<dyn Error>> {
    let mut cmd = Command::cargo_bin(CIRCOM)?;
    let tmp_dir = assert_fs::TempDir::new()?;
    let test_file = Path::new("tests/zzz/example.circom");
    cmd
        .arg("--llvm")
        .arg("-o").arg(tmp_dir.path())
        .arg(test_file);
    cmd.assert().success();
    Ok(())
}

#[test]
fn should_not_compile() -> Result<(), Box<dyn Error>> {
    let mut cmd = Command::cargo_bin(CIRCOM)?;
    let tmp_dir = assert_fs::TempDir::new()?;
    let test_file = Path::new("tests/arrays/array4.circom");
    cmd
        .arg("--llvm")
        .arg("-o").arg(tmp_dir.path())
        .arg(test_file);
    cmd.assert()
        .failure()
        .stderr(predicate::str::contains("Exception caused by invalid access: trying to access to an output signal of a component with not all its inputs initialized"));
    Ok(())
}