use std::ffi::{c_char, CString};

#[no_mangle]
pub extern "C" fn jk27_version() -> *mut c_char {
    CString::new("JITKit27 Rust Core 0.1.0").unwrap().into_raw()
}

#[no_mangle]
pub unsafe extern "C" fn jk27_string_free(value: *mut c_char) {
    if !value.is_null() { drop(CString::from_raw(value)); }
}

// Stable ABI boundary. Pairing and RSD functions are added behind this layer
// so Swift does not depend on Rust implementation types.
