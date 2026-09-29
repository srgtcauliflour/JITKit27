use std::ffi::{c_char,c_void,CStr,CString};
use std::net::{IpAddr,Ipv4Addr,SocketAddr};
use std::ptr;
use idevice::remote_pairing::{PairableHost,PairableHostInfo,RpPairingFile,RpPairingSocket};
use tokio::net::TcpListener;

pub type ReadyCb=Option<extern "C" fn(*mut c_void,*const c_char,u16,*const *const c_char,*const *const c_char,usize)>;
pub type PinCb=Option<extern "C" fn(*mut c_void,*const c_char)>;

#[repr(C)]
pub struct Jk27PairResult { pub error:*mut c_char,pub device_name:*mut c_char,pub device_model:*mut c_char,pub device_udid:*mut c_char,pub pairing_file_path:*mut c_char,pub host_alt_irk_hex:*mut c_char }
impl Jk27PairResult { fn empty()->Self{Self{error:ptr::null_mut(),device_name:ptr::null_mut(),device_model:ptr::null_mut(),device_udid:ptr::null_mut(),pairing_file_path:ptr::null_mut(),host_alt_irk_hex:ptr::null_mut()}} }
struct Callbacks{ready:ReadyCb,pin:PinCb,ctx:*mut c_void}
unsafe impl Send for Callbacks {}

fn s(p:*const c_char,default:&str)->String{if p.is_null(){default.into()}else{unsafe{CStr::from_ptr(p)}.to_string_lossy().into_owned()}}
fn out(s:impl Into<String>)->*mut c_char{CString::new(s.into()).unwrap_or_default().into_raw()}
fn parse_irk(v:&str)->Option<[u8;16]>{if v.len()!=32{return None}let mut a=[0;16];for(i,b)in a.iter_mut().enumerate(){*b=u8::from_str_radix(&v[i*2..i*2+2],16).ok()?;}Some(a)}
fn hex(v:&[u8])->String{v.iter().map(|b|format!("{b:02x}")).collect()}

pub unsafe fn run_host(bind:*const c_char,port:u16,name:*const c_char,model:*const c_char,path:*const c_char,irk:*const c_char,ready:ReadyCb,pin:PinCb,ctx:*mut c_void,result:*mut Jk27PairResult)->i32{
 if result.is_null(){return 2} *result=Jk27PairResult::empty();
 let rt=match tokio::runtime::Builder::new_multi_thread().enable_all().build(){Ok(v)=>v,Err(e)=>{(*result).error=out(format!("runtime: {e}"));return 1}};
 match rt.block_on(run(s(bind,"0.0.0.0"),port,s(name,"JITKit27"),s(model,"Mac17,7"),s(path,"rp_pairing_file.plist"),parse_irk(&s(irk,"")),Callbacks{ready,pin,ctx})){
  Ok(v)=>{(*result).device_name=out(v.0);(*result).device_model=out(v.1);(*result).device_udid=out(v.2);(*result).pairing_file_path=out(v.3);(*result).host_alt_irk_hex=out(v.4);0},
  Err(e)=>{(*result).error=out(e);1}
 }
}
async fn run(bind:String,port:u16,name:String,model:String,path:String,saved:Option<[u8;16]>,cbs:Callbacks)->Result<(String,String,String,String,String),String>{
 let ip:IpAddr=bind.parse().unwrap_or(IpAddr::V4(Ipv4Addr::UNSPECIFIED));
 let listener=TcpListener::bind(SocketAddr::new(ip,port)).await.map_err(|e|format!("bind: {e}"))?;
 let port=listener.local_addr().map_err(|e|e.to_string())?.port();
 let mut file=match RpPairingFile::read_from_file(&path).await{Ok(mut f)=>{f.alt_irk=None;f},Err(_)=>RpPairingFile::generate(&name)};
 let mut info=PairableHostInfo::generate(&name,&model);if let Some(v)=saved{info.alt_irk=v}let host_irk=info.alt_irk;let id=file.identifier.clone();
 if let Some(cb)=cbs.ready{let records=info.mdns_txt_records(&id);let ks:Vec<CString>=records.iter().map(|(k,_)|CString::new(k.as_str()).unwrap()).collect();let vs:Vec<CString>=records.iter().map(|(_,v)|CString::new(v.as_str()).unwrap()).collect();let kp:Vec<_>=ks.iter().map(|v|v.as_ptr()).collect();let vp:Vec<_>=vs.iter().map(|v|v.as_ptr()).collect();let ci=CString::new(id).unwrap();cb(cbs.ctx,ci.as_ptr(),port,kp.as_ptr(),vp.as_ptr(),records.len());}
 let(stream,_)=listener.accept().await.map_err(|e|format!("accept: {e}"))?;let mut host=PairableHost::new(RpPairingSocket::new_device(stream),info);let ctx_addr=cbs.ctx as usize;let pin_cb=cbs.pin;
 let peer=host.accept(&mut file,move|p|async move{if let Some(cb)=pin_cb{if let Ok(c)=CString::new(p){cb(ctx_addr as *mut c_void,c.as_ptr())}}}).await.map_err(|e|format!("pairing: {e}"))?;
 file.write_to_file(&path).await.map_err(|e|format!("write pairing file: {e}"))?;let size=tokio::fs::metadata(&path).await.map(|m|m.len()).unwrap_or(0);if size==0{return Err("pairing file is empty".into())}
 Ok((peer.name,peer.model,peer.remotepairing_udid,path,hex(&host_irk)))
}
pub unsafe fn result_free(r:*mut Jk27PairResult){if r.is_null(){return}for p in[(*r).error,(*r).device_name,(*r).device_model,(*r).device_udid,(*r).pairing_file_path,(*r).host_alt_irk_hex]{if !p.is_null(){drop(CString::from_raw(p));}}*r=Jk27PairResult::empty();}
