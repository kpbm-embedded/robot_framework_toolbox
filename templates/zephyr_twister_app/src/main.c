#include <zephyr/kernel.h>
#include <zephyr/shell/shell.h>

static int cmd_ping(const struct shell *sh, size_t argc, char **argv)
{
	ARG_UNUSED(argc);
	ARG_UNUSED(argv);
	shell_print(sh, "pong");
	return 0;
}
SHELL_CMD_REGISTER(ping, NULL, "answers pong", cmd_ping);

int main(void)
{
	return 0;
}
