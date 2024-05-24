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
pub(crate) type REI<'e> = InterpRes<(Option<Value>, Env<'e>)>;
/// Like 'super::RC' but internally uses InterpRes instead of Result
pub(crate) type RCI = InterpRes<Option<Value>>;
/// Like 'super::RG' but internally uses InterpRes instead of Result
pub(crate) type RGI<E> = InterpRes<(Option<Value>, E)>;
/// Like 'RGI' but the value of a condition is also needed
pub(crate) type RBI<E> = InterpRes<(Option<Value>, Option<bool>, E)>;

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

impl<T> InterpRes<Option<T>> {
    /// NOTE: It is safe to use [Option::unwrap] on the Continue/Return variants of the return value
    #[must_use]
    pub fn expect_some<S: std::fmt::Display>(self, label: S) -> Self {
        match self {
            InterpRes::Continue(v) => {
                InterpRes::try_continue(opt_as_result(v, label).map(Option::Some))
            }
            InterpRes::Return(v) => {
                InterpRes::try_return(opt_as_result(v, label).map(Option::Some))
            }
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

#[must_use]
pub fn opt_as_result<D, S: std::fmt::Display>(value: Option<D>, label: S) -> Result<D, BadInterp> {
    match value {
        Some(v) => Result::Ok(v),
        None => Result::Err(new_compute_err(format!("Could not compute {}!", label))),
    }
}

#[must_use]
pub fn opt_as_result_u32<S: std::fmt::Display>(
    value: Option<Value>,
    label: S,
) -> Result<usize, BadInterp> {
    opt_as_result(value, label).and_then(Value::as_u32)
}
