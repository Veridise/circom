use std::collections::{BTreeSet, HashMap};
use codespan_reporting::files::Files;
use compiler::intermediate_representation::ir_interface::ObtainMeta;
use program_structure::{
    error_code::ReportCode, error_definition::Report, file_definition::FileLibrary,
};
use super::InterpRes;

const MUST_EXECUTE: &str = "Compute does not support Env modification. Use execute instead.";

#[derive(Clone, Debug)]
pub struct BadInterp {
    is_error: bool,
    message: String,
    code: ReportCode,
    file_to_lines: HashMap<Option<usize>, BTreeSet<usize>>,
}

impl BadInterp {
    #[must_use]
    fn new(is_error: bool, message: String, code: ReportCode) -> BadInterp {
        BadInterp { is_error, message, code, file_to_lines: Default::default() }
    }

    #[must_use]
    pub fn error(error_message: String, code: ReportCode) -> BadInterp {
        BadInterp::new(true, error_message, code)
    }

    #[must_use]
    pub fn warning(error_message: String, code: ReportCode) -> BadInterp {
        BadInterp::new(false, error_message, code)
    }

    pub fn get_message(&self) -> &String {
        &self.message
    }

    pub fn add_location<L: ObtainMeta>(&mut self, location: &L) -> &mut Self {
        self.file_to_lines
            .entry(location.get_source_file_id().clone())
            .or_default()
            .insert(location.get_line());
        self
    }

    #[must_use]
    pub fn to_report(self, file_library: &FileLibrary) -> Report {
        let mut res = if self.is_error {
            Report::error(self.message, self.code)
        } else {
            Report::warning(self.message, self.code)
        };
        for (file, lines) in self.file_to_lines {
            // NOTE: FileLibrary always inserts "<generated>" at index 0 to account for None location
            let file_id = file.unwrap_or(0);

            // Add location info to the report by mapping line numbers back to byte offsets
            //  and merging adjecent lines into a single location.
            let mut curr_range = None;
            for line in lines {
                let next_range = match file_library.to_storage().line_range(file_id, line) {
                    None => usize::MIN..usize::MAX, // show full file if range was not determined properly
                    Some(r) => r,
                };
                match curr_range {
                    None => curr_range = Some(next_range),
                    Some(cr) => {
                        // ASSERT: lines are iterated in ascending order so next range is not less than current
                        assert!(next_range.start >= cr.start);
                        // Check for adjacent ranges and merge in that case. Otherwise, report the current one.
                        if next_range.start <= cr.end {
                            curr_range = Some(cr.start..cr.end.max(next_range.end));
                        } else {
                            res.add_primary(cr, file_id, String::from("found here"));
                            curr_range = Some(next_range);
                        }
                    }
                }
            }
            //print the final range (if present)
            if let Some(cr) = curr_range {
                res.add_primary(cr, file_id, String::from("found here"));
            }
        }
        res
    }
}

#[inline]
#[must_use]
pub fn new_inconsistency_err<S: ToString>(msg: S) -> BadInterp {
    BadInterp::error(msg.to_string(), ReportCode::InconsistentStaticInformation)
}

#[inline]
#[must_use]
pub fn new_compute_err<S: ToString>(msg: S) -> BadInterp {
    BadInterp::error(msg.to_string(), ReportCode::NonComputableExpression)
}

#[inline]
#[must_use]
pub fn new_compute_err_result<S: ToString, R>(msg: S) -> InterpRes<R> {
    InterpRes::Err(new_compute_err(msg))
}

#[inline]
#[must_use]
pub fn new_modifies_env_err() -> BadInterp {
    BadInterp::error(MUST_EXECUTE.to_string(), ReportCode::NonComputableExpression)
}

#[inline]
#[must_use]
pub fn new_modifies_env_err_result<R>() -> InterpRes<R> {
    InterpRes::Err(new_modifies_env_err())
}

#[inline]
#[must_use]
pub fn is_modifies_env_err(e: &BadInterp) -> bool {
    e.is_error && e.message.eq(MUST_EXECUTE)
}

#[inline]
#[must_use]
pub fn is_modifies_env_err_result<R>(e: &InterpRes<R>) -> bool {
    match e {
        InterpRes::Err(e) => is_modifies_env_err(e),
        _ => false,
    }
}
