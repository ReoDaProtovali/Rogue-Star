// Phase shifting procs (and related procs)
/mob/living/simple_animal/shadekin/proc/phase_shift()
	var/turf/T = get_turf(src)
	if(!T.CanPass(null,T) || loc != T)
		to_chat(src,"<span class='warning'>You can't use that here!</span>")
		return FALSE

	forceMove(T)
	var/original_canmove = canmove
	SetStunned(0)
	SetWeakened(0)
	if(buckled)
		buckled.unbuckle_mob()
	if(pulledby)
		pulledby.stop_pulling()
	stop_pulling()
	canmove = FALSE

	//Shifting in
	if(ability_flags & AB_PHASE_SHIFTED)
		ability_flags &= ~AB_PHASE_SHIFTED
		name = real_name
		for(var/belly in vore_organs)
			var/datum/belly/B = vore_organs[belly]
			B.escapable = initial(B.escapable)

		overlays.Cut()
		alpha = initial(alpha)
		invisibility = initial(invisibility)
		see_invisible = initial(see_invisible)
		incorporeal_move = initial(incorporeal_move)
		density = initial(density)
		force_max_speed = initial(force_max_speed)

		//Cosmetics mostly
		flick("tp_in",src)
		custom_emote(1,"phases in!")
		sleep(5) //The duration of the TP animation
		update_icon()
		canmove = original_canmove

		//Affect nearby lights
		var/destroy_lights = 0
		if(eye_state == RED_EYES)
			destroy_lights = 80
		if(eye_state == PURPLE_EYES)
			destroy_lights = 25

		for(var/obj/machinery/light/L in machines)
			if(L.z != z || get_dist(src,L) > 10)
				continue

			if(prob(destroy_lights))
				spawn(rand(5,25))
					L.broken()
			else
				L.flicker(10)

	//Shifting out
	else
		ability_flags |= AB_PHASE_SHIFTED
		custom_emote(1,"phases out!")
		real_name = name
		name = "Something"

		for(var/belly in vore_organs)
			var/datum/belly/B = vore_organs[belly]
			B.escapable = FALSE

		overlays.Cut()
		flick("tp_out",src)
		sleep(5)
		invisibility = INVISIBILITY_LEVEL_TWO
		see_invisible = INVISIBILITY_LEVEL_TWO
		update_icon()
		alpha = 127

		canmove = original_canmove
		incorporeal_move = TRUE
		density = FALSE
		force_max_speed = TRUE

/mob/living/simple_animal/shadekin/UnarmedAttack()
	if(ability_flags & AB_PHASE_SHIFTED)
		return FALSE //Nope.

	. = ..()

/mob/living/simple_animal/shadekin/can_fall()
	if(ability_flags & AB_PHASE_SHIFTED)
		return FALSE //Nope!

	return ..()

/mob/living/simple_animal/shadekin/zMove(direction)
	if(ability_flags & AB_PHASE_SHIFTED)
		var/turf/destination = (direction == UP) ? GetAbove(src) : GetBelow(src)
		if(destination)
			forceMove(destination)
		return TRUE

	return ..()

// Healing others
/mob/living/simple_animal/shadekin/proc/mend_other()
	//I hate to crunch a view() but I only want ones I can see
	var/list/viewed = oview(1)
	var/list/targets = list()
	for(var/mob/living/L in viewed)
		targets += L
	if(!targets.len)
		to_chat(src,"<span class='warning'>Nobody nearby to mend!</span>")
		return FALSE

	var/mob/living/target = input(src,"Pick someone to mend:","Mend Other") as null|anything in targets
	if(!target)
		return FALSE

	target.add_modifier(/datum/modifier/shadekin/heal_boop,1 MINUTE)
	visible_message("<span class='notice'>\The [src] gently places a hand on \the [target]...</span>")
	face_atom(target)
	return TRUE
