#ifndef JITKIT27_H
#define JITKIT27_H
#include <stdint.h>
#include <stddef.h>
typedef struct { char *error; char *device_name; char *device_model; char *device_udid; char *pairing_file_path; char *host_alt_irk_hex; } Jk27PairResult;
typedef void (*Jk27ReadyCb)(void *ctx,const char *service_id,uint16_t port,const char * const *keys,const char * const *values,size_t count);
typedef void (*Jk27PinCb)(void *ctx,const char *pin);
char *jk27_version(void);
void jk27_string_free(char *value);
int32_t jk27_pairing_run_host(const char *bind,uint16_t port,const char *name,const char *model,const char *path,const char *host_alt_irk_hex,Jk27ReadyCb ready,Jk27PinCb pin,void *ctx,Jk27PairResult *result);
void jk27_pair_result_free(Jk27PairResult *result);
#endif
