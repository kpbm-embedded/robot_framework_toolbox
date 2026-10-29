#include <zephyr/kernel.h>
#include <zephyr/shell/shell.h>

static int cmd_hello(const struct shell *sh, size_t argc, char **argv)
{
	shell_print(sh, "hello %s", argc > 1 ? argv[1] : "world");
	return 0;
}
static int cmd_up(const struct shell *sh, size_t argc, char **argv)
{
	shell_print(sh, "uptime %lld ms", k_uptime_get());
	return 0;
}
SHELL_STATIC_SUBCMD_SET_CREATE(demo_cmds,
	SHELL_CMD_ARG(hello, NULL, "hello [name]", cmd_hello, 1, 1),
	SHELL_CMD(uptime, NULL, "print uptime", cmd_up),
	SHELL_SUBCMD_SET_END);
SHELL_CMD_REGISTER(demo, &demo_cmds, "demo commands", NULL);

int main(void) { return 0; }
