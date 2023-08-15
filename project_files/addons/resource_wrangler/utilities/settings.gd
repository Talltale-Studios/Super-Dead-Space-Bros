@tool
extends Node

# MIT License
#
# Copyright (c) 2023 Donn Ingle (donn.ingle@gmail.com)
# Copyright (c) 2022 Nathan Hoad
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

const database = preload("res://addons/resource_wrangler/utilities/database.gd")

const ADDON_KEY = "resource_wrangler"
const AUTOMADE_KEY = "automade_path"
const DATABASE_KEY = "database_path_and_filename"
const DEFAULT_AUTOMADE_PATH := "res://automade_resources"
const DEFAULT_DATABASE_PATH_AND_FILENAME := "res://resource_wrangler_database.tres"

static var automade_path:
	get:
		var ret : String = get_setting(AUTOMADE_KEY, "").rstrip("/")
		return ret

static var database_path:String:
	get:
		var ret : String = get_setting(DATABASE_KEY, "")
		if ret != "":
			if not ret.ends_with(".tres"): ret += ".tres"
		#print("GET:", ret)
		return ret


static func setup():
	# Desperately flail around trying to make keys and stuff

	if not ProjectSettings.has_setting("%s/%s" % [ADDON_KEY,AUTOMADE_KEY]):
		set_setting(AUTOMADE_KEY, DEFAULT_AUTOMADE_PATH)
		#Hisss. Evil. Hiss-->ProjectSettings.set_initial_value("%s/%s" % [ADDON_KEY,AUTOMADE_KEY],
		#DEFAULT_AUTOMADE_PATH)
	if not ProjectSettings.has_setting("%s/%s" % [ADDON_KEY,DATABASE_KEY]):
		#print("Making default db key")
		set_setting(DATABASE_KEY, DEFAULT_DATABASE_PATH_AND_FILENAME)

	# Also hissss->Can't seem to get this to work
	ProjectSettings.set_as_basic(ADDON_KEY, true)


static func set_setting(key: String, value) -> void:
	ProjectSettings.set_setting("%s/%s" % [ADDON_KEY,key], value)
	ProjectSettings.save()


static func get_setting(key: String, default):
	if ProjectSettings.has_setting("%s/%s" % [ADDON_KEY,key]):
		return ProjectSettings.get_setting("%s/%s" % [ADDON_KEY,key])
	else:
		return default


static func save_database(boards) -> void:
	#print_debug("Save called")
	var dbi = database.new() #not intuitive, but you have to new()
	dbi.dict["boards"] = boards
	#print_debug("boards:", boards)
	if database_path == "":
		print_debug("Set your database path and filename in the Project Settings and try again.")
		return
	var err = ResourceSaver.save(dbi, database_path)
	#print_debug(" Save err:", err)
	if err != OK:
		print_debug("Err: %s Could not save your boards database. \
		Make sure all folders in the path exist." % err)
		assert(true,"abort") #?


static func load_database()->Dictionary:
	if FileAccess.file_exists(database_path):
		var di = ResourceLoader.load(database_path)
		return di.dict.get("boards",{})
	return {}

