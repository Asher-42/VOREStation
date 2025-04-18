//Solar tracker

//Machine that tracks the sun and reports it's direction to the solar controllers
//As long as this is working, solar panels on same powernet will track automatically

/obj/machinery/power/tracker
	name = "solar tracker"
	desc = "A solar directional tracker."
	icon = 'icons/obj/power.dmi'
	icon_state = "tracker"
	anchored = TRUE
	density = TRUE
	use_power = USE_POWER_OFF
	var/glass_type = /obj/item/stack/material/glass

	var/id = 0
	var/sun_angle = 0		// sun angle as set by sun datum
	var/obj/machinery/power/solar_control/control = null
	var/SOLAR_MAX_DIST = 40		//VOREStation Addition


/obj/machinery/power/tracker/Initialize(mapload, glass_type)
	. = ..()
	update_icon()
	connect_to_network()

/obj/machinery/power/tracker/Destroy()
	unset_control() //remove from control computer
	. = ..()

//set the control of the tracker to a given computer if closer than SOLAR_MAX_DIST
/obj/machinery/power/tracker/proc/set_control(var/obj/machinery/power/solar_control/SC)
	if(SC && (get_dist(src, SC) > SOLAR_MAX_DIST))
		return 0
	control = SC
	return 1

//set the control of the tracker to null and removes it from the previous control computer if needed
/obj/machinery/power/tracker/proc/unset_control()
	if(control)
		control.connected_tracker = null
	control = null

//updates the tracker icon and the facing angle for the control computer
/obj/machinery/power/tracker/proc/set_angle(var/angle)
	sun_angle = angle

	//set icon dir to show sun illumination
	set_dir(turn(NORTH, -angle - 22.5))	// 22.5 deg bias ensures, e.g. 67.5-112.5 is EAST

	if(powernet && (powernet == control.powernet)) //update if we're still in the same powernet
		control.cdir = angle

/obj/machinery/power/tracker/attackby(var/obj/item/W, var/mob/user)

	if(W.has_tool_quality(TOOL_CROWBAR))
		playsound(src, 'sound/machines/click.ogg', 50, 1)
		user.visible_message(span_notice("[user] begins to take the glass off the solar tracker."))
		if(do_after(user, 50))
			var/obj/item/solar_assembly/S = new(loc)
			S.tracker = TRUE
			S.anchored = TRUE
			new glass_type(loc, 2)
			playsound(src, 'sound/items/Deconstruct.ogg', 50, 1)
			user.visible_message(span_notice("[user] takes the glass off the tracker."))
			qdel(src)
		return
	..()

// Tracker Electronic

/obj/item/tracker_electronics

	name = "tracker electronics"
	icon = 'icons/obj/doors/door_assembly.dmi'
	icon_state = "door_electronics"
	w_class = ITEMSIZE_SMALL
