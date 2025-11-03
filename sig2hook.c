#define _GNU_SOURCE
#include <dlfcn.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/syscall.h>
#include <ucontext.h>
#include <unistd.h>

static const char CTOR_MSG[] = "== [libsig2hook] loaded ==\n";
static const char DTOR_MSG[] = "== [libsig2hook] unloading ==\n";

void patched_asm(void) {
    int a = 777777;
    int b = 7000000;

    asm volatile("sub sp, sp, #0x10");

    asm volatile(
        "mov x0, %x[x0]\n"
        "mov x1, %x[x1]\n"
        "br  x16\n"
        : [x0] "+r"(a), [x1] "+r"(b));
}

void signal_ill_handler(__attribute__((unused)) int signum,
                        __attribute__((unused)) siginfo_t *info, void *ptr) {
    const uintptr_t pc = ((ucontext_t *)ptr)->uc_mcontext.pc;
    ((ucontext_t *)ptr)->uc_mcontext.regs[16] = pc + 0x4;
    ((ucontext_t *)ptr)->uc_mcontext.pc = (uint64_t)&patched_asm;
}

__attribute__((constructor)) static void libsig2hook_ctor(void) {
    printf(CTOR_MSG);

    struct sigaction action;
    memset(&action, 0, sizeof(action));
    action.sa_sigaction =
        (void (*)(int, siginfo_t *, void *))signal_ill_handler;
    action.sa_flags = SA_SIGINFO;
    if (sigaction(SIGILL, &action, NULL) == -1) {
        {
            fprintf(stderr, "sigaction error");
            exit(1);
        }
    }
}

__attribute__((destructor)) static void libsig2hook_dtor(void) {
    printf(DTOR_MSG);
}
