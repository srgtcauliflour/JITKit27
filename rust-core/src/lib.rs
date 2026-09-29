use std::ffi::{c_char,c_void,CString};
mod pairing;
pub use pairing::Jk27PairResult;
#[no_mangle] pub extern "C" fn jk27_version()->*mut c_char{CString::new("JITKit27 Rust Core 0.1.0").unwrap().into_raw()}
#[no_mangle] pub unsafe extern "C" fn jk27_string_free(v:*mut c_char){if !v.is_null(){drop(CString::from_raw(v));}}
#[no_mangle] pub unsafe extern "C" fn jk27_pairing_run_host(bind:*const c_char,port:u16,name:*const c_char,model:*const c_char,path:*const c_char,irk:*const c_char,ready:pairing::ReadyCb,pin:pairing::PinCb,ctx:*mut c_void,result:*mut Jk27PairResult)->i32{pairing::run_host(bind,port,name,model,path,irk,ready,pin,ctx,result)}
#[no_mangle] pub unsafe extern "C" fn jk27_pair_result_free(r:*mut Jk27PairResult){pairing::result_free(r)}
