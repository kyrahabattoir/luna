/obj/item/proc/process()
	processing_items.Remove(src)
	return null

/obj/item/proc/attack_self()
	return

/obj/item/proc/talk_into(mob/M as mob, text)
	return

/obj/item/proc/security_talk_into(mob/M as mob, text)

/obj/item/proc/moved(mob/user as mob, old_loc as turf)
	return

/obj/item/proc/dropped(mob/user as mob)
	return

// Called just as an item is picked up (loc is not yet changed)
/obj/item/proc/pickup(mob/user)
	return

/* Called after an item is placed in an equipment slot.
   user is mob that equipped it, slot is text of slot type e.g. "head".
   For items that can be placed in multiple slots
   Note this isn't called during the initial dressing of a player */
/obj/item/proc/equipped(var/mob/user, var/slot)
	return
//
// ***TODO: implement unequipped()
//

/obj/item/proc/on_found(mob/finder as mob)
	return

/obj/item/proc/afterattack()
	return

/obj/item/weapon/dummy/ex_act()
	return

/obj/item/weapon/dummy/blob_act()
	return

/obj/item/ex_act(severity)
	switch(severity)
		if(1.0)
			del(src)
			return
		if(2.0)
			if (prob(50))
				del(src)
				return
		if(3.0)
			if (prob(5))
				del(src)
				return
		else
	return

/obj/item/blob_act()
	return

/obj/item/verb/move_to_top()
	set src in oview(1)

	if(!istype(src.loc, /turf) || usr.stat || usr.restrained() )
		return

	var/turf/T = src.loc

	src.loc = null

	src.loc = T

/obj/item/examine()
	set src in view()

	var/t
	switch(src.w_class)
		if(1.0)
			t = "tiny"
		if(2.0)
			t = "small"
		if(3.0)
			t = "normal-sized"
		if(4.0)
			t = "bulky"
		if(5.0)
			t = "huge"
		else
	if ((CLUMSY in usr.mutations) && prob(30)) t = "funny-looking"
	usr << text("This is a []\icon[][]. It is a [] item.", !src.blood_DNA.len ? "" : "bloody ",src, src.name, t)
	usr << src.desc
	return

/obj/item/attack_hand(mob/user as mob)
	if (istype(src.loc, /obj/item/weapon/storage))
		for(var/mob/M in range(1, src.loc))
			if (M.s_active == src.loc)
				if (M.client)
					M.client.screen -= src

	src.throwing = 0

	if (src.loc == user)
		if(istype(src, /obj/item/clothing) && !src:canremove)
			return
		else
			user.u_equip(src)
	else
		if(ishuman(user) && !user:zombie)
			src.pickup(user)

	if (user.hand)
		if(ishuman(user))
			var/datum/organ/external/temp = user:organs["l_hand"]
			if(temp.status)
				user.l_hand = src
			else
				user << "\blue You pick \the [src] up with your ha- wait a minute."
				return
		else
			user.l_hand = src
	else
		if(ishuman(user))
			var/datum/organ/external/temp = user:organs["r_hand"]
			if(temp.status)
				user.r_hand = src
			else
				user << "\blue You pick \the [src] up with your ha- wait a minute."
				return
		else
			user.r_hand = src

	src.loc = user
	src.layer = 20
	add_fingerprint(user)
	user.update_clothing()
	return

/obj/item/attack_paw(mob/user as mob)
	if (istype(src.loc, /obj/item/weapon/storage))
		for(var/mob/M in range(1, src.loc))
			if (M.s_active == src.loc)
				if (M.client)
					M.client.screen -= src
	src.throwing = 0
	if (src.loc == user)
		user.u_equip(src)
	if (user.hand)
		user.l_hand = src
	else
		user.r_hand = src
	src.loc = user
	src.layer = 20
	user.update_clothing()
	return


/obj/item/verb/verb_pickup()
	set src in oview(1)
	set category = "Object"
	set name = "Pick up"

	if(!usr.canmove || usr.stat || usr.restrained() || !in_range(src, usr))
		return

	if(ishuman(usr))
		if(usr.get_active_hand() == null)
			src.Click()
	else
		usr << "\red This mob type can't use this verb."


/obj/item/var/superblunt = 0
/obj/item/var/slash = 0

/obj/item/proc/attack(mob/living/M as mob, mob/living/user as mob, def_zone)
	if (!M) // not sure if this is the right thing...
		return

	if(iscarbon(M) && (M.lying || isslime(M)))
		var/mob/living/carbon/mob = M
		//world << "mob is acceptable for surgery"
		if(mob.surgeries.len)
			//world << "mob has surgery"
			if(user.a_intent == "help")
				//world << "user is helpful"
				for(var/datum/surgery/S in mob.surgeries)
					//world << "checking [S]"
					if(S.next_step(user, mob))
						return 1


	if (src.hitsound)
		playsound(src.loc, hitsound, 50, 1, -1)
	/////////////////////////
	user.lastattacked = M
	M.lastattacker = user
	/////////////////////////

	if(M.client)
		log_attack("[M.name] attacked by [user.name]([user.key]) with [src]")
	user.log_m("Attacked [M.name]([M.real_name]) with [src]")
	M.log_m("Attacked by [user.name]([user.real_name])([user.key]) with [src]")
	var/mob/user3 = user
	if(TK in user.mutations)
		user3 = null
	if(!istype(M, /mob/living/carbon/human))
		for(var/mob/O in viewers(M, null))
			O.show_message(text("\red <B>[] has been attacked with [][] </B>", M, src, (user3 ? text(" by [].", user3) : ".")), 1)
	var/power = src.force
	if (istype(M, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = M
		if(H.zombie) power = 0
		if (istype(user, /mob/living/carbon/human) || istype(user, /mob/living/silicon/robot))
			if (!( def_zone ))
				var/mob/user2 = user
				var/t = user2:zone_sel.selecting
				if ((t in list( "eyes", "mouth" )))
					t = "head"
				def_zone = ran_zone(t)
		var/datum/organ/external/affecting
		if (H.organs[text("[]", def_zone)])
			affecting = H.organs[text("[]", def_zone)]
		if(affecting)
			if(!affecting.status)
				for(var/mob/O in viewers(M, null))
					O.show_message(text("\red <B>[user3] has missed [M] with [src] </B>"),1)
				return
			var/hit_area = parse_zone(def_zone)
			for(var/mob/O in viewers(M, null))
				O.show_message(text("\red <B>[] has been attacked in the [] with [][] </B>", M, hit_area, src, (user3 ? text(" by [].", user3) : ".")), 1)
			if (istype(affecting, /datum/organ/external))
				var/b_dam = (src.damtype == "brute" ? src.force : 0)
				var/f_dam = (src.damtype == "fire" ? src.force : 0)
				if (COLD_RESISTANCE in M.mutations)
					f_dam = 0
				if (def_zone == "head")
					if (b_dam && (istype(H.head, /obj/item/clothing/head/helmet/) && H.head.body_parts_covered & HEAD) && prob(80 - src.force))
						if (prob(20))
							affecting.take_damage(power, 0,slash,superblunt)
						else
							H.show_message("\red You have been protected from a hit to the head.")
						return
					if ((b_dam && prob(src.force + affecting.brute_dam + affecting.burn_dam) && !H.zombie))
						var/time = rand(10, 120)
						if (prob(90))
							if (H.paralysis < time)
								H.paralysis = time
						else
							if (H.weakened < time)
								H.weakened = time
						if(H.stat != 2)	H.stat = 1
						if(H.stat != 2)
							for(var/mob/O in viewers(M, null))
								O.show_message(text("\red <B>[] has been knocked unconscious!</B>", H), 1, "\red You hear someone fall.", 2)
							if (prob(50))
								if (ticker.mode.name == "revolution")
									ticker.mode:remove_revolutionary(H.mind)
					if (b_dam && prob(25 + (b_dam * 2)) && !(TK in user.mutations))
						src.add_blood(H)
						if (prob(65))
							var/turf/location = H.loc
							if (istype(location, /turf/simulated))
								location.add_blood(H)
						if (H.wear_mask)
							H.wear_mask.add_blood(H)
						if (H.head)
							H.head.add_blood(H)
						if (H.glasses && prob(33))
							H.glasses.add_blood(H)
						if (istype(user, /mob/living/carbon/human))
							var/mob/living/carbon/human/user2 = user
							if (user2.gloves)
								user2.gloves.add_blood(H)
								user2.gloves.transfer_blood = 2
								user2.gloves.bloody_hands_mob = H
							else
								user2.add_blood(H)
								user2.bloody_hands = 2
								user2.bloody_hands_mob = H
							if (prob(15))
								if (user2.wear_suit)
									user2.wear_suit.add_blood(H)
								else if (user2.w_uniform)
									user2.w_uniform.add_blood(H)
					affecting.take_damage(b_dam, f_dam,slash,superblunt)
				else if (def_zone == "chest")
					if (b_dam && ((istype(H.wear_suit, /obj/item/clothing/suit/armor/)) && H.wear_suit.body_parts_covered & CHEST) && prob(90 - src.force))
						H.show_message("\red You have been protected from a hit to the chest.")
						return
					if ((b_dam && prob(src.force + affecting.brute_dam + affecting.burn_dam) && !H.zombie))
						if (prob(50))
							if (H.weakened < 5)
								H.weakened = 5
							for(var/mob/O in viewers(H, null))
								O.show_message(text("\red <B>[] has been knocked down!</B>", H), 1, "\red You hear someone fall.", 2)
						else
							if (H.stunned < 2)
								H.stunned = 2
							for(var/mob/O in viewers(H, null))
								O.show_message(text("\red <B>[] has been stunned!</B>", H), 1)
						if(H.stat != 2)	H.stat = 1
					if (b_dam && prob(25 + (b_dam * 2)) && !(TK in user.mutations))
						src.add_blood(H)
						if (prob(65))
							var/turf/location = H.loc
							if (istype(location, /turf/simulated))
								location.add_blood(H)
						if (H.wear_suit)
							H.wear_suit.add_blood(H)
						if (H.w_uniform)
							H.w_uniform.add_blood(H)
						if (istype(user, /mob/living/carbon/human))
							var/mob/living/carbon/human/user2 = user
							if (user2.gloves)
								user2.gloves.add_blood(H)
								user2.gloves.transfer_blood = 2
								user2.gloves.bloody_hands_mob = H
							else
								user2.add_blood(H)
								user2.bloody_hands = 2
								user2.bloody_hands_mob = H
							if (prob(15))
								if (user2.wear_suit)
									user2.wear_suit.add_blood(H)
								else if (user2.w_uniform)
									user2.w_uniform.add_blood(H)
					affecting.take_damage(b_dam, f_dam,slash,superblunt)
				else if (def_zone == "groin")
					if (b_dam && (istype(H.wear_suit, /obj/item/clothing/suit/armor/) && H.wear_suit.body_parts_covered & GROIN) && prob(90 - src.force))
						H.show_message("\red You have been protected from a hit to the groin (phew).")
						return
					if ((b_dam && prob(src.force + affecting.brute_dam + affecting.burn_dam) && H.zombie ))
						if (prob(50))
							if (H.weakened < 5)
								H.weakened = 5
							for(var/mob/O in viewers(H, null))
								O.show_message(text("\red <B>[] has been knocked down!</B>", H), 1, "\red You hear someone fall.", 2)
						else
							if (H.stunned < 2)
								H.stunned = 2
							for(var/mob/O in viewers(H, null))
								O.show_message(text("\red <B>[] has been stunned!</B>", H), 1)
							if(H.stat != 2)	H.stat = 1
						if (b_dam && prob(25 + (b_dam * 2)) && !(TK in user.mutations))
							src.add_blood(H)
							if (prob(65))
								var/turf/location = H.loc
								if (istype(location, /turf/simulated))
									location.add_blood(H)
							if (H.wear_suit)
								H.wear_suit.add_blood(H)
							if (H.w_uniform)
								H.w_uniform.add_blood(H)
							if (istype(user, /mob/living/carbon/human))
								var/mob/living/carbon/human/user2 = user
								if (user2.gloves)
									user2.gloves.add_blood(H)
									user2.gloves.transfer_blood = 2
									user2.gloves.bloody_hands_mob = H
								else
									user2.add_blood(H)
									user2.bloody_hands = 2
									user2.bloody_hands_mob = H
								if (prob(15))
									if (user2.wear_suit)
										user2.wear_suit.add_blood(H)
									else if (user2.w_uniform)
										user2.w_uniform.add_blood(H)
						affecting.take_damage(b_dam, f_dam,slash,superblunt)
				else
					if (b_dam && prob(25 + (b_dam * 2)) && !(TK in user.mutations))
						src.add_blood(H)
						if (prob(65))
							var/turf/location = H.loc
							if (istype(location, /turf/simulated))
								location.add_blood(H)
						if (H.wear_suit)
							H.wear_suit.add_blood(H)
						if (H.w_uniform)
							H.w_uniform.add_blood(H)
						if (istype(user, /mob/living/carbon/human))
							var/mob/living/carbon/human/user2 = user
							if (user2.gloves)
								user2.gloves.add_blood(H)
								user2.gloves.transfer_blood = 2
								user2.gloves.bloody_hands_mob = H
							else
								user2.add_blood(H)
								user2.bloody_hands = 2
								user2.bloody_hands_mob = H
							if (prob(15))
								if (user2.wear_suit)
									user2.wear_suit.add_blood(H)
								else if (user2.w_uniform)
									user2.w_uniform.add_blood(H)
					affecting.take_damage(b_dam, f_dam,slash,superblunt)

			if(H)
				H.UpdateDamageIcon()
				H.update_clothing()
			user.update_clothing()
	else
		switch(src.damtype)
			if("brute")
				M.bruteloss += power
			if("fire")
				if (!(COLD_RESISTANCE in M.mutations))
					M.fireloss += power
			//		M << "heres ur burn notice"
		M.updatehealth()
	src.add_fingerprint(user)
	return



