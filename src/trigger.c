/*
 * trigger:  fire triggers before and/or after repository level commands.
 *
 * Copyright (c) 2000, David Parsons & Larry McVoy.
 */

#include "system.h"
#include "sccs.h"

int
trigger(char *action, char *when, int status)
{
	char	*what;
	char	*var;
	char	*t;
	char	file[MAXPATH];

	unless (bk_proj && bk_proj->root) return (1);
	unless (t = strchr(action, ' ')) return (1);
	t++;

	if (strneq(t, "remote pull", 11) || strneq(t, "push", 4) ||
	    strneq(t, "clone", 5) || strneq(t, "remote clone", 12)) {
		what = "outgoing";
		var = "BK_OUTGOING";
    	} else if (
	    strneq(t, "remote push", 11) || strneq(t, "pull", 4)) {
		what = "incoming";
		var = "BK_INCOMING";
	} else if (strneq(t, "commit", 6)) {
		what = "commit";
		var = "BK_COMMIT";
	} else {
		return (1);
	}

	sprintf(file, "%s/%s/%s-%s", bk_proj->root, TRIGGERS, when, what);
	get(file, SILENT, "-");
#ifdef WIN32
	if (exists(file)) {
#else
	if (access(file, X_OK) == 0) {
#endif
		char	cmd[MAXPATH*4];

		if (status) {
			sprintf(cmd, "%s=ERROR %d", var, status);
			putenv((strdup)(cmd));
		} else unless (t = getenv(var)) {
			sprintf(cmd, "%s=OK", var);
			putenv((strdup)(cmd));
		}
		sprintf(file, "%s/%s-%s", TRIGGERS, when, what);
#ifdef WIN32
		sprintf(cmd,
		    "bash -c \"cd %s; %s %s %s\"", bk_proj->root, file, when, action);
#else
		sprintf(cmd,
		    "cd %s; %s %s %s", bk_proj->root, file, when, action);
#endif
		if (system(cmd)) return (1);
	}
	return (0);
}