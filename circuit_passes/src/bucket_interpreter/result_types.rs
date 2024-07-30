use compiler::intermediate_representation::ir_interface::ObtainMeta;
use super::env::Env;
use super::error::{new_compute_err, BadInterp};
use super::value::Value;

#[derive(Clone, Debug)]
pub(crate) enum InterpRes<T> {
    Continue(T),
    Return(T),
    Err(BadInterp),
}

/// Like 'super::RE' but internally uses InterpRes instead of Result
pub(crate) type REI<'e> = InterpRes<(Vec<Value>, Env<'e>)>;
/// Like 'super::RC' but internally uses InterpRes instead of Result
pub(crate) type RCI = InterpRes<Vec<Value>>;
/// Like 'super::RG' but internally uses InterpRes instead of Result
pub(crate) type RGI<E> = InterpRes<(Vec<Value>, E)>;
/// Like 'RGI' but the value of a condition is also needed
pub(crate) type RBI<E> = InterpRes<(Vec<Value>, Option<bool>, E)>;

impl<T> InterpRes<T> {
    #[inline]
    #[must_use]
    pub fn try_continue(value: Result<T, BadInterp>) -> Self {
        match value {
            Err(e) => InterpRes::Err(e),
            Ok(t) => InterpRes::Continue(t),
        }
    }

    #[inline]
    #[must_use]
    pub fn try_return(value: Result<T, BadInterp>) -> Self {
        match value {
            Err(e) => InterpRes::Err(e),
            Ok(t) => InterpRes::Return(t),
        }
    }

    #[must_use]
    #[inline]
    pub fn map<U, F: FnOnce(T) -> U>(self, op: F) -> InterpRes<U> {
        match self {
            InterpRes::Continue(t) => InterpRes::Continue(op(t)),
            InterpRes::Return(t) => InterpRes::Return(op(t)),
            InterpRes::Err(e) => InterpRes::Err(e),
        }
    }

    #[must_use]
    pub fn add_loc_if_err<B: ObtainMeta>(self, loc: &B) -> Self {
        match self {
            InterpRes::Err(e) => InterpRes::Err({
                let mut new_e = e;
                new_e.add_location(loc);
                new_e
            }),
            r => r,
        }
    }
}

impl<T> InterpRes<Result<T, BadInterp>> {
    #[must_use]
    pub fn flatten(self) -> InterpRes<T> {
        match self {
            InterpRes::Continue(t) => InterpRes::try_continue(t),
            InterpRes::Return(t) => InterpRes::try_return(t),
            InterpRes::Err(e) => InterpRes::Err(e),
        }
    }
}

impl<T: std::fmt::Display> InterpRes<Vec<T>> {
    #[must_use]
    pub fn expect_single<S: std::fmt::Display>(self, label: S) -> InterpRes<T> {
        match self {
            InterpRes::Continue(v) => InterpRes::try_continue(into_single_result(v, label)),
            InterpRes::Return(v) => InterpRes::try_return(into_single_result(v, label)),
            InterpRes::Err(e) => InterpRes::Err(e),
        }
    }
}

impl<T> From<InterpRes<T>> for Result<T, BadInterp> {
    #[must_use]
    fn from(value: InterpRes<T>) -> Self {
        match value {
            InterpRes::Continue(t) => Result::Ok(t),
            InterpRes::Return(t) => Result::Ok(t),
            InterpRes::Err(e) => Result::Err(e),
        }
    }
}

/// Produces the value inside of an InterpRes::Continue, otherwise immediately returns the InterpRes.
#[macro_export]
macro_rules! check_res {
    ($result:expr) => {{
        use $crate::bucket_interpreter::result_types::InterpRes;
        match $result {
            InterpRes::Continue(t) => t,
            InterpRes::Return(t) => return InterpRes::Return(t),
            InterpRes::Err(e) => return InterpRes::Err(e),
        }
    }};
    ($result:expr, $return_converter:expr) => {{
        use $crate::bucket_interpreter::result_types::InterpRes;
        match $result {
            InterpRes::Continue(t) => t,
            InterpRes::Return(t) => return InterpRes::Return($return_converter(t)),
            InterpRes::Err(e) => return InterpRes::Err(e),
        }
    }};
}

/// Produces the result inside Ok, otherwise immediately returns an InterpRes with the error.
#[macro_export]
macro_rules! check_std_res {
    ($result:expr) => {{
        use $crate::bucket_interpreter::result_types::InterpRes;
        match $result {
            Result::Ok(t) => t,
            Result::Err(e) => return InterpRes::Err(e),
        }
    }};
}

#[inline]
#[must_use]
pub fn into_singleton_vec<D>(value: Option<D>) -> Vec<D> {
    match value {
        Some(v) => vec![v],
        None => vec![],
    }
}

#[inline]
#[must_use]
pub fn into_single_option<D>(values: Vec<D>) -> Option<D> {
    let mut values = values;
    match values.len() {
        1 => values.pop(),
        _ => None,
    }
}

#[inline]
#[must_use]
pub fn into_single_result_u32<S: std::fmt::Display>(
    values: Vec<Value>,
    label: S,
) -> Result<usize, BadInterp> {
    into_single_result(values, label).and_then(Value::as_u32)
}

#[must_use]
pub fn into_single_result<D: std::fmt::Display, S: std::fmt::Display>(
    values: Vec<D>,
    label: S,
) -> Result<D, BadInterp> {
    let mut values = values;
    match &values[..] {
        [] => Result::Err(new_compute_err(format!("Could not compute {}!", label))),
        [_] => Result::Ok(values.remove(0)),
        [head, tail @ ..] => {
            let s = tail.iter().fold(format!("{}", head), |acc, nxt| format!("{},{}", acc, nxt));
            Result::Err(new_compute_err(format!("Non-scalar value for {}: [{}]", label, s)))
        }
    }
}

#[must_use]
pub fn into_result<D, S: std::fmt::Display>(values: Vec<D>, label: S) -> Result<Vec<D>, BadInterp> {
    match &values[..] {
        [] => Result::Err(new_compute_err(format!("Could not compute {}!", label))),
        _ => Result::Ok(values),
    }
}
