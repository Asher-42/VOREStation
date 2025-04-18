#define NOGRAV_FIGHTER_DAMAGE 20

/obj/mecha/combat/fighter
	name = "Delete me, nerd!!"
	desc = "The base type of fightercraft. Don't spawn this one!"

	var/datum/effect/effect/system/ion_trail_follow/ion_trail
	var/landing_gear_raised = FALSE //If our landing gear for safely crossing ground turfs is on.
	var/ground_capable = FALSE //If we can fly over normal turfs and not just space

	icon = 'icons/mecha/fighters64x64.dmi' //See ATTRIBUTIONS.md for details on license

	icon_state = ""
	initial_icon = ""

	dir_in = null //Don't reset direction when empty

	step_in = 2 //Fast
	step_energy_drain = 0 //These should use fuel instead of energy

	health = 400
	maxhealth = 400

	infra_luminosity = 6

	opacity = FALSE

	wreckage = /obj/effect/decal/mecha_wreckage/gunpod

	stomp_sound = 'sound/mecha/fighter/engine_mid_fighter_move.ogg'
	swivel_sound = 'sound/mecha/fighter/engine_mid_boost_01.ogg'

	bound_height = 64
	bound_width = 64

	max_hull_equip = 2
	max_weapon_equip = 2
	max_utility_equip = 1
	max_universal_equip = 1
	max_special_equip = 1

	zoom_possible = 1

	starting_components = list(
		/obj/item/mecha_parts/component/hull/fighter,
		/obj/item/mecha_parts/component/actuator,
		/obj/item/mecha_parts/component/armor/fighter,
		/obj/item/mecha_parts/component/gas,
		/obj/item/mecha_parts/component/electrical
		)

/obj/mecha/combat/fighter/Initialize(mapload)
	. = ..()
	ion_trail = new /datum/effect/effect/system/ion_trail_follow()
	ion_trail.set_up(src)
	ion_trail.stop()

/obj/mecha/combat/fighter/moved_inside(var/mob/living/carbon/human/H)
	. = ..()
	consider_gravity()

/obj/mecha/combat/fighter/go_out()
	. = ..()
	consider_gravity()

//We don't get lost quite as easy.
/obj/mecha/combat/fighter/touch_map_edge()
	//No overmap enabled or no driver to choose
	if(!using_map.use_overmap || !occupant || !can_ztravel())
		return ..()

	var/obj/effect/overmap/visitable/our_ship = get_overmap_sector(z)

	//We're not on the overmap
	if(!our_ship)
		return ..()

	//Stored for safety checking after user input
	var/this_x = x
	var/this_y = y
	var/this_z = z
	var/this_occupant = occupant

	var/what_edge

	var/new_x
	var/new_y
	var/new_z

	if(x <= TRANSITIONEDGE)
		what_edge = WEST
		new_x = world.maxx - TRANSITIONEDGE - 2
		new_y = rand(TRANSITIONEDGE + 2, world.maxy - TRANSITIONEDGE - 2)

	else if (x >= (world.maxx - TRANSITIONEDGE + 1))
		what_edge = EAST
		new_x = TRANSITIONEDGE + 1
		new_y = rand(TRANSITIONEDGE + 2, world.maxy - TRANSITIONEDGE - 2)

	else if (y <= TRANSITIONEDGE)
		what_edge = SOUTH
		new_y = world.maxy - TRANSITIONEDGE -2
		new_x = rand(TRANSITIONEDGE + 2, world.maxx - TRANSITIONEDGE - 2)

	else if (y >= (world.maxy - TRANSITIONEDGE + 1))
		what_edge = NORTH
		new_y = TRANSITIONEDGE + 1
		new_x = rand(TRANSITIONEDGE + 2, world.maxx - TRANSITIONEDGE - 2)

	var/list/choices = list()
	for(var/obj/effect/overmap/visitable/V in range(1, our_ship))
		choices[V.name] = V

	var/choice = tgui_input_list(usr, "Choose an overmap destination:", "Destination", choices)
	if(!choice)
		var/backwards = turn(what_edge, 180)
		forceMove(get_step(src,backwards)) //Move them back a step, then.
		set_dir(backwards)
		return
	else
		var/obj/effect/overmap/visitable/V = choices[choice]
		if(occupant != this_occupant || this_x != x || this_y != y || this_z != z || get_dist(V,our_ship) > 1) //Sanity after user input
			to_chat(occupant, span_warning("You or they appear to have moved!"))
			return
		var/list/levels = V.get_space_zlevels()
		if(!levels.len)
			to_chat(occupant, span_warning("You don't appear to be able to get there from here!"))
			return
		new_z = pick(levels)
	var/turf/destination = locate(new_x, new_y, new_z)
	if(!destination || destination.density)
		to_chat(occupant, span_warning("You don't appear to be able to get there from here! Is it blocked?"))
		return
	else
		forceMove(destination)

//Modified phazon code
/obj/mecha/combat/fighter/Topic(href, href_list)
	..()
	if (href_list["toggle_landing_gear"])
		landing_gear_raised = !landing_gear_raised
		send_byjax(src.occupant,"exosuit.browser","landing_gear_command","[landing_gear_raised?"Raise":"Lower"] landing gear")
		src.occupant_message(span_notice("Landing gear [landing_gear_raised? "raised" : "lowered"]."))
		return

/obj/mecha/combat/fighter/get_commands()
	var/output = {"<div class='wr'>
						<div class='header'>Special</div>
						<div class='links'>
						<a href='byond://?src=\ref[src];toggle_landing_gear=1'><span id="landing_gear_command">[landing_gear_raised?"Raise":"Lower"] landing gear</span></a><br>
						</div>
						</div>
						"}
	output += ..()
	return output

/obj/mecha/combat/fighter/can_ztravel()
	return (landing_gear_raised && has_charge(step_energy_drain))

// No space drifting
// This doesnt work but I actually dont want it to anyways, so I'm not touching it at all. Space drifting is cool.
/obj/mecha/combat/fighter/check_for_support()
	if (landing_gear_raised)
		return 1

	return ..()

// No falling if we've got our boosters on
/obj/mecha/combat/fighter/can_fall()
	if(landing_gear_raised && has_charge(step_energy_drain))
		return FALSE
	else
		return TRUE

/obj/mecha/combat/fighter/proc/consider_gravity(var/moved = FALSE)
	var/gravity = get_gravity()
	if (gravity && !landing_gear_raised)
		playsound(src, 'sound/effects/roll.ogg', 50, 1)
	else if(gravity && ground_capable && occupant)
		start_hover()
	else if((!gravity && ground_capable) || !occupant)
		stop_hover()
	else if(moved && gravity && !ground_capable)
		occupant_message("Collision alert! Vehicle not rated for use in gravity!")
		take_damage(NOGRAV_FIGHTER_DAMAGE, "brute")
		playsound(src, 'sound/effects/grillehit.ogg', 50, 1)

/obj/mecha/combat/fighter/get_step_delay()
	. = ..()
	if(get_gravity() && !landing_gear_raised)
		. += 4

/obj/mecha/combat/fighter/handle_equipment_movement()
	. = ..()
	consider_gravity(TRUE)

/obj/mecha/combat/fighter/proc/start_hover()
	if(!ion_trail.on) //We'll just use this to store if we're floating or not
		ion_trail.start()
		var/amplitude = 2 //maximum displacement from original position
		var/period = 36 //time taken for the mob to go up >> down >> original position, in deciseconds. Should be multiple of 4

		var/top = old_y + amplitude
		var/bottom = old_y - amplitude
		var/half_period = period / 2
		var/quarter_period = period / 4

		animate(src, pixel_y = top, time = quarter_period, easing = SINE_EASING | EASE_OUT, loop = -1)		//up
		animate(pixel_y = bottom, time = half_period, easing = SINE_EASING, loop = -1)						//down
		animate(pixel_y = old_y, time = quarter_period, easing = SINE_EASING | EASE_IN, loop = -1)			//back

/obj/mecha/combat/fighter/proc/stop_hover()
	if(ion_trail.on)
		ion_trail.stop()
		animate(src, pixel_y = old_y, time = 5, easing = SINE_EASING | EASE_IN) //halt animation

/obj/mecha/combat/fighter/check_for_support()
	if (has_charge(step_energy_drain) && landing_gear_raised)
		return 1

	var/list/things = orange(1, src)

	if(locate(/obj/structure/grille) in things || locate(/obj/structure/lattice) in things || locate(/turf/simulated) in things || locate(/turf/unsimulated) in things)
		return 1
	else
		return 0


/obj/mecha/combat/fighter/play_entered_noise(var/mob/who)
	if(hasInternalDamage())
		who << sound('sound/mecha/fighter/fighter_entered_bad.ogg',volume=60)
	else
		who << sound('sound/mecha/fighter/fighter_entered.ogg',volume=60)


//causes damage when running into objects
/obj/mecha/combat/fighter/Bump(atom/obstacle)
	. = ..()
	if(istype(obstacle, /obj) || istype(obstacle, /turf))
		occupant_message(span_bolddanger(span_large("COLLISION ALERT!")))
		take_damage(20, "brute")
		playsound(src, 'sound/mecha/fighter/fighter_collision.ogg', 50)

////////////// Gunpod //////////////

/obj/mecha/combat/fighter/gunpod
	name = "Gunpod"
	desc = "Small mounted weapons platform capable of space and surface combat. More like a flying tank than a dedicated fightercraft."
	icon = 'icons/mecha/fighters64x64.dmi'
	icon_state = "gunpod"
	initial_icon = "gunpod"

	catalogue_data = list(/datum/category_item/catalogue/technology/gunpod)
	wreckage = /obj/effect/decal/mecha_wreckage/gunpod

	step_in = 3 //Slightly slower than others

	ground_capable = TRUE

	// Paint colors! Null if not set.
	var/stripe1_color
	var/stripe2_color
	var/image/stripe1_overlay
	var/image/stripe2_overlay

/obj/mecha/combat/fighter/gunpod/loaded/Initialize(mapload) //Loaded version with guns
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/weapon/energy/laser
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/explosive
	ME.attach(src)

/obj/mecha/combat/fighter/gunpod/recon/Initialize(mapload) //Blinky
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/teleporter(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/tesla_energy_relay(src)
	ME.attach(src)

/obj/mecha/combat/fighter/gunpod/update_icon()
	cut_overlays()
	..()

	if(stripe1_color)
		stripe1_overlay = image("gunpod_stripes1")
		stripe1_overlay.color = stripe1_color
		add_overlay(stripe1_overlay)
	if(stripe2_color)
		stripe2_overlay = image("gunpod_stripes2")
		stripe2_overlay.color = stripe2_color
		add_overlay(stripe2_overlay)

/obj/mecha/combat/fighter/gunpod/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W,/obj/item/multitool) && state == 1)
		var/new_paint_location = tgui_input_list(user, "Please select a target zone.", "Paint Zone", list("Fore Stripe", "Aft Stripe", "CANCEL"))
		if(new_paint_location && new_paint_location != "CANCEL")
			var/new_paint_color = tgui_color_picker(user, "Please select a paint color.", "Paint Color", null)
			if(new_paint_color)
				switch(new_paint_location)
					if("Fore Stripe")
						stripe1_color = new_paint_color
					if("Aft Stripe")
						stripe2_color = new_paint_color

		update_icon()
	else ..()

/obj/effect/decal/mecha_wreckage/gunpod
	name = "Gunpod wreckage"
	desc = "Remains of some unfortunate gunpod. Completely unrepairable."
	icon = 'icons/mecha/fighters64x64.dmi'
	icon_state = "gunpod-broken"
	bound_width = 64
	bound_height = 64

/datum/category_item/catalogue/technology/gunpod
	name = "Voidcraft - Gunpod"
	desc = "This is a small space-capable fightercraft that has an arrowhead design. Can hold up to one pilot, \
	and sometimes one or two passengers, with the right modifications made. \
	Typically used as small fighter craft, the gunpod can't carry much of a payload, though it's still capable of holding it's own."
	value = CATALOGUER_REWARD_MEDIUM


////////////// Baron //////////////

/obj/mecha/combat/fighter/baron
	name = "Baron"
	desc = "A conventional space superiority fighter, one-seater. Not capable of ground operations."
	icon = 'icons/mecha/fighters64x64.dmi'
	icon_state = "baron"
	initial_icon = "baron"

	catalogue_data = list(/datum/category_item/catalogue/technology/baron)
	wreckage = /obj/effect/decal/mecha_wreckage/baron

	ground_capable = FALSE

/obj/mecha/combat/fighter/baron/loaded/Initialize(mapload) //Loaded version with guns
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/weapon/energy/laser
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/omni_shield
	ME.attach(src)

/obj/effect/decal/mecha_wreckage/baron
	name = "Baron wreckage"
	desc = "Remains of some unfortunate fighter. Completely unrepairable."
	icon = 'icons/mecha/fighters64x64.dmi'
	icon_state = "baron-broken"
	bound_width = 64
	bound_height = 64

/datum/category_item/catalogue/technology/baron
	name = "Voidcraft - Baron"
	desc = "This is a small space fightercraft that has an arrowhead design. Can hold up to one pilot. \
	Unlike some fighters, this one is not designed for atmospheric operation, and is only capable of performing \
	maneuvers in the vacuum of space. Attempting to operate it in an atmosphere is not recommended."
	value = CATALOGUER_REWARD_MEDIUM


////////////// Scoralis //////////////

/obj/mecha/combat/fighter/scoralis
	name = "scoralis"
	desc = "An imported space fighter with an integral cloaking device. Beware the power consumption, though. Incapable of ground operations."
	icon = 'icons/mecha/fighters64x64.dmi'
	icon_state = "scoralis"
	initial_icon = "scoralis"

	catalogue_data = list(/datum/category_item/catalogue/technology/scoralis)
	wreckage = /obj/effect/decal/mecha_wreckage/scoralis

	ground_capable = FALSE

/obj/mecha/combat/fighter/scoralis/loaded/Initialize(mapload) //Loaded version with guns
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/cloak
	ME.attach(src)

/obj/effect/decal/mecha_wreckage/scoralis
	name = "scoralis wreckage"
	desc = "Remains of some unfortunate fighter. Completely unrepairable."
	icon = 'icons/mecha/fighters64x64.dmi'
	icon_state = "scoralis-broken"
	bound_width = 64
	bound_height = 64

/datum/category_item/catalogue/technology/scoralis
	name = "Voidcraft - Scoralis"
	desc = "An import model fightercraft, this one contains an integral cloaking device that renders the fighter invisible \
	to the naked eye. Still detectable on thermal sensors, the craft can maneuver in close to ill-equipped foes and strike unseen. \
	Not rated for atmospheric travel, this craft excels at hit and run tactics, as it will likely need to recharge batteries between each 'hit'."
	value = CATALOGUER_REWARD_MEDIUM

////////////// Allure //////////////

/obj/mecha/combat/fighter/allure
	name = "allure"
	desc = "A fighter of Zorren design, it's blocky appearance is made up for by it's stout armor and finely decorated hull paint."
	icon = 'icons/mecha/fighters64x64.dmi'
	icon_state = "allure"
	initial_icon = "allure"

	catalogue_data = list(/datum/category_item/catalogue/technology/allure)
	wreckage = /obj/effect/decal/mecha_wreckage/allure

	ground_capable = FALSE

	health = 500
	maxhealth = 500

/obj/mecha/combat/fighter/allure/loaded/Initialize(mapload) //Loaded version with guns
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/cloak
	ME.attach(src)

/obj/effect/decal/mecha_wreckage/allure
	name = "allure wreckage"
	desc = "Remains of some unfortunate fighter. Completely unrepairable."
	icon = 'icons/mecha/fighters64x64.dmi'
	icon_state = "allure-broken"
	bound_width = 64
	bound_height = 64

/datum/category_item/catalogue/technology/allure
	name = "Voidcraft - Allure"
	desc = "A space superiority fighter of zorren design, many would comment that the blocky shape hinders aesthetic appeal. However, Zorren are \
	often found painting their hulls in intricate designs of purple and gold, and this craft is no exception to the rule. Some individual seems to have \
	decorated it finely. Import craft like this one often ship with no weapons, though the Zorren saw fit to integrate a cloaking device."
	value = CATALOGUER_REWARD_MEDIUM

////////////// Pinnace //////////////

/obj/mecha/combat/fighter/pinnace
	name = "pinnace"
	desc = "A mass-produced, lightweight fighter craft, capable of atmospheric and interstellar operation. While cheap and simple to operate, it suffers from sub-par survivability."
	icon = 'icons/mecha/fighters64x64.dmi'
	icon_state = "pinnace"
	initial_icon = "pinnace"

	catalogue_data = list(/datum/category_item/catalogue/technology/pinnace)
	wreckage = /obj/effect/decal/mecha_wreckage/pinnace

	ground_capable = TRUE

	health = 200
	maxhealth = 200

/obj/mecha/combat/fighter/pinnace/loaded/Initialize(mapload) //Loaded version with guns
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/weapon/energy/laser
	ME.attach(src)

/obj/effect/decal/mecha_wreckage/pinnace
	name = "pinnace wreckage"
	desc = "Remains of some unfortunate fighter. Completely unrepairable."
	icon = 'icons/mecha/fighters64x64.dmi'
	icon_state = "pinnace-broken"
	bound_width = 64
	bound_height = 64

/datum/category_item/catalogue/technology/pinnace
	name = "Voidcraft - Pinnace"
	desc = "A small, unassuming forward-swept-wing fighter craft, first produced some seventy years ago by Hesphaestus Industries for \
	the Commonwealth. Since then, the design has seen widespread adoption by many different corporate, federal and independent \
	groups alike; this can easily be attributed due to its ease of manufacturing, reliability and simplicity to both maintain and \
	operate. Outdated in comparison to more modern aerospace craft, it still sees heavy usage in the frontier regions where \
	cutting-edge technology is less of a concern."
	value = CATALOGUER_REWARD_MEDIUM

#undef NOGRAV_FIGHTER_DAMAGE
