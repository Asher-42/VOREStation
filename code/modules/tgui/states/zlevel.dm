/*!
 * Copyright (c) 2020 Aleksej Komarov
 * SPDX-License-Identifier: MIT
 */

/**
 * tgui state: z_state
 *
 * Only checks that the Z-level of the user and src_object are the same.
 **/

GLOBAL_DATUM_INIT(tgui_z_state, /datum/tgui_state/z_state, new)

/datum/tgui_state/z_state/can_use_topic(src_object, mob/user)
	var/turf/turf_obj = get_turf(src_object)
	var/turf/turf_usr = get_turf(user)
	if(turf_obj && turf_usr && turf_obj.z == turf_usr.z)
		return STATUS_INTERACTIVE
	return STATUS_CLOSE
