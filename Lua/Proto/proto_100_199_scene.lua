return [[

.scene_main_role_info {
	scene_uid 0 : integer
	role_id 1 : integer
	career 2 : integer
	name 3 : string
	scene_id 4 : integer
	pos_x 5 : integer
	pos_y 6 : integer
	pos_z 7 : integer
}
.info_item {
	key 0 : integer
	value 1 : string
	time 2 : integer
}
.scene_obj_info {
	scene_obj_uid 0 : integer
	info_list 1 : *info_item
}
.scene_role_info {
	role_id 0 : integer
	career 1 : integer
	name 2 : string
}
.scene_monster_info {
	monster_id 0 : integer
	monster_type_id 1 : integer
	hp 2 : integer
	maxhp 3 : integer
}
.scene_npc_info {
	npc_id 0 : integer
	npc_type_id 1 : integer
}

scene_get_main_role_info 100 {
	response {
		role_info 0 : scene_main_role_info
	}
}

scene_get_cur_scene_info 101 {
	response {
		role_list 0 : *scene_role_info
		monster_list 1 : *scene_monster_info
		npc_list 2 : *scene_npc_info
	}
}

scene_walk 102 {
	request {
		pos_x 0 : integer
		pos_y 1 : integer
		pos_z 2 : integer
		time  3 : integer
	}
	response {
	}
}

scene_get_objs_info_change 103 {
	request {
	}
	response {
		obj_infos 0 : *scene_obj_info
	}
}

scene_enter_scene 104 {
	request {
		scene_id 0 : integer
	}
	response {
		result 0 : integer
		role_info 1 : scene_main_role_info
	}
}

]]

