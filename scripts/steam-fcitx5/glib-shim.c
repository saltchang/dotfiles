/* glib >= 2.68 symbols that host-built im-fcitx5.so needs but Steam Runtime's glib 2.66 lacks.
   Prototypes declared by hand: glib headers turn g_once_init_* into macros. */
#include <stddef.h>
typedef struct _GString GString;
void *g_memdup(const void *mem, unsigned int byte_size);
int g_once_init_enter(volatile void *location);
void g_once_init_leave(volatile void *location, size_t result);
char *g_string_free(GString *string, int free_segment);

void *g_memdup2(const void *mem, size_t byte_size) { return g_memdup(mem, (unsigned int)byte_size); }
int g_once_init_enter_pointer(void *location) { return g_once_init_enter(location); }
void g_once_init_leave_pointer(void *location, void *result) { g_once_init_leave(location, (size_t)result); }
char *g_string_free_and_steal(GString *string) { return g_string_free(string, 0); }
