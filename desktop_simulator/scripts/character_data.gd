class_name CharacterData
extends RefCounted

# Available 3D Models
static var MODELS: Dictionary = {
	"soldier": {
		"id": "soldier",
		"name": "🪖 Tentara Militer (Soldier)",
		"file": "res://models/Soldier.glb"
	},
	"xbot": {
		"id": "xbot",
		"name": "🤖 Robot Cyborg (Xbot)",
		"file": "res://models/Xbot.glb"
	},
	"robot_expressive": {
		"id": "robot_expressive",
		"name": "🦾 Battle Droid (Punch Mocap)",
		"file": "res://models/RobotExpressive.glb"
	},
	"jokowi": {
		"id": "jokowi",
		"name": "🇮🇩 Presiden Jokowi (Figur)",
		"file": "res://models/jokowi.glb"
	}
}

# Character Combat Classes
static var PRESETS: Dictionary = {
	"mage_fire": {
		"id": "mage_fire",
		"name": "🔥 Fire Mage (Penyihir Bola Api)",
		"weapon_type": "staff_fire",
		"element": "fire",
		"model_id": "soldier",
		"scale": 1.0,
		"max_hp": 1800.0,
		"damage": 58.0,
		"speed": 7.5,
		"attack_range": 30.0,
		"attack_speed": 1.2,
		"knockback": 4.5,
		"is_ranged": true,
		"color": Color("#ef4444")
	},
	"mage_ice": {
		"id": "mage_ice",
		"name": "❄️ Frost Mage (Penyihir Es Pembeku)",
		"weapon_type": "staff_ice",
		"element": "ice",
		"model_id": "xbot",
		"scale": 1.0,
		"max_hp": 1850.0,
		"damage": 50.0,
		"speed": 7.6,
		"attack_range": 30.0,
		"attack_speed": 1.3,
		"knockback": 3.5,
		"is_ranged": true,
		"color": Color("#06b6d4")
	},
	"mage_lightning": {
		"id": "mage_lightning",
		"name": "⚡ Lightning Mage (Penyihir Petir)",
		"weapon_type": "staff_lightning",
		"element": "lightning",
		"model_id": "robot_expressive",
		"scale": 1.0,
		"max_hp": 1750.0,
		"damage": 64.0,
		"speed": 7.8,
		"attack_range": 28.0,
		"attack_speed": 1.15,
		"knockback": 6.5,
		"is_ranged": true,
		"color": Color("#a855f7")
	},
	"mage_holy": {
		"id": "mage_holy",
		"name": "✨ Holy Priest (Penyihir Cahaya Suci)",
		"weapon_type": "staff_holy",
		"element": "holy",
		"model_id": "soldier",
		"scale": 1.0,
		"max_hp": 2100.0,
		"damage": 46.0,
		"speed": 7.3,
		"attack_range": 32.0,
		"attack_speed": 1.35,
		"knockback": 3.0,
		"is_ranged": true,
		"color": Color("#eab308")
	},
	"mage_dark": {
		"id": "mage_dark",
		"name": "🌑 Dark Mage (Penyihir Kegelapan)",
		"weapon_type": "staff_dark",
		"element": "dark",
		"model_id": "xbot",
		"scale": 1.0,
		"max_hp": 1780.0,
		"damage": 60.0,
		"speed": 7.4,
		"attack_range": 29.0,
		"attack_speed": 1.25,
		"knockback": 4.8,
		"is_ranged": true,
		"color": Color("#8b5cf6")
	},
	"archer": {
		"id": "archer",
		"name": "🏹 Urban Sniper (Pemanah Taktis Kota)",
		"weapon_type": "bow",
		"model_id": "soldier",
		"scale": 1.0,
		"max_hp": 1600.0,
		"damage": 46.0,
		"speed": 7.2,
		"attack_range": 32.0, # Long range
		"attack_speed": 1.2,
		"knockback": 3.0,
		"is_ranged": true,
		"color": Color("#10b981")
	},
	"swordsman": {
		"id": "swordsman",
		"name": "⚔️ Urban Enforcer (Pedang & Perisai Kota)",
		"weapon_type": "sword_shield",
		"model_id": "soldier",
		"scale": 1.05,
		"max_hp": 2500.0,
		"damage": 44.0,
		"speed": 8.2,
		"attack_range": 2.5,
		"attack_speed": 1.4,
		"knockback": 5.0,
		"is_ranged": false,
		"color": Color("#f59e0b")
	},
	"spearman": {
		"id": "spearman",
		"name": "🛡️ Riot Spearman (Penjaga Barikade)",
		"weapon_type": "spear",
		"model_id": "soldier",
		"scale": 1.05,
		"max_hp": 2400.0,
		"damage": 42.0,
		"speed": 7.8,
		"attack_range": 3.4,
		"attack_speed": 1.3,
		"knockback": 6.5,
		"is_ranged": false,
		"color": Color("#d97706")
	},
	"commando": {
		"id": "commando",
		"name": "🪖 Commando Gunner (Senapan Serbu)",
		"weapon_type": "rifle",
		"model_id": "soldier",
		"scale": 1.0,
		"max_hp": 1850.0,
		"damage": 36.0,
		"speed": 7.6,
		"attack_range": 26.0,
		"attack_speed": 1.6,
		"knockback": 3.5,
		"is_ranged": true,
		"color": Color("#f59e0b")
	},
	"cyborg": {
		"id": "cyborg",
		"name": "🤖 Cyborg Enforcer (Baja Sci-Fi)",
		"weapon_type": "sword_shield",
		"model_id": "xbot",
		"scale": 1.0,
		"max_hp": 2450.0,
		"damage": 42.0,
		"speed": 8.5,
		"attack_range": 2.2,
		"attack_speed": 1.5,
		"knockback": 4.8,
		"is_ranged": false,
		"color": Color("#38bdf8")
	},
	"tyson": {
		"id": "tyson",
		"name": "🥊 Mike Tyson (Heavy Brawler Knockout)",
		"weapon_type": "fists",
		"model_id": "robot_expressive",
		"scale": 1.25,
		"max_hp": 3800.0,
		"damage": 78.0,
		"speed": 8.2,
		"attack_range": 2.4,
		"attack_speed": 1.8,
		"knockback": 12.0,
		"is_ranged": false,
		"color": Color("#ef4444")
	},
	"titan": {
		"id": "titan",
		"name": "🧌 Urban Titan (Colossus Penghancur Kota)",
		"weapon_type": "fists",
		"model_id": "soldier",
		"scale": 3.5,
		"max_hp": 58000.0,
		"damage": 280.0,
		"speed": 4.5,
		"attack_range": 6.0,
		"attack_speed": 0.7,
		"knockback": 25.0,
		"is_ranged": false,
		"color": Color("#b45309")
	}
}

static func get_preset(preset_id: String) -> Dictionary:
	if PRESETS.has(preset_id):
		return PRESETS[preset_id]
	return PRESETS["archer"]

static func get_model_info(model_id: String) -> Dictionary:
	if MODELS.has(model_id):
		return MODELS[model_id]
	return MODELS["soldier"]
