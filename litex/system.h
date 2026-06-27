#ifndef __SYSTEM_H
#define __SYSTEM_H

#ifdef __cplusplus
extern "C" {
#endif

static inline void flush_cpu_icache(void) {}
static inline void flush_cpu_dcache(void) {}

void flush_l2_cache(void);

#ifdef __cplusplus
}
#endif

#endif
