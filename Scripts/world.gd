extends Node

@onready var main_menu = $"2D Control/MainMenu"
@onready var address_entry = $"2D Control/MainMenu/AddressEntry"
@onready var hud = $"2D Control/HUD"
@onready var health_bar = $"2D Control/HUD/HealthBar"
@onready var selector = $"2D Control/Selector"

const Player = preload("res://Scenes/player.tscn")
const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()

@export var Blacksite: PackedScene
@export var Zone47: PackedScene

var current_map: Node = null  # Store the currently selected map
var map_selected: bool = false  # Track if a map has been chosen

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func _on_host_button_pressed():
	main_menu.hide()
	selector.show()

	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)

	# Ensure the host only adds a player if a map has been selected
	if map_selected:
		add_player(multiplayer.get_unique_id())

	print("Server running on LAN. Use your machine's LAN IP address to join.")

func _on_join_button_pressed():
	main_menu.hide()
	selector.show()

	enet_peer.create_client(address_entry.text, PORT)
	multiplayer.multiplayer_peer = enet_peer

func add_player(peer_id):
	if not map_selected:
		print("A map must be selected before adding players.")
		return  # Prevent adding players before a map is chosen

	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)

	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func update_health_bar(health_value):
	health_bar.value = health_value

func _on_multiplayer_spawner_spawned(node):
	if node.is_multiplayer_authority():
		node.health_changed.connect(update_health_bar)

# Map Selection Functions
func _on_black_site_button_pressed():
	load_map(Blacksite)
	selector.hide()
	hud.show()

func _on_zone_47_button_pressed():
	load_map(Zone47)
	selector.hide()
	hud.show()

func load_map(map_scene: PackedScene):
	if current_map:
		current_map.queue_free()  # Remove previous map
	current_map = map_scene.instantiate()
	add_child(current_map)  # Add new map to the scene tree
	map_selected = true  # Mark that a map has been chosen

	# Add player(s) only after the map is loaded
	if multiplayer.is_server():
		add_player(multiplayer.get_unique_id())
