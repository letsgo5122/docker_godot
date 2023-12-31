GDPC                �                                                                         T   res://.godot/exported/133200997/export-2887990fe5351906ea90a90f098e9db7-p_hero.scn   /      M      3�ǰD�� �d�=;�U#    P   res://.godot/exported/133200997/export-5e376aae3f75d46d1c418bca5034412e-Net.scn �      R      ��4���U@�$��U�        res://.godot/extension_list.cfg ��              
bs�]]3�����*�B    ,   res://.godot/global_script_class_cache.cfg  ��      �       82�N�B��4��=��Ì    L   res://.godot/imported/background4.png-e2c58223f5cda566cca6c82893c2ac37.ctex �K      �u      �e�u�ɱ�ҋ�1�    P   res://.godot/imported/card_back_128.png-6bd0e362e6d738e68d1a35ca01ae189c.ctex   @�      �      D���4��	�ޞ羣iz    D   res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex`�      �      �̛�*$q�*�́        res://.godot/uid_cache.bin  0�      �       ͬ���$�x"���9:       res://GameManager.gd`�      �       ����?&{4�qE�E��       res://Mtprtc/Cli.gd         �      �{r�ޱ�D&s�5��G�       res://Mtprtc/Net.tscn.remap �      `       ��9m0Aqk>��	,�       res://Mtprtc/P_Hero.gd  0+      �      �BC��3�.s���       res://Mtprtc/Svr.gd P4      �      �C��9�h���*��        res://Mtprtc/p_hero.tscn.remap  p�      c       ����R��}�\1xre�       res://icon.svg  p�      �      C��=U���^Qu��U3       res://icon.svg.import   @�      �       4X5^��)�/0�����       res://project.binary�      \      \焚8S��-R6��    $   res://texture/background4.png.importp�      �       �<���+E _�?DGj    (   res://texture/card_back_128.png.import   �      �       �i�Ot,&�i�љSr[�       res://webrtc/LICENSE.json   ��      4      �i}{~Ш�<+�� %�        res://webrtc/webrtc.gdextension 0�      #      "����!�����         extends Node

#Server port
var Server_Port = 5122
#For Client 
var Godot_Debug = "ws://" + "127.0.0.1:5122"
var Docker_server = "ws://" + "127.0.0.1/gd/"
var Svr_addr = Docker_server
enum Msg{
		ID,
		NEW_ROOM,
		ROOM_NUM,
		JOIN,
		MATCH,
		ANSWER,
		OFFER,
		CANDIDATE,
		TEST
	}
var wsPeer := WebSocketMultiplayerPeer.new()
var buffer =""
var hostId = 0
var Users = {} #connected websocket
var User_Info = {}
var Players = [] #join room players
var Rooms = {}
var rndRoom = "23456789abcdefghjkmnprstuvwxyz"

var rtcPeer = WebRTCMultiplayerPeer.new()

@onready var args = Array(OS.get_cmdline_args())
func _ready():
	wsPeer.connect("peer_connected",_on_ws_connected)
	wsPeer.connect("peer_disconnected",_on_ws_disconnected)
	
	multiplayer.connected_to_server.connect(RTCServerConnected)
	multiplayer.peer_connected.connect(RTCPeerConnected)
	multiplayer.peer_disconnected.connect(RTCPeerDisconnected)
	
func RTCServerConnected():
	print("RTC server connected")
func RTCPeerConnected(id):
	print("rtc peer connected " + str(id))
	#wsPeer.close()
func RTCPeerDisconnected(id):
	print("rtc peer disconnected " + str(id))
	
func ServerStart():
	_on_host_pressed()
	
func _on_host_pressed():
	$"../Host".visible = false
	var err = wsPeer.create_server(Server_Port)
	if err == OK:
		User_Info = {"id":wsPeer.get_unique_id(),"name":"WsSvr"}
		$"../RoomNum".text = "id:" + str(User_Info.id)+"\n"
	if OS.get_name() ==  "Windows":
		var lan_ip
		for n in range(0, IP.get_local_interfaces().size()):
			if IP.get_local_interfaces()[n].friendly == "Wi-Fi":
				lan_ip = JSON.stringify(IP.get_local_interfaces()[n]).split("\"")
	#			for i in range(0,lan_ip.size()):
	#				print(lan_ip[5])
		$"../RoomNum".text += str(lan_ip[5])
	#Users[User_Info.id]=User_Info
	#print("state", Peer.get_connection_status())
	
func _on_connect_host_button_down():
	$"../Host".visible = false
	$"../ConnectHost".visible = false
	
	var err = wsPeer.create_client(Svr_addr)
	#$MenuBg/Ip.text = str(userId)
	User_Info = {"name":$"../Name".text}
	#$MenuBg/Msg.add_text(str(userId))
	$"../Msg".add_text($"../Name".text+" Connect Host!")
	$"../Msg".newline()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	wsPeer.poll()
	buffer = []
	while wsPeer.get_available_packet_count():
		buffer = wsPeer.get_packet().get_string_from_utf8()
		var dataPack = JSON.parse_string(buffer)
			
		# Connecting user received self id from host
		if dataPack.msg == Msg.ID:
			if dataPack.id ==1:
				return
			if ! dataPack.has("roomNum"):
				User_Info["id"] = dataPack.id
				#For webrtc 
				rtc_CreateMesh(User_Info["id"])
			#If user joined room
			else :
				hostId = dataPack.hostId
				User_Info["hostId"] = hostId
				User_Info["roomNum"] = dataPack.roomNum
				
			print("Msg.ID User_info: ",User_Info," hostId:",hostId)
			$"../Msg".add_text("Msg."+ Msg.keys()[Msg.ID]+" "+str(dataPack.id))
			
		# Form wsServer send back ROOM_NUM to Creator ,display on host's app 
		if dataPack.msg == Msg.ROOM_NUM:
			if dataPack.has("roomNum") and User_Info.id != 1:
				$"../RoomNum".text = dataPack.roomNum
				hostId = dataPack.hostId
				User_Info["hostId"] = hostId
				User_Info["roomNum"] = dataPack.roomNum
			print("Msg.ROOM_NUM User_info: ",User_Info," hostId:",hostId)
	
		
		if dataPack.msg == Msg.MATCH:
			if User_Info.id != 1 :
				Players = dataPack.players
				print("Msg.MATCH Players ",dataPack.id," myId: ",User_Info.id)
				create_Rtc_Peer(dataPack.id)
			
		if dataPack.msg == Msg.CANDIDATE:
			if rtcPeer.has_peer(dataPack.orgPeer):
				print("Got Candididate: " + str(dataPack.orgPeer) + " my id is " + str(User_Info.id))
				rtcPeer.get_peer(dataPack.orgPeer).connection.add_ice_candidate(dataPack.mid, dataPack.index, dataPack.sdp)
			
		if dataPack.msg == Msg.OFFER:
			if rtcPeer.has_peer(dataPack.orgPeer):
				rtcPeer.get_peer(dataPack.orgPeer).connection.set_remote_description("offer", dataPack.data)
		
		if dataPack.msg == Msg.ANSWER:
			if rtcPeer.has_peer(dataPack.orgPeer):
				rtcPeer.get_peer(dataPack.orgPeer).connection.set_remote_description("answer", dataPack.data)
			
		if dataPack.msg == Msg.TEST:
			print("------------------Test Message: ",dataPack)
			
func create_Rtc_Peer(id):
	print("create_Rtc_Peer:",id,"  My ID :" ,User_Info.id)
	var peer : WebRTCPeerConnection = WebRTCPeerConnection.new()
	peer.initialize({
		"iceServers" : [{ "urls": ["stun:stun.l.google.com:19302"] }]
	})
	print("binding id:" + str(id) + "   my id:" + str(User_Info.id))
	peer.session_description_created.connect(self.offerCreated.bind(id))
	peer.ice_candidate_created.connect(self.iceCandidateCreated.bind(id))
	rtcPeer.add_peer(peer, id)
	print("hostId: ",hostId)
	if id > rtcPeer.get_unique_id():
		peer.create_offer()
	return peer
	
func offerCreated(type, data, id):
	print("offerCreated: ", " type:",type, " data:"+data," id:", id)
	if !rtcPeer.has_peer(id):
		return
	rtcPeer.get_peer(id).connection.set_local_description(type, data)
	if type == "offer":
		sendOffer(id, data)
	else:
		sendAnswer(id, data)

func sendOffer(id, data):
	var message = {
		"peer" : id,
		"orgPeer" : User_Info.id,
		"msg" : Msg.OFFER,
		"data": data,
		"room": User_Info["roomNum"]
	}
	wsPeer.put_packet(JSON.stringify(message).to_utf8_buffer())
	
func sendAnswer(id, data):
	var message = {
		"peer" : id,
		"orgPeer" : User_Info.id,
		"msg" : Msg.ANSWER,
		"data": data,
		"room": User_Info["roomNum"]
	}
	wsPeer.put_packet(JSON.stringify(message).to_utf8_buffer())
	
	
func iceCandidateCreated(midName, indexName, sdpName, id):
	var message = {
		"peer" : id,
		"orgPeer" : User_Info.id,
		"msg" : Msg.CANDIDATE,
		"mid": midName,
		"index": indexName,
		"sdp": sdpName,
		"room": User_Info["roomNum"]
	}
	wsPeer.put_packet(JSON.stringify(message).to_utf8_buffer())
	
func rtc_CreateMesh(id):
	print(id," CreateMesh")
	rtcPeer.create_mesh(id)
	multiplayer.multiplayer_peer = rtcPeer
	
func generate_room_number():
	var num = ""
	for i in range(5):
		var index = randi() % rndRoom.length()
		num += rndRoom[index]
	return num

#Server send back to connected user id 
func _on_ws_connected(id):
	#print("connected id:",id)
	var Data = {
		"id":id,
		"msg":Msg.ID
		}
	Send_One(Data)
	#Send back to connected user id  

func Send_All(data):
	wsPeer.put_packet(JSON.stringify(data).to_utf8_buffer())
	
func Send_One(data):
	wsPeer.get_peer(data.id).put_packet(JSON.stringify(data).to_utf8_buffer())
	
func sendHost(data):
	wsPeer.get_peer(1).put_packet(JSON.stringify(data).to_utf8_buffer())
	
func _on_ws_disconnected(id):
	pass


func _on_room_button_down():
	$"../Room".visible = false
	$"../Join Room".visible = false
	var data = {
		"msg" : Msg.NEW_ROOM,
		"id" : User_Info.id
	}
	sendHost(data)
	
func _on_join_room_button_down():
	if $"../RoomNum".text=="":
		return
	$"../Join Room".visible = false
	if User_Info.has("id"):
		var data = {
			"id" : User_Info.id,
			"msg" : Msg.JOIN,
			"roomNum" : $"../RoomNum".text
		}
		$"../Msg".add_text(str(User_Info.id))
		$"../Msg".newline()
		sendHost(data)


func _on_start_game_button_down():
	Game.rpc()
@rpc("any_peer", "call_local")
func Game():
	$"..".visible = false
	for i in Players:
		var p_hero = load("res://Mtprtc/p_hero.tscn")
		var hero = p_hero.instantiate()
		hero.name = str(i)
		add_child(hero)
		var rnd_x = randi_range(10,20)
		hero.global_position = Vector2(500+rnd_x,200)
		

             RSRC                    PackedScene            ��������                                                  resource_local_to_scene    resource_name    custom_solver_bias    size    script 	   _bundled    
   Texture2D    res://texture/background4.png Rf���R
   Texture2D     res://texture/card_back_128.png �gn��ѹ+   Script    res://Mtprtc/Svr.gd ��������   Script    res://Mtprtc/Cli.gd ��������      local://RectangleShape2D_upd1x �         local://PackedScene_3tril          RectangleShape2D             PackedScene          	         names "   6      Net    layout_mode    anchors_preset    anchor_right    anchor_bottom    grow_horizontal    grow_vertical    Control    base    texture    TextureRect    floor 	   position    scale    StaticBody2D    CollisionShape2D    shape    MenuBg    custom_minimum_size    anchor_left    anchor_top    offset_left    offset_top    offset_right    offset_bottom    expand_mode    Svr    script    Node    Cli    NameTg    text    Label    Name $   theme_override_font_sizes/font_size 	   TextEdit 
   RoomNumTg    RoomNum    Host    Button    ConnectHost    Msg    scroll_following    RichTextLabel    Room 
   Join Room    Start Game    _on_host_pressed    pressed    _on_connect_host_button_down    button_down    _on_room_button_down    _on_join_room_button_down    _on_start_game_button_down    	   variants    ?                    �?                      
     D  D
     pB   @          
     �C  �C            ?     �     H�     C     HC                                       �A     �B     `B      Name      �B     �A     �C     �B            ZYX      B     C     �B     "C   	   Room Num      C     C    ��C     &C     �A     �B     �B     �B      Host 
     pB   B     �C      Connect Host      ,B     fC    ��C    ��C           6C     C     ZC   	   New Room     ��C   
   Join Room      B     �C     C     �C      Start Game       node_count             nodes     ?  ��������       ����                                                    
      ����                                       	                       ����                                ����                     
      ����      	            
                                                               	                             ����                          ����                           ����                                                  #   !   ����                                 "                           $   ����                               !      "              #   %   ����            #      $      %      &   "                 '   &   ����            '      (      )      *   "         +              '   (   ����      ,                  (      -      *   "         .              +   )   ����            /      0      1      2   *   3              '   ,   ����            '      4      5      6   "         7              '   -   ����            &      4      8      6   "         9              '   .   ����            :      ;      <      =   "         >             conn_count             conns     #         0   /                    2   1                    2   3                    2   4                    2   5                    node_paths              editable_instances              version             RSRC              extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	pass
	
func _physics_process(delta):
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		# Add the gravity.
		if not is_on_floor():
			velocity.y += gravity * delta

		# Handle Jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var direction = Input.get_axis("ui_left", "ui_right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		move_and_slide()
         RSRC                    PackedScene            ��������                                                  . 	   position    resource_local_to_scene    resource_name    custom_solver_bias    size    script    properties/0/path    properties/0/spawn    properties/0/sync    properties/0/watch 	   _bundled       Script    res://Mtprtc/P_Hero.gd ��������
   Texture2D    res://icon.svg �,���O      local://RectangleShape2D_f4vq3        %   local://SceneReplicationConfig_qjsxm Q         local://PackedScene_r2kma �         RectangleShape2D       
     �B  �B         SceneReplicationConfig                            	         
                   PackedScene          	         names "   
      P_Hero    script    CharacterBody2D 	   Sprite2D 	   position    texture    CollisionShape2D    shape    MultiplayerSynchronizer    replication_config    	   variants                 
     �@   @         
     �@  �?                         node_count             nodes     (   ��������       ����                            ����                                 ����                                 ����   	                conn_count              conns               node_paths              editable_instances              version             RSRC   extends Node

#Server port
var Server_Port = 5122
#For Client 
var Godot_Debug = "ws://" + "127.0.0.1:5122"
var Docker_server = "ws://" + "127.0.0.1/gd/"
var Svr_addr = Docker_server
enum Msg{
		ID,
		NEW_ROOM,
		ROOM_NUM,
		JOIN,
		MATCH,
		ANSWER,
		OFFER,
		CANDIDATE,
		TEST
	}
var wsPeer := WebSocketMultiplayerPeer.new()
var buffer =""
var hostId = 0
var Peers = [] #connected websocket
var User_Info = {}
var Players = [] #join room players
var Rooms = {}
var rndRoom = "23456789abcdefghjkmnprstuvwxyz"
var rtcPeer = WebRTCMultiplayerPeer.new()

@onready var args = Array(OS.get_cmdline_args())
func _ready():
	
	if args.has("-s"):
		print("starting server...\n")
		ServerStart()
	if OS.get_name() == "Web":
		$"../Host".visible = false
	wsPeer.connect("peer_connected",_on_ws_connected)
	wsPeer.connect("peer_disconnected",_on_ws_disconnected)
	
	multiplayer.connected_to_server.connect(RTCServerConnected)
	multiplayer.peer_connected.connect(RTCPeerConnected)
	multiplayer.peer_disconnected.connect(RTCPeerDisconnected)
	
func RTCServerConnected():
	print("RTC server connected")
func RTCPeerConnected(id):
	print("rtc peer connected " + str(id))
	#wsPeer.close()
func RTCPeerDisconnected(id):
	print("rtc peer disconnected " + str(id))
	
func ServerStart():
	_on_host_pressed()
	
func _on_host_pressed():
	$"../Host".visible = false
	var err = wsPeer.create_server(Server_Port)
	if err == OK:
		User_Info = {"id":wsPeer.get_unique_id(),"name":"WsSvr"}
		$"../RoomNum".text = "id:" + str(User_Info.id)+"\n"
	if OS.get_name() ==  "Windows":
		var lan_ip
		for n in range(0, IP.get_local_interfaces().size()):
			if IP.get_local_interfaces()[n].friendly == "Wi-Fi":
				lan_ip = JSON.stringify(IP.get_local_interfaces()[n]).split("\"")
	#			for i in range(0,lan_ip.size()):
	#				print(lan_ip[5])
		$"../RoomNum".text += str(lan_ip[5])
	#Users[User_Info.id]=User_Info
	#print("state", Peer.get_connection_status())
	
func _on_connect_host_button_down():
	$"../Host".visible = false
	$MenuBg/ConnectHost.visible = false
	
	var err = wsPeer.create_client(Svr_addr)
	#$MenuBg/Ip.text = str(userId)
	User_Info = {"name":$"../Name".text}
	#$MenuBg/Msg.add_text(str(userId))
	$"../Msg".add_text($"../Name".text+" Connect Host!")
	$"../Msg".newline()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	wsPeer.poll()
	buffer = []
	while wsPeer.get_available_packet_count():
		buffer = wsPeer.get_packet().get_string_from_utf8()
		var dataPack = JSON.parse_string(buffer)
			
			
		# Host Side  Host Side  Host Side  Host Side  Host Side  Host Side  Host Side 
		# Host Side  Host Side  Host Side  Host Side  Host Side  Host Side  Host Side 
		if dataPack.msg == Msg.NEW_ROOM:
			var new_hostId = dataPack.id
			var Players = []
			Players.append(new_hostId)
			var roomNum  = generate_room_number()
			Rooms[roomNum] = {
				"hostId" : new_hostId,
				"players" : Players
				}
			$"../RoomNum".text = roomNum
			print("Rooms:",Rooms)
			var data = {
				"id" : new_hostId,
				"msg" : Msg.ROOM_NUM,
				"roomNum" : roomNum,
				"hostId" : Rooms[roomNum]["hostId"],
				"players" : Players
			}
			#send New room num back to creater
			Send_One(data)
		
		if dataPack.msg == Msg.JOIN:
			var roomNum = dataPack.roomNum
			if Rooms.has(roomNum):#Check Svr Rooms
				Rooms[roomNum]["players"].append(dataPack.id)
				#Players.append(dataPack.id)
				print("Rooms:",Rooms)
			#Send Info back to join user 
			var data = {
				"id": dataPack.id,
				"msg" : Msg.ID,
				"roomNum" : roomNum,
				"hostId" : Rooms[roomNum]["hostId"],
				"players" : Rooms[roomNum]["players"]
			}
			Send_One(data)
			
			if Rooms[roomNum]["players"].size() >= 2:
				for pl_id in Rooms[roomNum]["players"]:
					var data_1 = {
						"id": dataPack.id,
						"msg" : Msg.MATCH,
						"players" : Rooms[roomNum]["players"]
					}
					#Send back to joiner
					wsPeer.get_peer(pl_id).put_packet(JSON.stringify(data_1).to_utf8_buffer())

					var data_2 = {
						"id": pl_id,
						"msg" : Msg.MATCH,
						"players" : Rooms[roomNum]["players"]
					}
					wsPeer.get_peer(dataPack.id).put_packet(JSON.stringify(data_2).to_utf8_buffer())
		#---------------------------------------------------------------------------------------------
		if dataPack.msg == Msg.OFFER || dataPack.msg == Msg.ANSWER || dataPack.msg == Msg.CANDIDATE:
			if User_Info.id == 1:
				wsPeer.get_peer(dataPack.peer).put_packet(JSON.stringify(dataPack).to_utf8_buffer())
				
		if dataPack.msg == Msg.TEST:
			print("------------------Test Message: ",dataPack)
			
	
func generate_room_number():
	var num = ""
	for i in range(5):
		var index = randi() % rndRoom.length()
		num += rndRoom[index]
	return num

#Server send back to connected user id 
func _on_ws_connected(id):
	Peers.append(id)
	
	var Data = {
		"id":id,
		"msg":Msg.ID
		}
	Send_One(Data)
	#Send back to connected user id  

func Send_All(data):
	wsPeer.put_packet(JSON.stringify(data).to_utf8_buffer())
	
func Send_One(data):
	wsPeer.get_peer(data.id).put_packet(JSON.stringify(data).to_utf8_buffer())
	
func sendHost(data):
	wsPeer.get_peer(1).put_packet(JSON.stringify(data).to_utf8_buffer())
	
func _on_ws_disconnected(id):
	pass


func _on_room_button_down():
	$"../Room".visible = false
	$"../Join Room".visible = false
	var data = {
		"msg" : Msg.NEW_ROOM,
		"id" : User_Info.id
	}
	sendHost(data)
	
func _on_join_room_button_down():
	if $"../RoomNum".text=="":
		return
	$"../Join Room".visible = false
	if User_Info.has("id"):
		var data = {
			"id" : User_Info.id,
			"msg" : Msg.JOIN,
			"roomNum" : $"../RoomNum".text
		}
		$"../Msg".add_text(str(User_Info.id))
		$"../Msg".newline()
		sendHost(data)


func _on_start_game_button_down():
	Game.rpc()
@rpc("any_peer", "call_local")
func Game():
	$MenuBg.visible = false
	for i in Players:
		var p_hero = load("res://Mtprtc/p_hero.tscn")
		var hero = p_hero.instantiate()
		hero.name = str(i)
		add_child(hero)
		var rnd_x = randi_range(10,20)
		hero.global_position = Vector2(500+rnd_x,200)
		
           GST2   �   �      ����               � �        Ju  RIFFBu  WEBPVP8L5u  /�   ͨ	��a�E��"�����QM�FAI����R�mۦ�w�*j�H
��rfw�<�"�t�(�!la�ӣC��v��1aZ �$�C�m��s�1=�n�I�3sʬ���ޞ�cIoҷ�#���U	�f��@�$I�$ @$fU�-�=�̪޻_����5�=ӗp7SUf"D�,P�$I�$�@Qs���?��p3&�o��-{m��p�$�vURUC7���f��-�-]p��;t÷$I�$I�EĢ�5����u�d��
��$ɒ$ɶ�"�f�5���˞ʌ0S��?��WO�,�>,�2,�4�A	>K��})�M;xO؊���p�mᩭE�^�����X�-���d���:��ݹ5�����T�6fik躊��n�`�$m�ၻ;��!�E.���Q{=���<.�	����:�99Yo �M;�����Y�M�<�P�m���<�����zL��`S��ME鲞4��%��о�Ϙ����u�{�7bbCI������dH|]��&�S�?��������;-��C߭�m��p���ζ[c$l���[��p���'!��Q�𥯧�S�n>u��Ty2ǴM���?�y#���M@<����:��y���ĥ�rGSM��h�8B]���g��۞���;�G�vt�NG=b<'4�rY������O�=��t5�|�F��0�s�y�B�*8(ӫ�<��I�v�Ո�p���Y.~�?~�����5����u�>hB�~�ڰxK��]i ep��C=VhȞ�_��i�hP��S�2�wC�/}:;.}{>���_V��Y�fYЎ��~�����wÓ��v���cc�t�J�y��r���?�/��^��a�;_3�xjMlg�Z���]r,$�ryMS�����mj�������W��-?�l�h�AsxM�#B�D�������8�+�E��\�w��ǯC�X�G"�#��|��P@Sn����|�x��q�x�Qlƣ�/����Ą�祊]3˔)~xܟ�Tھ+��
����	l �E�Dm!�V*������_=��#��1��(��i
�'�;�������&м���t������&M�&5�7����^�����X0�5��+{v�����8��������}��,�?[��e��|�j��Cmb�=\Z�9�nX�f]I8_F���o��t�k��+ج���	Sx` c�\�F����7�����/���$דּ���.�&�5�jF~�L!�R����S�jz��t��t�~Y��q>�˹"���ǵp���T$p��a �e3�]��7�a�����H���v��=��d��xj���1-����,��ސ�R�8��d�@�`rx)��8��0���W?���eY�~��/t��
|�B7e#� ��f���aøN��d*Bx�T�qJN���	�C�P� o�I\���8�����`���v�9�GSu�~��4?��3�����Ə�T֧��{@�}�з��e��,=���}y��|�y�1�O�������6;�$�B�I]fs�ӧ*G��e�6d@��9W�i-Q�zlı���y9#���u.N���3�PQ�s�9u��ӂo���������`�]^ꐣ�r�!����=�\=oX3�R��q�(n����
��I"Ӳ>�E o_���IY�o�ԝ�C(q%��Mj�h;��kR��Ϊ��2�a�=m�/�i�T�+�=�,��Xƽt
����=r���|��R��O��lS�P�j�T�hC0�e^d��4��8�'udY0���[rGh�Fs����TaJ�:vlO�/�<��]66)�6���dk8����08��J�r���O��ӫz ��bs�����Ɉt���3�2��h�G�	h#σ�B� ÆXi��̫��8�[�����6���Ai1_�=獗���mxZu*O�&5����`o�/�s�ЏT��-�RC_J�Cs�P��~Z�����7���͹g(Ke�Ɨ��~/t��v�t�NʙJ^������9���ȹ�X��[�����ewH�
�=_��$�peHWl����u��r��dh��(a�aIb~5=���u2>�A\�e?�k㠼�I��cR�P��e��*��$^�H��q�� �:�X��� }h=�Z�\��8��tP=�: x}�{.�%�j��$ ��6~�q��-Qx5Dq���v�[��|^���	�h���BA`�P��j�O�e�l���۞��k;�q� A� �� Q�s:mhO��LŦ~��[���4����_���R:n��X$ԌAM��s	}��<j���mf}��@�G c�~���H�x�L����7�j�)7����|�V|4F�-,1*��=�(�0��u��fⵃ�%Z����H��LN_����k�Ǟ��hy�G�?V�lS%��2m�&z��S���C���t�i��>t��vDL$���X����!��Β)�ܔ}.�OQ�4K����Gj�!$)��h_OK��-�;:�>X�8�H��l,�LH��*�<���w	�̜��	�&��N��P�#��nGy�?�#�(�ڀ�I����0�hNV~h�8�#�������qZE�� $���(@�!��/�QfM�Ԍ��ș�e�м�Ӊ�V
�e��gu�� �R�.\h������x�4'�Z���OM��E��O_�vl�ja\V;.D�,ƧA�C�81�FEbp���ִ���!��E:uT�����F���ެ���>y���� `S�RϹ���N�r[���GyS��J�`�̫I~�_>��tG�u ��������/y KϘ�!��7�cٙg�ˑp8ZS��{��7�ϙ_|Τ��M� %���ӳ�:t������l������՗�m����Jz+�nGgY�)a�����z(��Ͽ������ϲ���;��w�����W��z�A����z�h�����y!�F�K�C�3!�I�V��{� �����k�{~�
����m�������OP=��/�d_������WQk-��~���?�����]�U��s:]��69�}�t��}<Xh����d��9K\�S4��S�i���問�o�#������] ^&����>�0��ۭ{��x?�=L�=�í,����_����_㏕��l@�����lj�}���B>��K���5��<?���$&�aLB;kI���?3=��qա�=�P�m�o��.��3�; �c]�)��'p
����\�ޮH��qƳ�Y!UCِ.w:ek��m���\���g�m-u*:�}{�������˿��G�r�k�������9�1Y�x��_D�1��h�mR!}W�a��� ��xX�����FQ�m!m�_���\������
�K�X��
�^j4Z��lC_��s����\
�=N�����k�<��$��@ŪA������[������y����c�g��˽q�W�7o	]S���4ix�P��p���ut=7�@%�!Gt���H�'�����N�rPq+,�!X�QU��O�lݚ���y���i��2��^���ݖ�:���!rB3�]o�&R����@Y�×�q�D��I����V'z[�{�?���qE��HG��`��{j>��H��^gz��._����5����;�%XOS��412n �����r����i�^�O[{�63
;)-��)�<����~at�&����z���Kx�i�i{55�wA�yhl뜄4DRr�&=AlTj�ihSI�!���)�����|RN_`2��*���Љ��^S��ZD0�k��dΝ/�v�����E��yl'$a��?���&������J��˳?�d��k6�H�j��|�28A7"
�'�׼O��v���ҘJ����:��gϭ�Ð���:�oUD��_��f��	�����[,�?\~;����'��.-�k����XS�C����o���\i\�m�r;|N'���f���x*!5bL~ɩ���s?��Z��U����e������K���R�D���4�&i��[_���oI�9%`�;�� ��I(�p� ����x�%)��Mʳ��f�NeN���	a��#� F��4��E��E�6�E�*yF>�ƶo�Z'����T���-8e��8\@6�F2JLdB��oZ���!�c_���ʒԩadvv�(�^�+���0d�� �����"��S�C���	�j$�a�ueհ�j�R��_�n�6/�`�)���9a�w���M��̓ ��G������'�䜲��yZ�ݗ�����	��un�r_�r�a8.a�$XBEO�g#F墨v�9��\�C�<5���p�c�Ԉ�F���Ƿ���:��qZ٤��]EVg� /�NC<kH�{�'y�fJ�W_u<(�y���I���*�����nS�L����9Ûv�/
�F*�	m�*�$"M��'$�I�K��ǵa���M~ԣ�Ȫo�`�թ[�����X�����3Nې�z��*��Z�[�q���%+������T�w��h�pm�~�ǟ���% }{$��HR�y�!�� uf�m���az�v}��;���
&%�gZ�؎傾v1��="d9��͐
l+��X��av2��QL��.�� ��[]�N��8�.�~�|�����E�����c$��z�Q�8�W��@r�h��Zi�R�H��)��{m��d2e}��vVx��#��W_��Zr��{p���������9����7��p�|j�I�ϟ����p�:��Q�/�dxb�Yi_IK��ٌ��z��^&`Ԇ8�-HQ(&�s����!��:2Q�����5=P'�����- �X�Q���I�-\:>��J�H�5��I��M���h������yw1�""�� �p5I�l�S�C�����	-|����3,�.�h��iW�'����ytPh�FB�c�/�z%���/{��t��^�~�.�Km�J���{�|����|��e���|�K���hT��TH�x� 
Ds�DPO����[�2(+PC�%F�����9K�\_��3pð-�(I�rּ�E����[}P@a]�`PE8�	n�0�M_�ʹ0��~��Y���,���HF�� g�ao�he�C��]E�˝"��s���q�|e�r�E�>,����︍\ΐa�r����L"�r,н����w��!�|-�~�i&FS�'s�|Fg�m�A�*�ߟ�}K��A}9�B�	���;��c=�}d>ȑ\��#
Fi0%��h̖q��e=���^rCaK�~���3��]���#id�����r_=�2�e���I^%��8��-Y����0ƶJk�Ц�8Dez�+�8~ŝ��?�{�������c���������}�$�!����l���럸�����7�y��Վ�e~��u�^�O�3r�g����ё�E�Щu���
P��/Ǉ�MZ���a�^?��߳�������?��~�a�7����o�Y'����;}���O�$�Ũ�<s�H��]�.N�_�w��.C�x��)�~}����Yk��~�׬I�Q�oE"�>����F(T$<X{��`3�P�ۦ����}�i���S�~QD;�
�-�c�ܿ��	�]��LUg��_�b��R7"�q���{�6��>?��'��2a�/��x�t�6�W��\��W�0�E�v{��yv�l^r�o��t	��eEsލ h<��щ��XD��Oͮo`q{7�L�%�ᾟ9�ODFlƪ <K���ҝs@�e}-E�࿍�A&�"���/o�=�5�\���8�Ez�Z�p`��=$���$�+�N��=��߉�����m�Tc`���M�P���k���ӂ�1I�{��	O��E�b���\�G�� ���5�B*v�T^����g�1�j�ɥ�x踊b��!Q7�麰,�I��魯��B~��(o����Bb�:�svk�Hƃ����G�ox*V���(!�z"s�
a-��Ѯ�!��B8��,�[q��{xe�:cv}|�`J�c^Cq4���X�*wT#��jb�b���1f:rR��R|�~���Й��t�Cߦ/���";�(�x�q-
G\S�+�.���L�4:�ˀ5��1b~�`O�:� �)]�vS�Jkt#F<Ӯ|ٺP �( i�L&Ø3���QI+,O����/Y��>sԊ�����"����Hm_����?�_sN�ZPfy ��9��*���H		k�
Wi�Q���1bI;�:��՟��ù�b���� ً�&����0^��`��* LCO�t��Ư�[�%�[%ઁ���;LⰍ�%Mـc�7������3���S�6��{�?	V"��*���V}�H���E�'l���1uh9&�b&>�?H�p�/iv�6�i�D�W*���֜���xj(��u��9�������a��N����Z����Z��e�g[H�d�*h�e� �����������Om��W-����b��W\ꫭ$A{ �̓���Ўl(�V\�V�u��zL�21�Ξ6�m@+M��i�z�����Z?�/�S/J?;@0MjԒ���]��T_�g[\Jh��6��p�T*.��������5&��e6!p�
Jl2��(B.	2eY��{2�5Aч�;}vZ=&�=���Hv8��2&[��KT��������˝�ʌ�T����5���}5(�J��P�'OL�l�XS�0N��������g������d����J��&���Y�p!a��np�K����y�ĉ9$v^�c4����14�Q��	ɖA��78�*��2�u�\��yz���Q�ҕ�����"Gy���	�D�@a?d,�\w�2_�@�0"F,�����z<��g��zJ��'���$�X��}�)��[ň8J��9�7F�N��8v�1Oƭ:�{ϩ��΄��|��N#ξ��ծ�2������@�mcYlh���x�vY!%pŘ���Uoi\�f��G-��dA�u� ��ǻيuLⵈp>��:����)�E�T�c�Y��nP�Fw��y]�?�J6�բٯ��[�]$ݤ�� U�V�|A�Lg��Hc�f�&��{�����ȝs~��C��q��O�o���N���eޞ���hj�9ӿ�Y�X���@'�3�� �e�9{�����C�R�.�e�E�y�Ջ�T��xP���
�1DR��.�����S;䞋l�[�n+�;��:m�J�\�Ӗ�~�8�w���%V����Q~9��_C����~!�H:���12(�k����Ż>:�xPC��#??~����o�h�ޅj�_�p�!�17�_�����-3(�s�R3���[2�YA���4�>��b3�����>��Xi�4Dt�\���O�wH�}DK���T랶�u�yʹ�?>S�����Ne�j����*Ѹ�P&�do�(����m�Ĵ�dno��˭��&k��S�M�{<��ct�&m��wĬ�B�J�ߛg����}���?�:�.�ν�xd�x��
;j�����Io:�ٓ�2� ?®6�2j]�����?���A��%��Q� 0�wϿd\�:���KT�����㽡��:y���M\�}&-,��^\��~�N1���nB~�!��{���	[�=l	i�]쵮���b��kH�Yu�Pk����}�,�ǩ�)�v�M��<PM�Vw�[���Y[�m�>���A
�M� ��q|���?� ���xY��o�����_�k�ZrYb����������r~#e�Z��kq ˧�� a�0��S9֟Ԯ��֜��YS����[��eL�C$�,��}�G�g��+Q�ƴ���}���	)g/�a�N���>���8|���s� p�M���|�:�΅FF�mq�w�2���c؛�Jm��J��[C�����E,�Ǯ�
��[?�C0LC�Z=p$T���V5Q�7��N�qV���N�u}�~�|��u��7�׮W׹o�~��=�qӸ���Y�.ޯ��������]/�z����ߟ��J#����H�g)8�H��_�^r�^��ޘ��u�/��m���mwi*~�k�)\ѷ�W�����w]��l�{�~��4K�kْ�����G����������������;�R�����&a; ]������j�ѯ��9�5�)t�{�]����h�W�(�گ�Ǘ�۹6j��X��gJ����(]H�I\��`e>����}�S&=P�_0��.a�������3�s �_S���-� F��pv�޿���ӷ;�����Q۶�7l�ʀ0�b^��m�ߧ������ ���uН�@g���k�W�5h����G�{��s��8�yY����n졾B6��߽�|m�Q�z���1��p��_���Ϟ�&�0kx�%�ئ����`[��J线x$3������ˍ�rD�q�)|�L����,U�k��N�9*�$�I�B�����0�$Q �0������b*ki�5J
�.���������,A�_�(c���	?���u�t_��r�C�JS��C�FTn�DQ�5
�t{��:��גZ81�:{��� ��5�E+Ҽ-�`k�Ik
��k�&�7��O���M���(?��\�Hک�����0���mJ.ر����3�|�`�骢���=b���=���^���� fm%���|�+y�12��z�TQ-L!6�: 9_x�n�A�$˶cZ�*�c.�����"����z�梿
�UvU���$*��6���D$���]Z�3o�$q���I��3N�
�ጱ&$eK�I�MV�iEc)��e�yn޴�4��6�  ��H���>�l�U���B	�V2"q%68�_����( ?޿D���̄�%5.4v�s�5.�Kr'L����HW�a����Тi]�5�T�D�"�*e���2�`�B0u�T��V-�Z,�,6rP,���*#��e�mE�	
4N��r�r�:��}#�p��	gW�D��ll��)�{|\�Kk�'cV�$1(
�N���,	j,����	�̲�O����UÆ�F��Cα����I���46 �����u���UW�e%��đ�he!Ed���^!�*67��ɇ�q!��APXrB).6 ������\�_�t��8�����8���׼�% ���h"�@�4x^�b���Ih��=���$[)Y�hp�y�()R׶7��B
O8k���xR��ǒή!W.�R+6�+��%Rs �����qPP�6����%42���H�Ӧ��t2i����!��\�;�\I�N��A���W�/qveIiex��L�ay�KmP��i�����i7DZ@zd�O��~.�P����8
�Z�l��S�;NQ��k��.f�+�X�������#���.=�քE��jo��.���p�����p:lvI.�Y��V�̝"F�/��<��
WC��=�`Ca��];���P�^�W,W��2O��6�h�_5DS�Gus�AO���(9w&�)�	`���PY`�,�Y"Rɔs��� 8y�o�
��j�����0�P-�BB��d�ݧZH5ࡉ�@�Z���ܷ��ňl��H(�����G��Z��+����%0@u�=J+�Nr�Rf��aŜ���jh�uA�+n,��� A��G�h:
�d���W��=��G�����G��*,j�XK2ZQ�)�lS6�R����X@��S�X��F��3�$ER=ûZ@����w�P�i��ṧ3ފ`��7��q�%�=�/��7�p�G	0� �DK�c4cy�@!6��H��m�&��`�w��"�Zqe��ԛS��I6�TJ�(.�E@,�S���[=�Mg�N�MNj�D�� �J$=e�H*\݊�����;�.u �d!�hqDB&���.�Va�ɇ
�v]>o��8�)<�Mu��"���#�|�jHK����	;�ղ}� �p�
�ZETy�������5�R��J�DmdFW�BX�s��K[x,Cw�Z�%apˉU���v@��ÐƧ0]G�%�	
�W=���1�9���	�Y�c�3��;b��31S��^�q��<��eK�=j��@Ʊ|�ͱ�͡��,����)��оי�r�Uh��RH5���j�ޞk6�C�U�N�B�b�R���T���j �U��j���aya��M<�j�/�c+Nh�_=	�à%�_�mdD��ݯ0�e�2�U-`��bLҩ]�(!��9�E7q��Sr��}` С%���s�G;*S�ɡ݂��t�#����붲y��X*���M�n~�����Vx���ϝ�\��I��|=�9��������S��q���5�qx��6��x!�m�ﵰ�G�����U-���^3����\N÷�/�W�%��c����l�x�@vaֹ�~[��З�U]�/嗺�j�fU҅+�5�LM�e|��;|/�+Un���������Ÿ����=,����:
�W�~[_믭k�}	���ŷ�o^�ts��>��RW���ǖ��7��Q��(�𼿍亹��M+�h�d�{Zi�jā��X�[F�_�`�^���-�\������QBhaj	�̏�owA#@,9�X�l9�fR�L3K�y2i�ӴHs�=�.��T1s����ˤ5�s�z�Gs��aÜ�_��ļ�W#g,k0�f��6=��Cٴ�m\�A�]��U:ۚ��}b�l,��T�P�0��=ա�|�t�j+�CC ��i��2K�n4�)����P��NV�z(t��W�)�I|y>7��Y7B��bX
�MB�v������$GO1�z^ꕹ�|�mh,�{�4:�D��PF�4�XP#�b���2��C��\�jI9���ĮЪ*E��6g������	m3%�r�R����ߕ��[��y;�@����=�Գ7` �KF5�֛2${���g�p���e��A���	���g�](n�9�-2֦n�ۉ1LX����0���Q�������mp��Ҟ����Χ�k��	wd����Ȋǅ���
�I�Y���;$G�Ԯ�M�P�nh�
�x0��M�I�c-|/,K�E<�0�VJel���3(�H��9�"&&Cz�k]֝��;��<(�e�z=�����6u]6Nav���.RN����X�Y�Ώ���@'�'�f��й����I��LАH1ފ6��/�2�u�6��Ͼ�e�1�B��Bӭ턔4�:�d��	A�Z3�Τ6@a�׃)�ttZb�06�'S�����̢	���st]�TU ���������P��qp ��*��{Y8�� �Vb�fmN>�z����e���h�e��O�ξkRW؞@��ֱ=�Љ��+��cA�{+�cM)�/��X�
9�E`>� �;�[b=D�D��=
�,��u?��1v�MM\�1��N����}vF&��D<�E��S��T=�f(�m��Q:� ���X��vT��2\��$b��NR@"���
�
K>L�A��(Q��`'�vb7ځUG�T��D�PVy�c<��i��d�#Œ�B��SOGC-��(�r�̀j��$q0�PH0�/����MX��M^�����Z ʬ��T�Ju%�]�7��V��JN�!;GC@�h��m8݇�v^^�Y�v�ml�KLn�ZCq�lL��r}/��ejp����F w�uWsDHZ��%PNXɢ� ���B�r��-#<�>�% ����5Z'�kn �����g�=�JҖ��y�K����'�O�%����ӧbkD!r�`�$�1�������C��vx��V$.ܧ�-3bG{	%@�X��ջM�Qqy�����4�Jɔ�mzy��e���d7l,:�KH@���'� �Zi,7n�1���KGA���F�P�`�E�^�EXNG9���d���u5ֆF��FB�z����=X�p�rXd��K[8���4�F��$sax/K�г�WJ���ǐ�8#�j�i�r�]���p���.c��i%��t5ӱ�p��%��j�2HY�#JLk�$ �0>�[5U��l��µ�Q
��S�eB������J[[Ie�K�h&��aJY.!�=��'���p}DQDH	(縇*C� )u���t)		k��8�a�RE(	��+��4�ޡo���q��߿�Đ$楝�bG����j��U�B�R��("{�-�O�t��sH"���j�ƒ�������Tz��b��ژV	[P��En�����z�Kqػ๜R���ۖ��E4�e���64��������ll.�p��� ���W-K�;��r�r�c���Х�T��A�`qX���e/��9���	���A$t�K���2Ϙ/����	~q7@�2�z����x�
���y]��A7t�7�7^ܙ*��
ٸ�  x5�}���,�g�<jzC��x}�я��r<(�!}VY'��D�B�ig�E�O���0e7�YO�u_�.ݘ�BvԚ�A�ܢ�V%��`�{��X��0G��U��5/[�*G#f#��j]��&�4/�b��Eyn=����7�e- vB����Q�|�]s(�!90�4|(�ٙ~��hp,��JAS+����ς)����t���]9ǩ!{�Z�8�M�FB��(F����_^��>%;w`��Z-���NC������R���j+�W�Y�PZ1��S|���W��A��lW��������e��ns�s�%�7�ٯ/�t���l�����.��r��u��[#w���ӊZ�ԯ�+�&/W����z]���Ih��
������rm�y=���x����y����5_,�C~Q�Xf��r��*���mueު�R�����W�I	<�y~�LOy��_=���.�k�~}a�/d-���m�ׅ��z_��+4i�R����y�C{+C�v�c�{�d������)|���¤t���+�]n�Ws��Aj���ۻ�e�N�V�J��)����RW�Wv�E� ��1��D�㹧>�L>�XSxpg0G��1���+��CTyŮ<�1��s
o�����>S����l�Θ1�	g��s�A-�a�F�6I�' �l�!��
�l��Y =����_R�T��&Ñ�<P�+F������V>mMG�f���eA�!إ��}�IbbT/�m�&�
f�>菎=�QR��Q�Ǵ�<i�H��Els.2U����;|�A�,7�>r65�;�끙"Ħ�G2E;I#@�2VA�9y���j���ᕋ�����e����t/�x���� �O#SU�.N�k�����@^ѪF\L �-m�{�T�E�Rs9&#�DX���˰�1���w:�~��k2�u[q�E�X{��⻍��H�Pm��ؕ��F[�)BQ��#�M��N����jK¨jaKU�AVjڕ�!R���� �w��/��[�� !.S�+dʥ:A͘U4v��5&A�N�(�Or��$���6Y��o�|dsE �UDh��')��2H�T��=Hp��`Jw�!�� ��?D���"��5z�	2;0)�eS�h��OG{Sc�j���}C���zaX���^>�9N����������2�:��}z���A-F��h��X˞m��z�+>�Q)��y��%(������2'ʦ�*<��� ������Я��)���է?���h���R1��`�{ �G�c4�Q@F�S����;�� #𬞐�֘�[�a?=r��	�Ah%��i"+�B(M]���'���a����9.�c���y���d,x�6H�f�P��a!h�6��m��S������+�4j�����d�����dVۈxE�y�����F?#Ķ�L�O@@�Pd�5hG����r݂��C��E����ϩ�$h0$+����h�$}\T>)��  .8 i%��փP�����50�%8���ǹ�e��� 9�
����Σd)Rs�,�)� �u?͝.߇�z��}�M_ą�w�6�f�1��,b!	E阵�Ġ�r-�l�s_�Kaê�ǟsEJ#B�i�Yl*����
�pw��[��z�4v*0نYzn�-��0]H��<R"U��2g����RPPE�Ê�!88�-(WT���͸a�R���:�DF�Ii5.���
�Z��=��H2�����2�n����.��I�ޮ\��|�{��H��xJV�[kX��\�y�G ��	�XFJ'�����sM��Y�B�IFcb�n��=��c�u8ш�J���JZ��U멮�,[��P	�$G<ڇM����(P1ˁ�ۣ����h�Qq�3�����A.�p�a�i�	I�2[T�p�GeZs�,�d����հQX	�s����i��S;��F�!^@ }`�F�h��՚�j��4 �N�J�����l�ŕ��wH��ߡ)�`z� jw�O�"om�������CX�$�E�)�~ɀ���O�{e!I��*	�DB���DլЍx!�`�&�M�U��w�)bE�p�;
 *����z���Ť%�暠9�x}x��ćގMN�XK�,I�ə�|FHY^��'���n�mD�%�_�A��w�ݵ�A	5"�IJ���6JC(-X����n'����E��J��d`���@G{[-}��h,�iZ�{>��,�C�]q(M���1.�`�y�����8g�D`'��";G���t�Q�Uq�O���=�y����0@���ґ�.�e��&H�TZ����'�k˨!��h�F ���Jv�K��<8X״���U�X8q��Q66���?�3N?\�:B��r^:���kݞ��� *��Y��*IX.V@E�A��(岇�7jA���ȵ�j	Q�K��4�������}����ov6;��_������q���<���<���{
C�-����ˊ�{����Y�pI�t�rk�>^7���Og�@�V���e���ag-T�\"�T��]�Ҋ�+�����b]�+kA�%�I�u65c3fy��r�����Y�Y񵘲���ż�z���[VcQ���<��[v5"=H=���4��vM�,��C��ֽl�v��l��S�����?��A�����O6�9/t���?:l������A�6�]�Ё�y�>�c�b���M�㱧¦�-����������st���}�5u_o��=S�d���3��OOg�{
�𣙭e�sg���g!���N{j,�[F�w�2C?��<��w�@��:����|'.��^J<z�z����֬=6���്ea�y����f�d���[�#��D�<}eg�uk�6�L1�*gͮ'g��������]SPT��F7��р���ǘ��)hA���"�M�<��v�746j��kk��L��;�Xb�����	�Vj���~3��h�ՕZ��Z�d��l�H'GNP�0èT�N�ʦ��1s ��t�Lf�6:5�b_>� ��� ��[�c�@z��M��6�R�����6a�K�yw��I��)�g�ږ�p��۵s�]$W�o�� jZ�\e��6����e%
��h>���N��M�3����#L�:�@�v��<��U�3fH(d�բ��FL0_h�/Y5P�%b]�"I�	8bA9��0����ejA$E3` Y����,VŉPbW�&UW#"�+ 4̵�$�)�%�D�F��:_��ϧ�:V��
e�4<d5Dr�ބ��kk��NF8�4������|���c�$72��S��xZ��c�<�,��Bx'�@g�9G��t������U9��[׃���As�ۓ�0 ��ƅ<����
� %��M˅^�1�OT=Î�	)dX�w�@P�S��4-�G�!����L����qtX��r2j�Ge���� a)I$R��"h�Ap�T0wZ�銊�
���Z�""�'�E�ҋ8��0`�`W��r���/JŔ�)�
j�i2��_Vrd�	��e��}�'\�K������	�����m;Co��K�y��4�\�duS����(d���`�X��`��[�3e0�r�kG�i�147�F�e3͑�`�ѐ�f��4���2������y%5
MN�|�N/����(��N*xm���D����|��2��ԏpMU��U�p���]�9���[����(T�d�^ ץ�-/[�����Qo�t\����.+�Rʹ]�Ta�&�u�Ḑe�H��޵�_?���١v=�.` ����N2�Z�#��B0-�]WH�[�{#! �XSFUx�+��(� 7	^͔�݋3^�*��,�X9�)\�c/�����rņR��5� ē�hV��x�u���ٚrw��2Fe����4@���1�,�Bs,�*���Z.=����"l
e6$*)KU*zyP�ȵm�0�:���p��6�h#�iƄ9x�����5%�zĚ��:Ip�ŕЬ�Pe#P���t�^��c����w��z*�!�R�2�Z�r�֠����8�%����mA�#�VH?��e/E��4ж���T���1L�B���S����4�;�4kO4 �N�%8�pۈ�HAO�`r�2��WJ�V`�q�P�~�(����Η�U���uo\ӣ�2h���JZV ��aIԫG��n�ۈ����=*�FZ�w�	:������(��p�}JGi�r�g(�+k��:u��-'�l �#� ��<�NA��2�1�ʚ�p�,IP��AT@p�z�PB�S�^M��"-�<�Sd���EQQΉ=��ITR�&�(9�21����2�U:<�.�93>�t����u6�:0FC��U�#lZt9���բ�nB8����>��0�+o⧾}�QU�o:W�do�Qs�"f�1���\�H���K;1��i�H����U���*0i�B�ȜK���}�FǍ�a��#��=�[\�3��E2E�
����bJ"�$A�|@/��AR�!�3T@�\FT��j��� >W��l��$Bm�P!a
ʡJ*l�K1������]���Z�ǔ��Hkq`�"���M�9���R�0e:�\#Ӱ��r���o
�g݉�o'�[5�'��E^�wH�������p+v�6p,� �!����E�ʫ#>"�.l��- ��C��N0Z�M�/HP���O��ą���q��SB8@<���쇫0N��Psl­㚪�i+[���<m�{�@۩̬��(,4�u� p�؜&�q�KaЯ��b?��ea��d�o�fy��Ѽ��p,%�MZNl���5���~M�����1��z�o}�b�����t��m_W~�;�9������|�����i�T��Sͺ�y*�Õ~�_�{�o�d'�~��b���帇��x o;�8�/[o{/��V_���L��^��%$;w��R�CY
t>����V�]}�>�^��z���/!�nr��\i[����!�s��zo^������w�u��J�eQs�?����QC԰�n������ǯԺ�;F����ZnKܷ^NW��D6p4ѺB'�W��jPD�F)�X�Q���Ч��Ƭ���<��čN+�:z_�w�xlB��͸�ρ����<��w�����:�❥V�a����S�?s������1������I\���6iξѰ^h'���?��:I�1����0��I+���;;j�ֹ��9-�Ļ�ȞQC�.�`�l�n�3L�D~�z���;5��J�b��S���n++z�Ժ�N������tYr�I�2��A.rj� B \]� �J|VJ&:<�)��A5�e�i��"u݌�)qؠQon���@�B��\�˥�N��&m�)���8��d}x���s}����2M��p�J5�r2�1�ȹD�^�NZW�Ba]�|���cZ�? �?z�Fq��x�huͰK�Z�D��R�!�uO�P!�� �����z�� ��e�6��:'�!L���F��Ny(,������/�jCM,K��1iKh���8�!�ի�/)o�!�6�J�.)A	�(Qr�=����L���4�岹�+q�݆�S@�-L�uee	��vOtoY�wQ�e8H�ä!����H.h؎�y!
̐�ʈv�L�� FU��0��i�j[`��I�(��E���y
��{e�6'�O�+	�ӂr0����=�0qj?`��@	��P]u��Sؠ&^w�͉�{[;JӞ���u\/�1؁�0v��-?BB$�DZ�uR�0!�
�'� 6g؅���T�V��c\���a��B!),��@�?d�j�� �:Mu�l!�I�@�P
ւ��y+�iE���D����ěwp'A��o�	�2� ����x�"�eD�G��I.FM.�:�P'���j�С\�4�	����@a���6�K�e[�.=�X"�`A��).RXg�vܳ�u��bJ.��V��j� �å�Yr]=��SFEY�Y�	j���3d�n���LP!㞙H���t�.��rz[t�A���K�����A��ҧ���6V.�p/X��ԏ��#!+R�-j+�"��P�zU��,�\���]������U[@5Y�PR4L�PB��qR�Wo��l_N�K��r^�Rp�K��]ÂnO��C���X�c������W��-���p�@�@e=��"2Tb.�`9�Lg��ʬۍ�t�U3xȈ�I+" �����9*�'��u.a8AΒ	g�ű��5�ِBlz��c�W}�$�^$8I/�W��C� ���腗��B��C	c(
��X�I���t=��[�_��H+��p��9���/�����CJ)��^��q�Q�1���B�� ����-I�I�:i[ ��S�Җ?a�a�K;8�MD�i�:����1�Bぱ��+S�$��.E�EP� �J�6�o����\+i:��p���$�uUG-�3<�; �	�ʼJ��qM��5�{$``p�U�TP��b�
�/��7|  �VGo��q��!\����I��Ÿ��jr$�"d&��p����(xT��cqB/EשMR2����{X���IY*#.�T�I|l��cC*C�1��#��6L��˲��T�2�lp�rup���\�
� �j\H`U�|�8
YF��xQrH�a��%��E%�X���ð�,�1��X��w��Ò���	��R���k3�(ջ���l� �1��t*j_N������Z$�#CU2G���tdդCd���E�r��eJ �oF�K���j��,��B����NbHYNf-Y�����E"_��q/Z��`+�@&1Wk���G&�
���؁B@R����� ��:�Q�ۼ�:�2�+�S���{�/q���K�^�'R.�������� ���$�0ݎ<�%� >�ii������q<�5/H�^R�<��Sz+{Z��=�^`��P�
9���6x��2P�nސ�X�%iڥ�p������RS�
��~�V�a��ϲhq[h+�n����4/ޮ�K�d���:y�o��z�>��0�R:�E[�mP)����Ғ&�v�>���g��h�T�zO���.z���9<V�q=��\�Ď]wB�A5���A�N
{A� U���ы�X4S��{Yf��΁�:�����>16hר��岣V�[�I�M�/;j��M�9�������U<��������w�~?7����~��<��?Nh#�Q��﷟_�����~�.]�����+��k�����KB�-JS*,_C��q~�e묾����[ח�7����&_0QMk�jϗč��%v�S_᫹�o����/���?;L��%O���[��S�������5���~���K�8�o���C�ڭ���+dW"��Qx��_rM��w}K��W��*�'�Y��fl��>�[yHǟ����V�Y�Win3³����˦��m�5��p"$t�x�6}<�&�M��Y:���eY�v��hw�}T*]p����Ke=��磮��4ܛ7�t؉�i�ụ�����L�}ɌTX7���e�u�T:���AY���ADxl��p�7��`Ƃzgk�Gý
[N�2eg�;�'��9q㼱g�P7�Ϡ��.v�A�lr6B`t�z΀�2j��#9���\e���w﨨�{�`�
��& ϸ��ꠞ�T�_��ˇ׾�]�����"T"G�Y��Ԫ�EDP��p���v-񪸎�η�Ȳ�	��	,e�mC�,�����gf��q�@4�8d_WAx�C�2^�R�	�萒����@#?<�v��dI������'a�%b�~������*n�Y6�婨d��� ���T����W����Ki=��ۇS��Ű�2;��^���!g����܁�Q#�9C4�8q���%�2=V�{��ul��8�vuh1x}�Jw���e��q�戥�@ְїe�}���U�A���#�^1�Z>�hdK����Z�᰼A�HY�$�Hb0h�-QymTi�},�a�V���V�!\�r����8s84yvc�,YL�v-6m�ȝ�/��ǎ�qlS�2�o�5⑄A�A���c�`�\�(�-�@؛B'�%���Ή��2V�;���3l��0,�\�bx�NӺT�a$��K��-O�n�9��P���d#$˄��#1L�v��������]��oV���\u���'1@��{ԔB�Ʊ���CV�t�0|q~*GE���<��@<!1̀­.C�B���)B��r���V�8*Eo﹢�ʝ��#��8�}>zt�iό��u�p��*�kC��l��n��J5��T��Kcu��4B=�����C�����.�5�֪9����h(^��>r�0= \�Nٶ��ɳ��v�Gl()�&�dݣ�����	�j�>?ϝ�m�v=��z∘�hohH�7@�f��i�X*3���X���9aF���\as-�b���C��Kz=����q��g؏Y�q4���Twvan�3�y��Ȋ�v9&�@g������P�̼�8ֱ �JE�1�HuR��w���yMM'�[2����t��[�����o )G�u\�A��*�r4�C��۪c�p��А,�:Xf^��`j�r�$��7a�d&��ƴ����	b(��g��uL�r��B[�b��*\0,������
�1w$PF9�%/����u�����s �u�M�OO.�aˆ�.[΢����.	���^?�:�8uH��~y��%0 �t16�TR»��&��vF[e��f�״8=���R��˷GIڌ4�T��"p�|u�u��:o�=���8$Baq��M\�_��Ͱ�"l��USyx�j�2O���#����
_J�)>N��IAR^�EO���$Uy����	���aƂ\9a���_χ�Rz0�Y��'�aQ��JRπ���L��k�ݯ�@�cvl�z�D{,wT8 �B�d1��P)���vP�������1Bƶ�����Mc���1�S�3_Bcm�u����J9x9�R��n����1ow�L�K�e͵�@g]֐���D#��*.��"Sy� h����k��eh��Ծ����^CF�PFH]UQ����hj�z�2г��Z3b.��}�W`��v@���FWQ;@�F��Po��7a|��%
�+� :�)/���8��aKj`Wj$�DRf�H������qJ��/�̾��*��[��kKM Z�n��Ӛ�bw��^�����
nn�ZA�����A�~�^�JN�#���]
IP�3'���p�O)	�da����+[��UƁ���x��gU��[DT�yy���E7}�1�m#-w���I��l��/�2Vs�pa����z���2��v�O�=�[�g`���C�ڜ !�5��|�Vuh�.���0��2��޼+ȑ�b�O�S��$}:o���+[z�-���x�L��h��y#}c�>�r�ng��h..Ô����ݔ.�۾�����Q�\�J��M8K%T̾�3�9��#!(R��~�n�)���z0�̗��8�x9��R�{�C��֡9�o�0�[�Gy��+�G�c����UF��?�.5hPUЬ:��u\���.��v�Ҩۨ��	зR��{w��B{��«g������#��Cp��S���n��R{:6׌C�m�����c��i�P�~��[�咠���{��ޯ������?��6 �J4��ӻ�~Ͻ�r��S:&�:�Ū�>������Ω�)�q���5�c~Oc,�6�����s�Ϸ��A��_�! ����7��S������p':���?@QW�}=��Ae���L�k�c(��;����}���5@p#�<����>껢��blm��2�ؗ����Hwg	�xn׺B��F�O�V�w;�\���Nُ��6�\��?����b���zb��UL�dْ�,�H+�y�e��{�g,�;k�c�s�9�Zwr�}5_)#����?u�v7�R�ޣz�7����݊{����FY�Ǻ>ӈ���EŎ��z[�Q�>�U۪���+����t��̨&�Dk�?�vp������������O�+/���ŢA��=xsi[�J�P�Z3�i}/��V���-��N�E֭�{���[��U�a)�\ZG�+���婹֖�ꗧ9�vY�=��ϵ����v嘚��L"��q,�z9����}�CޒF(F<�������;\MJ%T�ӻ9K.�`���LY#��%�����j���ZB������{
?�)8�%�v�7�o��8��;�]`��[�X}[�bPE�O�8���������Sb�2�u޾[��X��o=z�#X0ʫ/с*��bŠn^Ǻ]�Òi�k���C6�b��8Qu���E�cD=*�L-�X�/Q�%z�~����!�k0��rp]U��.����-'�<��-�3�y*Nc3�(�|�F�JA���|�;K�G�RB��f��޲*�0�y)��:V @V%cu��Qׄ2�e�r
g���ƿK���Oe�C��>�Z�!A�F��R �} hۜ1�_��7��������t[U#�Jy����GR
�j��<E� 6лJ����s�,=֌��c���巡D��eJ!	�Is����'�d[��2�!�IEf�����ÿ�a���4h��ENmy�������ϰx�9K�5�hya���}���@�D�D�Cl��UCW���+Awk�̗A�t�;���7�����>�����T�Y������x�@?� ��z�MG���Τ|/��U��/,Â;��O㴒�&L�ڇ��c
��$��uk�ju}��L7aL�e�ˇ=��t��c�&6m���5��{c� ��U�6�������<�8�ޖ��?����s_�g�-q��m0�i��ڤ4<��~.�������,�B{�Sӌl����L��Q�	��l��G��x��5=Fm�C��S1^V��hKL��oʟ�os�ZZ���w�+����
�������]b�L�-�����{[k"�KV�,��FZ��ϸ��m|���ۚ�_�-�Է�\ɸk�������TNd*�j��ec�ap�\i'�YM��;�����Z�56 �ؽ��y�6?P0��t�S��@qz)�~7�S������XŬ���o�6��O+3�X��M���}\�I�)TI�m�ɠ3n���v�ze\�j�aGޫ��_��5y3���_��5�����"��%����/��u�o�wg� �XG��-���bk���������{�T�R&���S�у�;�^�NK����C��^��ܶ�%�V�?�;B	�+`�C�7�b��Zk���k�7�����3�d���06-6�F�c}�h�E&K��0����O�=�쇤:�?\q�sYRΫ��6����:�ۄ���9��ٵ�k��L�2Q����k�����5�?������O��n�gg���wU��G���g����E|wz��Ou�Cye��%���;q�-��K���1��V��C����[����%�v��4�?����K��>�K诋M�XIa�{ۓ�Z���Ztya;���u�REjH�S�舧�M�|�ute �t�����m�S�S�)�(�+��غL�:/8Z���8N!}:�ʬ÷y���Q��v�j�+�����5:WUy����x��#���-��ni\���������1�K(���j퀔��Ҹ�F�^;.8�֠P�##��'�X&Jk������lh�{ύB�"�����&����6)��6����k�'��V�٢/�s/O9�6���Y�/���(UGH��@�G i����hsǰ�iltb��Ԯ�" q4P&^s���kk����Ǻ�4n]s+�gQ���齁fq��+cUZ�6�i��oĐ�9zM��d�;��}b+��}�}eOWø&��A�Vl.�r�D�z]50��^W�����X��
j�n��x��}���"=qh��%�7��a>�߰��l�0��8-�S��vhdt�׎a��-C�	�%��.�G����� ��2v���S(�/���=��ϗ\��srW@��g�5R��`�DYHI���4����̃D�O?�������m��x���jc<އ{֫��4y��ǫk�<v�6)~}7��kh���J��*X��h�C��x�Z8��x�3rh����3px�m��6]>���M���߰������}v����/�����o��Y��K��iF���}i��5��40��~��g�Ísl{�[��tVRK�5���[�x�y����e���c^��}Q�h;�|%� ������M���b�ܘy�����8�n�z��GS��c	*v�^�y��e['�j�RNA�<S׉Gi�ʽ;��(��|�`{��
Ja�,����z��bT���%���������V*���;i���}�ܮW5��$�{��+����[���{�������[�#:�����5��Cf���a�g�5Hɿ[���0~]�W��ƍD�C)�x��]���2P����EI��<�8��pl{Ȇd9C`i{��c.j=%u;3��%m>ߓZ��ᏝEx�P�cj�[�o�t?�|܊%a�^bO{8�6Y���j����ݞr�A�{ޚS�� �t�c��w�F;����dY�[�O�j�t�����^l�[{��2p3vKAKT�<��\!{J���a��LҲ?�v�A���P�ѷ�o%��>*&
<�-y������y���iL�ۆ+ǫ%˪������uQ9۬��h���([�Q{�R;o���ܧ/_����->���A�w���o��)��ԣ�<�c�4���/��ɵ4�XC�d�r�K����#�0qq���=� �~�K����1&�����x�?�ݯCK��> $���������9�f���	����3�Kgo��K����!�j����p�z)�n�dL��k�q�t�#��;�Yb���-�x����y5lE�p�iMo��٧��HF?n^��v��K��ðl��(j0v��k��'Tx���P��r��AE��=8�����s��{Iz%�be
|Ȓ���s��m��NzB�r�|y���y҃��|�؃ZO���Aj�2;ʟj�&�5QR8�`͸~5�ZWX���#��M�p��ϙH��u�/!���ȇ�l'qP:H�V�gs�m���<f��c�M����y�:z9����[z\�����3q>��Y|ܑ7aW&� �2}]hdI��E/���7�X_�VL�˧���4�/�T��,��R�ӵ5���\����-Yjpo��s}�̾���o��#�^Q{uս����i�<��x�i��|��/����΅�`�,9"M��;��UM����M�����}@���~P�`�kG����3����o�f�߆����w�r9����S���1x�LqC*�,��|]��.Y������D;o����٨}��7�U�b��S�.�$eت�+O�=I�(�՗����<��xf��Ye������Oi�P.}��C [.hu�/퍍=V5)�\��^}k���w�ֈ�6��>�<�ϋ_�w�B���b���y�{~	Z؀u{Ӕؤ���Z��I�ٳ��t��E<��-uvF�I���6���x���]V�q����#� ��úS�je_��#NO�]'��Zi�+"W���_�}�E�v-Fa�}�D��yc��!;��K��w�G�W ���֐�t!z�h����������k�^��?�^�l	�xϦ泱��5{a�6�+8cm��N�6���=O�����P�X&z�:7c���g�^��-��\�Z�twڞ�����i;���;�v�ɫ�����-yJ��_N�k���(9�M��6^[oQ�K��l'캫U�;M�������>.o�2��h5"\�.�C�l�w��)����s�&7����^��=��-�A����5�ek�� �b��Ld��?�ݑ��R�y�OW��Y7?���߾���_��@֎�5�y.o�HP��?+7�S�S1S����ײ��g�(`����\��q~x�y1B�e��
��_l�s��l�͏j qT8K��������q
��[�*���X��I�f,C����}�Q2��H�Vj��ڱ�պl}�a����Z�T�TC���y�y��:m��1� mU�<"�+�c�J%- ���7���I�[Kr\�oR���`�ŰK ɇ�+�$�l�կuKژJ��tY?�XK� $��v�t��^�S��x�q�����e�|kz�}n�/o�Aܢ��K�	>٩r�~ǭq���'�x��~<�+xY�4�M��Yy3<�m�.�\������b���hW�O_��ޯ��l��&�M��+�:]җs�V����rx@K댾��d���)�$`.��*�r�������CϧHXZ�7Լ=�q�|/�Z�Wp�~���M�\҇!+-8�S����G��"�����������1��WB�k_��8ˌ/�۾�����쇌����0��'Cp1F/o�>�o����9��I�=N�/�5��a��=@�C �%\���� V���N���&��-�[�/�.�p���z�����ˣe�D$W-1���4���O��?s��=�ܒ����Rq��FV�o[�s7)U�þ�Yy��O'�+ ����z���)��(@VF���&�*%���~FN��D.��"�p3��߅>�^�7��?��O��Ҙ%�i�Hϭ�jԠ�Tk�8Ӽ��HU�;vͪeаD8���1��s  (�-HRĈ�	�˯"!WU��Q�����]�WL=5Ƶ��'7�x�����4CSi�Q�ig[����U��͢Š�@�M&���p ����&���Xm�H�H�m�B�j�E^ז��f-5,�l9N�eb����G��)�������	���T���Ў&l⟫�:�Y\R���&�s+�	��=N�d�8�>?Y8օ���������F[�[W���0	Dh5(�/N�(2����I�ۗZ�������\���?��͍i/��6xl��Z��0A�CǏ�G�K����P�8dao7KF�RE�rc�n��r�S��O�x/����~��/����Nu�R�k�������(�̼	���Sm}�9w�V�_�	�4��s�f��[O��/����c�{�nw�Ѷ��DPz�~����I/`�ՎMտ��W��딥��S�%sŝ"!T5�w�,�Ŷ�A����4zV�����y1bm��K�p�#����˾�����G�,E]��b24Hnɟ���	���S"��U����r/S�}���z��m�(nH�e�9���ӵ��yU���������;�Z���qRF�Ŷ�����,W�c�{7�t1��/���.P�Uڬ��K�y�7�Ί�΅�.KV���9�*�V������Ͽz��q��p.��� x��	1den+�������T����:?>���tl���/n^�R�$���:�H�|P+*P���J@��ڤ�G|�+!��8lGt���A�:�-%M<6}>�6٭t�F���V;�כϧ��cK���f�Қ1F)uh�(I�i�T�amS��{Ƨ�_��:����%�c ��Z�].P��[��޿GP�-[.X
��tKW��,K�X��|�~[��^�7�2�?�ހ���#?��U	w��.݄_
X�	V'����P����[uc*�")K��>D�eECs�yI�=�����r�xN*=�\�[h���W��&���4�\��9ңM^.�}�����
��Q{�a�Z��*w�����������^���j٤$�֗m�so������>b�tʸ��9g�h�ft\�^Ak$���w>�@[�ۼ��e��ۘJ��W��T�o/��������һ�_Л�¯�%�?^�����s��O�����߱;��/���+T\��OvS}���|���P��M�ݒ+j�>���&7i�y�e'��.�JD�#���ێ�`����}D[HJ/�U�8ԧ�>�?L/���84��Yz���Glc7�")4��qeD�2ԗ���{&��,�b�%��tߜ9�5���B��ƭ<���,����X��L�����9������˱��D���!W������^~�������t"%��c���Ӂ7��:�R|YJ�	�f�I�eՁ;�a�Q����~���7,����u�=�]|>9�L7C��g^�C�E������1 5n�R�]�T<����|Ն�$�p4OQ ���h����5fϬ���uY>�l/t	�$r�n���#����skP�!$�_�WX�{ja>���6]�('y�V��n"N֑i�>ϵ���,�^�%~�,�3�,x��2�i��QH���p
^�ލ@�QC�ȴAp�����0^�(��XJ��<`�q��z�����17��3�zVuZIPg�X��aӛ���_�8p�VF����=t�����ޭ@ S>�N�hЧ��� L�{��b���Q�0m��r�LC�	[%�Zݰj9��xMK�W!��6?N3s=�x��W]�cmh�(����T����b��9�N�nHh����g�C��.�Oq
>���Z��:�� �w�&����(iH�{p+>��K����{?���3�d
����n��v��O�}��=���x�~���>0d��G��j?�ŭ5����*��Jx`+��
�����琂	��[�ÚK}����?\��agu�@�,0L~>���P��H��m=Ci��mr'�k��{��)��m��܏�jXcU,k�Chl�����ᥭ�~��|~9^���$�q��PMV�!�ְx�/�aE�G�w�w`YV� �z3X�Z|Fv�
,���"L�M�Ч�QzT�#`�ܖ/y�џ�nG��'�hC�|���ɷt������wף�O��|����LB=������������ρ�N�D^�_�'0g�L#s�R��|K{�7�c���Lם��W���a���Og�����eJ��5���IE�����v�yɧ�w�.�8��}�>��١uGCS�q/����ҷ�<���m4%�����^ܻ���t�-~1+,��ҋUҟ�FK�Z�?)�c���Ao��&ܥ�P�!��¼@�
} o̺<�KP��1W!D���&�"��5O������謰#N+Ay�Bم�MT	  �<=!�7��Aj��8�	g~��2HaY.)��e@�!S�i���Ć�� �J B�U��R�%<�C�Ȑ�A�`5#�_���%�A힘�J�t�!}y��YN�1���&�kyUy�N�B,1p
�
�%o�'�<�/��J��               [remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://crgbmyja74fgo"
path="res://.godot/imported/background4.png-e2c58223f5cda566cca6c82893c2ac37.ctex"
metadata={
"vram_texture": false
}
         GST2   Z   �      ����               Z �        �  RIFF�  WEBPVP8L�  /Y� ��m��O�m{P�Q���ff�~�yE5���ö=�[ۮ�xe۶m�m�l�F�m�vm+�l}30��Dc�����kۢ�������_������=k�]�i�;:�lOz��������?����/��w��~����GO���?z�G���y?�ӏ����?���>|��/}����ۇ�ÿ���?z�GO�������?}�����Ws��-WDCvc�YKH��������?�ӏ^���~�����뛾~�[&�L�9��y���o������������q�_���}��oo��[}��_}�g��+~�����_����|�?��_|�����}�xӿ���{�:����'~��w�^���vHf���1V�d7h�#����_~�����_��__����<��ΐ��9���˯Kwɥw��?��䛓�|q��Kߜ���nܫ}���~��>�����~��?��?�O���}w�ۇ~s髓�O�9���|���۬���Vk��U5$`�z�ۓ�^��;��ş=������o�����fV՚c�:>�w�w{{x{xw�+w�v�ٛG}w�����͟>�뾹��qWw�a��=۱�$�f�s���%	��5�����髧���o���c�h�Қ�%5�0*q�9v�C�;�;}{x{|{��:t�cN(ZV58�\k��pN�4����}䛻��n:4cq�$K�QvcI�̙�9s��um%W��"NS5�-��+��[$T�tv=�aƤ�����֌�P5�"��lv����]�HZ�HKk��h�5�%�T �bt�5Is^�T̒6�%1I�j�F��nG�XUK��hzZ1�;�ӤJ���r��4)$�v]q�bFvҪZ[UCe��i%�
�ƈ7�$�H���6k�H+^���ˉ�fi�r�x��s���v#���ͨ��vNKҌv���&�g�ֱ%v;f풥�n`�v29�%��[HHm9�ƪ��b��$�9�Ca�bri��ͮ�d�Z(6�4�Y��ӆJhP �۪;��,�J�*[Jk����V�)aR�mui;X)�s��a�hɌ�[�%�Ġ"!�̎�� vN�
K�e���]���,-��%YZ3	�eV�юV�K3�%۬jI��D
k����!ڑR�X�Y�V�ƪ�2[�c��[;�s&�unL�*6Kb�<͉�%*�4�v8��N��Kk-A*�v�n��v��Fɒ[+!ٍEki�&!`R�-�Y�%�LU����R�5έ�-�c��b���iZf�V3%�5�i�j�J4�%�y����m�T�K"-i�����
CPҬ�%��ͪ��b��9�X\Z���H+%If�ʉ*k� -"F�0����\H1���2���n��9�f������9�ƹ���lg��f�%���Ԓ�vZ�2�Ԓ���Ćd���6�+IE��QB�%Ŭ*pnAU�LaHZ՚�ņ�D�U�����Wޞ��\'�PN�b-aIHW�ʒs� ��"&i���!�$����M>���'|����Q��[S��b�d�cV���M�Z�,3���,���L�֘YN+N��x�ǿ���������fK��6O�B���i�I�JXr� (iV���ͪ���{�{���o��mߜ�;.a����"	I��t!��� H�"&���h��e���{���w���Kk�k�n�8���;H٬*�Z�ۭ�f�5�[&�rc�Hl��4���3?��_����a�qȒ������d����h7줥d�i���ii9�I�!�ч������=gS�Zi�Ov�l��J�U��TiZ��Z�jP%Y��L�FIV��i���{>�7WR�b$�E��&�8M���b���d��l��3;A�6U��� ���ڷ��5?������i%����5K���T�����F.#�v;	K�5-ىYk'�$����o�lCZCP1�uQe@k�e�4���Ę[r�����U�Tm�i��V�f�t��aDL ªU�r:�r�I-`,�lu]�0���f�Ds2�U5CZ
��V*�Y��֬�(!Y��f�5ii1�,9-;�EZrZ���4��N��[cI�=-U˺�ɕ͐�yy�$��HWCҤ1�"U�i��V`�Ҫ4s^ش�DS�Pa����k�4��Y��s����ٵT��契��i�vB��sZ-�a�Z����'m�����$�����k�+��d��ۭ�NZ)�����J��F.����ָ���f��K�iͤ�4�ܚ�3π�BZr���veU$;s`��-�f-;¨	(!m�4-�����[cI q.fU�2�T)� �Ŷ��r$���QWJfUY�2��ؕILK�U�YҶ%-),iLZF	U��l�l���3Յ�[Ҡ�����v�v,i<V��d��	�fP�E�fɆ�Jm��)��%fI��ki�
(i�����eC��Fªl���iifU�hP�ke�ʒsIH��U9�v��Y�v��3r��D;��K�5Ҙ�vK�Ya���j��5���Z����ք��UJl��m�BUe�JH;��K�Bk;�b�+-��,)f
$����N�1#�2��:FN7�D�V9�Ҭ%���Z�����i��f'�V!�I�,�ڵ���Ғ�-�%��K��Z�B2��֒�ۭY;3ܚ���n�¬j�r�a-vj�j���n�Ҳ�ܨ+%k���NZZkR��l X�����v�
K�N�T��9f\�11��yi�*fZk���eK2K�i΍U5��Ae�U��Ӥ
�v���,b;W$��;/gK��1i� �5��M�5[��MU�d���f�DeF���fv%�ZN�s���Z;�11q��XK����Ĵ֖�Z��"��F2#.ͪB�i�KۦD�X2�arA�P68��j�i��"]��1��.��,i�b�59g�K(1ɒdK�#��9[J�l��К�"	���Nkث�Tf�]Kf��H٨�d-��$"�ZҌ�v;�5v;-��``ך��n�[Rh�$6
Hk%�iRai��"0UYҬ���fvkFk�s���X	��3Z�j��eg&	f3�V��Kka(HW��0(�
�PYrG�ڽ�w��rnVB�6+z�̃sc�)�6��*�΍�S�i󤊄�bqp���DkI�Xk,��֒iFn-a,�ȭ�ɚى��Z�I�Қf�Ǝ��7�����|�"-3�Q�ѫWc��9*��i�-1K6T�Z�֚�b����=������0��麶$��%��P"N{�%3=-桊��*zZF��¬`�ux㋷���km�(!�-iZ�I�v�dI9fi��5�j�Z���oIZ�LҺC�y��?���jm���4u5F��e��P5T%ٙ9�dC�E��j�r�T(��6rZ�vx��/�������Җ����Jk��U��ֲ�6ilR-�'����%�%YOKN�����~���v�5rZh�vZ���������HXKn-���h�h�V��v�bV@�N߾�㗾����l�Sܚ圭��ε��Y%�n����f�ܚ�f$-1˹��@��XrZq�����O���>~�{/{/6JHp�%��W!iV��4),�Y�U�v;-���Y18�"�굷'�����������WK¸��.�vc	D���iR,���X�T1h���x.}v��������>�';��n-�fiF´�4�\�Nki��YU$�%��4۸Қ�^�U���B;�����������O?�I�F� �B��l�������cHkJ%T�1��4�D����y�/?�����C~�Z~����D�1b��K�Y��ZZ�"��4��
��D�' J�:}�����O��~������;�UeIk�H�%�i�H��v2�l��FZZ֪fpJv3Z3��s-٭�����7���O��sxs��0(�Y��*#Ǫj,���射�vcTZ�6#T�L�9��UJfF٨
1��n�IŬ��P�윆 �$�!���I�v���ܕ��\���f�%Vj���a�4�nGs�Iͬ�J�u�X&�����ۭ�Z�5k�f��KvkFZq��h6KF�A�v��� v{I+��� ;f�%ʹ�v;f�*YN;u]�ǪB�XֺnM�553�Pn/C���Q�Q�Z-e��ZI�*f���͹��V�T5���Y�U�8��W�i�8��<��0#zZa��4�5k��3iG2&���8�]ڠ@���h�[�J����֚���ڹ�N�Q�¦�!�ܒ�+!�3i��e$���&��vfڵ�U�ˍ\���%D�U5���8�ZP�Y93Ĥ�T�Nf(m��]0u"�m�V�[�v��Nk)mЮ�A�!,I$KNc���[�%���AkH�%���%����f��j��d�Z�i�^[b�[=ͭYnn�n�Y�1�Z�lV�4�"�Pf8��n%;-ų�����lvk	U�4�9�h-%�D%&�l�D`$V���V�E��9�UE���,��$KΑ6K1[U!!i���"-i�Ĭ���n-�5��^;[Jkn�qi;���)Uk�5��ڵ6Z��Hv�����(�̨�0T-h��n�ha6r�TCiF	I�Z ���`p��u�ŌHu��:��xz"X�*k	$A,U�U�r��v2k��T���n��RYrk̔,�5αv�YkpZS����1j6�4v��[kIk��!�*F�D�����Ғ�ǳKC�T,�֚�HŪ���䊡 bR�2K�h͹iU$�k-�gUX)Ph)�$KR�XK�������m�j�v��0�K�Z#�$�\Xڭ�5���\�4��͖�j���*f0۵�YU�]�z̻˯C��Z4C�LBKl���,���F.��"0�V���Jz̚�HZ�J�	�x�'ϑ	�u�����
-�0+����a�Be�UZ�s+]*����-_�|��V�$&�0��B1If��i�֎���փ���"]1�X������ɿ��ʭ�� 3k�h��,B2H��P�UY��f���Y�ȅ%v;��K�w~t�_N�:��bVk�1��H�b�Ґְ۩�m�i�n�$&I���%a�De{��K��x�N�8>��vf+�$$�I3"L����!�	;w�A����Rkz����������l��f�f��L;�0�iI�]k�YZc���� i���J�NZ΅�g}�֟_}{g���$P�� iVeT��ZNc]��"3Z[&����s�>_]�\5!�,	�i���,�I-#�T)��*�/
�d��֎�V������o��ځf��Z�9�Ҭݮ�h;��f�����К%MOۍ�^kiG��NZ��_>��_�����&1��sn%m�kIk%H�fif	�[S]���f\���&m������?��_?���۳�s��A%�p;Z��Vǀ��k'iP i�����/y���}?}�'�����Ů+�Kf�R5��\�[U����D��x9%�Re����K������7�n���i�d��%i-�6;1�ZN�В4����.Q�Lua�l-���k/{�e����n��ß��R�Pu���b�sPn3�3s�Q�B*6J�'Y��y�{/{��~y뛇ubW晪�v�s�(f�hN���چ��f����V���X�Z�UE���s"/~��~𽿹����7�X��R�줥d��,M;�ڵ��Ւ�vKk�3�H��T��������w�ɣ�;UJՠJ���58��*�k5UJf��g#B̤vJ���Ҷ���'���|w�Yi�*m9�������ƌD+����i�l���s+�%�h�Zb?��7�������n�RZ������F�J�NZ��R�ډI�����d���vn�ƹf������]}��-�Fn�4ۭ$�$�ݲ�k-5C�n�%l97�D��N��4��nI���n-f��#mvN狤He�XU.f�z,�&�9/�(��&Y�Tkp,9�i;�Ė�$��r�* M�.�i�R�Ε�N1�UE(f��slՅ�5k��5S�f��Y�i�@���Zk3Kk'ͱ]�XK���Y{9�Қ�4H�$3��4K�Q� i$Te$3�eA%&�[FkM�q*cɒcF.-̪"]Y+�Z����r�R�v����˭$KNc�1ە��I�]a��ڭU5�UZÌE��T����Nk1�s�����Jۭ�He&�2k�Ae֪VҬEkl�h����4=��h��FN����FiÚ��0���[�Z��$=#5���C1S����ZK��n�1�B��YkcU$;3�ͪH���%8�Tf�5J��bF�����r��vr{�6{����ŦJ������J*��k��mWEkkI�֚��nIZ�kNk�Ӛ�Z�햴$�d��v�Xr�����Z"aL�]�;d����
�[I���4â�mV���9g�mV����ɩ�*H̴���=w}���WfI���i���]s��ْR�T�v��^�6�֜��SKl(�x6�:���Qo���~�W��;�5�Zn�[b�^+٭���֒�J���R�Z���J�1K���5����oo��i�ş���5���ݕ�U����K�.��U��y�[-5C��L�Z�E�3�X�a��V�3�;����w�|�׿��?����vǗ7}��7ͪ�;�L�S��ۋ�V�Y�-�8߬hm�!�`�9%���榯����������?��~v������g6����u���c-<H1K��͒��[K��fX�Zhy��u������?�ӏ_�>        [remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://bk5i5c0imext6"
path="res://.godot/imported/card_back_128.png-6bd0e362e6d738e68d1a35ca01ae189c.ctex"
metadata={
"vram_texture": false
}
       MIT License 

Copyright (c) 2013-2022 Niels Lohmann

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
            [configuration]

entry_symbol = "webrtc_extension_init"
compatibility_minimum = 4.1

[libraries]

linux.debug.x86_64 = "lib/libwebrtc_native.linux.template_debug.x86_64.so"
linux.debug.x86_32 = "lib/libwebrtc_native.linux.template_debug.x86_32.so"
linux.debug.arm64 = "lib/libwebrtc_native.linux.template_debug.arm64.so"
linux.debug.arm32 = "lib/libwebrtc_native.linux.template_debug.arm32.so"
macos.debug = "lib/libwebrtc_native.macos.template_debug.universal.dylib"
windows.debug.x86_64 = "lib/libwebrtc_native.windows.template_debug.x86_64.dll"
windows.debug.x86_32 = "lib/libwebrtc_native.windows.template_debug.x86_32.dll"
android.debug.arm64 = "lib/libwebrtc_native.android.template_debug.arm64.so"
android.debug.x86_64 = "lib/libwebrtc_native.android.template_debug.x86_64.so"
ios.debug.arm64 = "lib/libwebrtc_native.ios.template_debug.arm64.dylib"
ios.debug.x86_64 = "lib/libwebrtc_native.ios.template_debug.x86_64.simulator.dylib"

linux.release.x86_64 = "lib/libwebrtc_native.linux.template_release.x86_64.so"
linux.release.x86_32 = "lib/libwebrtc_native.linux.template_release.x86_32.so"
linux.release.arm64 = "lib/libwebrtc_native.linux.template_release.arm64.so"
linux.release.arm32 = "lib/libwebrtc_native.linux.template_release.arm32.so"
macos.release = "lib/libwebrtc_native.macos.template_release.universal.dylib"
windows.release.x86_64 = "lib/libwebrtc_native.windows.template_release.x86_64.dll"
windows.release.x86_32 = "lib/libwebrtc_native.windows.template_release.x86_32.dll"
android.release.arm64 = "lib/libwebrtc_native.android.template_release.arm64.so"
android.release.x86_64 = "lib/libwebrtc_native.android.template_release.x86_64.so"
ios.release.arm64 = "lib/libwebrtc_native.ios.template_release.arm64.dylib"
ios.release.x86_64 = "lib/libwebrtc_native.ios.template_release.x86_64.simulator.dylib"
             extends Node

var Players = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
  GST2   �   �      ����               � �        �  RIFF�  WEBPVP8L�  /������!"2�H�$�n윦���z�x����դ�<����q����F��Z��?&,
ScI_L �;����In#Y��0�p~��Z��m[��N����R,��#"� )���d��mG�������ڶ�$�ʹ���۶�=���mϬm۶mc�9��z��T��7�m+�}�����v��ح�m�m������$$P�����එ#���=�]��SnA�VhE��*JG�
&����^x��&�+���2ε�L2�@��		��S�2A�/E���d"?���Dh�+Z�@:�Gk�FbWd�\�C�Ӷg�g�k��Vo��<c{��4�;M�,5��ٜ2�Ζ�yO�S����qZ0��s���r?I��ѷE{�4�Ζ�i� xK�U��F�Z�y�SL�)���旵�V[�-�1Z�-�1���z�Q�>�tH�0��:[RGň6�=KVv�X�6�L;�N\���J���/0u���_��U��]���ǫ)�9��������!�&�?W�VfY�2���༏��2kSi����1!��z+�F�j=�R�O�{�
ۇ�P-�������\����y;�[ ���lm�F2K�ޱ|��S��d)é�r�BTZ)e�� ��֩A�2�����X�X'�e1߬���p��-�-f�E�ˊU	^�����T�ZT�m�*a|	׫�:V���G�r+�/�T��@U�N׼�h�+	*�*sN1e�,e���nbJL<����"g=O��AL�WO!��߈Q���,ɉ'���lzJ���Q����t��9�F���A��g�B-����G�f|��x��5�'+��O��y��������F��2�����R�q�):VtI���/ʎ�UfěĲr'�g�g����5�t�ۛ�F���S�j1p�)�JD̻�ZR���Pq�r/jt�/sO�C�u����i�y�K�(Q��7őA�2���R�ͥ+lgzJ~��,eA��.���k�eQ�,l'Ɨ�2�,eaS��S�ԟe)��x��ood�d)����h��ZZ��`z�պ��;�Cr�rpi&��՜�Pf��+���:w��b�DUeZ��ڡ��iA>IN>���܋�b�O<�A���)�R�4��8+��k�Jpey��.���7ryc�!��M�a���v_��/�����'��t5`=��~	`�����p\�u����*>:|ٻ@�G�����wƝ�����K5�NZal������LH�]I'�^���+@q(�q2q+�g�}�o�����S߈:�R�݉C������?�1�.��
�ڈL�Fb%ħA ����Q���2�͍J]_�� A��Fb�����ݏ�4o��'2��F�  ڹ���W�L |����YK5�-�E�n�K�|�ɭvD=��p!V3gS��`�p|r�l	F�4�1{�V'&����|pj� ߫'ş�pdT�7`&�
�1g�����@D�˅ �x?)~83+	p �3W�w��j"�� '�J��CM�+ �Ĝ��"���4� ����nΟ	�0C���q'�&5.��z@�S1l5Z��]�~L�L"�"�VS��8w.����H�B|���K(�}
r%Vk$f�����8�ڹ���R�dϝx/@�_�k'�8���E���r��D���K�z3�^���Vw��ZEl%~�Vc���R� �Xk[�3��B��Ğ�Y��A`_��fa��D{������ @ ��dg�������Mƚ�R�`���s����>x=�����	`��s���H���/ū�R�U�g�r���/����n�;�SSup`�S��6��u���⟦;Z�AN3�|�oh�9f�Pg�����^��g�t����x��)Oq�Q�My55jF����t9����,�z�Z�����2��#�)���"�u���}'�*�>�����ǯ[����82һ�n���0�<v�ݑa}.+n��'����W:4TY�����P�ר���Cȫۿ�Ϗ��?����Ӣ�K�|y�@suyo�<�����{��x}~�����~�AN]�q�9ޝ�GG�����[�L}~�`�f%4�R!1�no���������v!�G����Qw��m���"F!9�vٿü�|j�����*��{Ew[Á��������u.+�<���awͮ�ӓ�Q �:�Vd�5*��p�ioaE��,�LjP��	a�/�˰!{g:���3`=`]�2��y`�"��N�N�p���� ��3�Z��䏔��9"�ʞ l�zP�G�ߙj��V�>���n�/��׷�G��[���\��T��Ͷh���ag?1��O��6{s{����!�1�Y�����91Qry��=����y=�ٮh;�����[�tDV5�chȃ��v�G ��T/'XX���~Q�7��+[�e��Ti@j��)��9��J�hJV�#�jk�A�1�^6���=<ԧg�B�*o�߯.��/�>W[M���I�o?V���s��|yu�xt��]�].��Yyx�w���`��C���pH��tu�w�J��#Ef�Y݆v�f5�e��8��=�٢�e��W��M9J�u�}]釧7k���:�o�����Ç����ս�r3W���7k���e�������ϛk��Ϳ�_��lu�۹�g�w��~�ߗ�/��ݩ�-�->�I�͒���A�	���ߥζ,�}�3�UbY?�Ӓ�7q�Db����>~8�]
� ^n׹�[�o���Z-�ǫ�N;U���E4=eȢ�vk��Z�Y�j���k�j1�/eȢK��J�9|�,UX65]W����lQ-�"`�C�.~8ek�{Xy���d��<��Gf�ō�E�Ӗ�T� �g��Y�*��.͊e��"�]�d������h��ڠ����c�qV�ǷN��6�z���kD�6�L;�N\���Y�����
�O�ʨ1*]a�SN�=	fH�JN�9%'�S<C:��:`�s��~��jKEU�#i����$�K�TQD���G0H�=�� �d�-Q�H�4�5��L�r?����}��B+��,Q�yO�H�jD�4d�����0*�]�	~�ӎ�.�"����%
��d$"5zxA:�U��H���H%jس{���kW��)�	8J��v�}�rK�F�@�t)FXu����G'.X�8�KH;���[             [remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://cnw86gkjchvt5"
path="res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex"
metadata={
"vram_texture": false
}
                [remap]

path="res://.godot/exported/133200997/export-5e376aae3f75d46d1c418bca5034412e-Net.scn"
[remap]

path="res://.godot/exported/133200997/export-2887990fe5351906ea90a90f098e9db7-p_hero.scn"
             list=Array[Dictionary]([{
"base": &"RefCounted",
"class": &"Lobby",
"icon": "",
"language": &"GDScript",
"path": "res://tutorial/Lobby.gd"
}])
 <svg height="128" width="128" xmlns="http://www.w3.org/2000/svg"><rect x="2" y="2" width="124" height="124" rx="14" fill="#363d52" stroke="#212532" stroke-width="4"/><g transform="scale(.101) translate(122 122)"><g fill="#fff"><path d="M105 673v33q407 354 814 0v-33z"/><path fill="#478cbf" d="m105 673 152 14q12 1 15 14l4 67 132 10 8-61q2-11 15-15h162q13 4 15 15l8 61 132-10 4-67q3-13 15-14l152-14V427q30-39 56-81-35-59-83-108-43 20-82 47-40-37-88-64 7-51 8-102-59-28-123-42-26 43-46 89-49-7-98 0-20-46-46-89-64 14-123 42 1 51 8 102-48 27-88 64-39-27-82-47-48 49-83 108 26 42 56 81zm0 33v39c0 276 813 276 813 0v-39l-134 12-5 69q-2 10-14 13l-162 11q-12 0-16-11l-10-65H447l-10 65q-4 11-16 11l-162-11q-12-3-14-13l-5-69z"/><path d="M483 600c3 34 55 34 58 0v-86c-3-34-55-34-58 0z"/><circle cx="725" cy="526" r="90"/><circle cx="299" cy="526" r="90"/></g><g fill="#414042"><circle cx="307" cy="532" r="60"/><circle cx="717" cy="532" r="60"/></g></g></svg>
             �۔oZ�ld   res://Mtprtc/Net.tscn�BGj�`�%   res://Mtprtc/p_hero.tscnRf���R   res://texture/background4.png�gn��ѹ+   res://texture/card_back_128.png�,���O   res://icon.svg         res://webrtc/webrtc.gdextension
ECFG
      application/config/name         mtpweb     application/run/main_scene          res://Mtprtc/Net.tscn      application/config/features(   "         4.1    GL Compatibility       application/config/icon         res://icon.svg     autoload/GameManager          *res://GameManager.gd   "   display/window/size/viewport_width         #   display/window/size/viewport_height      X     display/window/stretch/mode         viewport#   rendering/renderer/rendering_method         gl_compatibility*   rendering/renderer/rendering_method.mobile         gl_compatibility    