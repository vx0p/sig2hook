#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <sys/syscall.h>
#include <unistd.h>

static const char HOOK_PREFIX[] = "[HOOKED] ";
static const char CTOR_MSG[] = "== [libhook] loaded ==\n";
static const char DTOR_MSG[] = "== [libhook] unloading ==\n";
static const char ERR_MSG[] = "== [libhook] failed to resolve symbol ==\n";

// writeのhook中で再帰を避けるための書き込み
static inline ssize_t safe_write(int fd, const void *buf, size_t len) {
    return syscall(SYS_write, fd, buf, len);
}

static ssize_t (*orig_write)(int, const void *, size_t) = NULL;
static int (*orig_puts)(const char *) = NULL;

static void resolve_symbols(void) {
    orig_write =
        (ssize_t(*)(int, const void *, size_t))dlsym(RTLD_NEXT, "write");
    orig_puts = (int (*)(const char *))dlsym(RTLD_NEXT, "puts");
}

__attribute__((constructor)) static void libhook_ctor(void) {
    safe_write(STDOUT_FILENO, CTOR_MSG, sizeof(CTOR_MSG) - 1);
}

__attribute__((destructor)) static void libhook_dtor(void) {
    safe_write(STDOUT_FILENO, DTOR_MSG, sizeof(DTOR_MSG) - 1);
}

ssize_t write(int fd, const void *buf, size_t count) {
    if (!orig_write) {
        orig_write =
            (ssize_t(*)(int, const void *, size_t))dlsym(RTLD_NEXT, "write");
        if (!orig_write) {  // 解決失敗時
            return safe_write(fd, buf, count);
        }
    }

    if (fd == STDOUT_FILENO || fd == STDERR_FILENO) {
        (void)orig_write(fd, HOOK_PREFIX, sizeof(HOOK_PREFIX) - 1);
    }

    return orig_write(fd, buf, count);
}

int puts(const char *s) {
    if (!orig_write || !orig_puts) {
        resolve_symbols();
    }

    if (orig_write) {
        (void)orig_write(STDOUT_FILENO, HOOK_PREFIX, sizeof(HOOK_PREFIX) - 1);
    }

    if (orig_puts) {
        return orig_puts(s);
    }

    // 解決失敗時
    safe_write(STDERR_FILENO, ERR_MSG, sizeof(ERR_MSG) - 1);
    return EOF;
}
