import random
import socket
import struct
import time
import math
import select
import gym
from gym import spaces
import numpy as np
from Packets.Packet import *
move_directions = ["move_left", "move_up", "move_right", "move_down", "move_none", "shoot", "ability"] #"move_none" for no movement


class RotMGEnvironment(gym.Env):
    def __init__(self):
        super(RotMGEnvironment, self).__init__()

        # Action space (discrete or continuous depending on your game)
        self.action_space = spaces.Discrete(5)  # Example: [Move Left, Move Right, Move Up, Move Down, Shoot]

    def step(self, action):
        # Apply the action to the game
        state, reward, done, info = self._apply_action(action)
        return state, reward, done, info

    def reset(self):
        # Reset the environment and return the initial state
        return self._get_initial_state()

    def _apply_action(self, action):
        # Send the action to the game (your project)
        # Get updated observations and reward
        state = self._get_state()
        reward = self._calculate_reward()
        done = self._check_game_over()
        info = {}
        return state, reward, done, info

    # def _get_state(self):
    #     # Gather observations (player position, health, etc.)
    #     return normalized_observation_vector

    def _calculate_reward(self):
        # Define rewards (e.g., surviving, damaging enemies, picking up quests)
        reward = 0
        return reward

    # def _check_game_over(self):
    #     # Check if the game is over
    #     return game_over_flag
    def _get_initial_state(self):
        pass


def encode_no_walk_tiles(player_position, no_walk_tiles, world_size=2048, grid_radius=15):
        grid_size = grid_radius * 2 + 1  # 31x31 grid
        grid = [[0 for _ in range(grid_size)] for _ in range(grid_size)]

        # Player's position in the world
        #print("Player position: ", player_position)
        player_x, player_y = player_position

        for tile in no_walk_tiles:
            # Denormalize tile position back to world space
            world_x = tile[0] * world_size
            world_y = tile[1] * world_size

            # Convert world position to local position relative to the player
            local_x = world_x - player_x
            local_y = world_y - player_y

            # Translate local position into grid indices
            grid_x = int(local_x + grid_radius)
            grid_y = int(local_y + grid_radius)

            # Ensure the tile is within the grid bounds
            if 0 <= grid_x < grid_size and 0 <= grid_y < grid_size:
                grid[grid_y][grid_x] = 1  # Mark as non-walkable

        # Flatten the 2D grid into a 1D list
        flattened_grid = [tile for row in grid for tile in row]
        return flattened_grid


class Client:
    def __init__(self):
        self.buffer = b""
        self.position = (0, 0)
        self.health = 0
        self.speed = 0
        self.can_ability = False # Ability flag
        self.move_direction = "move_none"
        self.shoot_angle = 0
        # self.projectile_positions = []
        # self.projectile_velocities = []
        # self.enemy_positions = []
        self.in_realm = False
        self.ability_range = 1
        self.MAX_PROJECTILES = 30
        self.MAX_ENEMIES = 10
        self.MAX_BAGS = 5
        self.MAX_NO_WALK_TILES = 961 #This is how many tiles the client will load around itself. The player loads 31x31 tiles around itself. 31*31 = 961
        #We process the incoming tile's world positions and localize them around the player. We then send the localized positions to the AI.
        self.observations = {
            "position": (0.0,0.0),
            "health": self.health, #Will be normalized before its sent
            "move_direction": self.move_direction,
            "shoot_angle": self.shoot_angle,
            "projectiles": None,# First is dmg (dmg/playerMaxHP) then sorted into a pair of Vector2 and Vector2 for each projectile. (x,y) and (dx,dy)
            "enemy_positions+health": [], #Enemy health will be normalized before its sent
            "quest_position": (0.0,0.0),
            "bags": [],
            "noWalkTiles": []
        }
        self.observation_vector = []# Observation to be used for RL

        # Convert our observations to a vector for the RL model to gain sample data size
        self.observation_vector = self.observations_to_vector()
        self.env = RotMGEnvironment()
        # Observation space (example dimensions)
        self.env.observation_space = spaces.Box(low=0, high=1, shape=(len(self.observation_vector),), dtype=np.float32)

        self.current_state = self.env.reset()

        #Convert our observations to a vector for the RL model
    def observations_to_vector(self):
            vector = [
                *self.observations["position"],
                self.observations["health"],
                *self.observations["quest_position"],
            ]

            #Add projectiles
            projectiles = self.observations["projectiles"] or []
            for proj in projectiles[:self.MAX_PROJECTILES]:
                vector.extend(proj)
            #pad 0s if there are less than MAX_PROJECTILES
            vector.extend([0] * 5 * (self.MAX_PROJECTILES - len(projectiles)))

            #Add enemies
            enemies = self.observations["enemy_positions+health"] or []
            for enemy in enemies[:self.MAX_ENEMIES]:
                vector.extend(enemy)
            #pad 0s if there are less than MAX_ENEMIES
            vector.extend([0] * 3 * (self.MAX_ENEMIES - len(enemies)))

            #Add bags
            bags = self.observations["bags"] or []
            for bag in bags[:self.MAX_BAGS]:
                vector.extend(bag)
            #pad 0s if there are less than MAX_BAGS
            vector.extend([0] * 2 * (self.MAX_BAGS - len(bags)))

            #Add no walk tiles
            no_walk_tiles = self.observations["noWalkTiles"] or []
            flattened_grid = encode_no_walk_tiles(self.observations["position"], no_walk_tiles)
            vector.extend(flattened_grid)

            return np.array(vector, dtype=np.float32)


def start_server(host='127.0.0.1', port=65432):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind((host, port))
        s.listen()
        print(f"Server listening on {host}:{port}")
        s.setblocking(False)
        connections = {}


        while True:
            readable, writeable, exceptional = select.select([s] + list(connections.keys()), list(connections.keys()), [])
            for conn in readable:
                if conn is s:
                    client_conn, addr = s.accept()
                    print(f"Connected by {addr}")
                    client_conn.setblocking(False)
                    connections[client_conn] = Client()
                else:
                    client = connections[conn]

                    try:
                        data = conn.recv(4096)
                        if not data:
                            print(f"Connection closed by client: {conn.getpeername()}")
                            del connections[conn]
                            conn.close()
                            continue
                        client.buffer += data
                        if conn not in connections:
                            continue

                        #print("Data:", data)
                        process_packets(client)
                        action = compute_action(client.observations, client)
                        send_action(conn, action)


                    except ConnectionResetError:
                        print("Connection reset by peer, closing connection.")
                        del connections[conn]
                        conn.close()


            for conn in exceptional:
                print("Handling exceptional condition for", conn.getpeername())
                if conn in connections:
                    del connections[conn]
                conn.close()
def send_action(conn, action):
    # Create a packet with the action
    message_length = len(action)
    header = struct.pack("!iB", message_length + 5, 1)  # Message type 1
    packet = header + action.encode()
    # time.sleep(.00321)
    conn.send(packet)

def process_packets(client):
    delimiter = b"\n"  # Each packet ends with a newline
    while b"\n" in client.buffer:
        packet, client.buffer = client.buffer.split(delimiter, 1)
        process_client_data(client, packet)
        #Send the observations to the AI
        client.observation_vector = client.observations_to_vector()
def process_client_data(client, data):
    #Get the latest Packet ID from the client buffer
    data = data.decode()
    #print(data)
    packet_id = int(data[:3])
    #print("pkt id ", packet_id, "data:", data[3:])
    data = data[3:]
    if packet_id == PacketTypes.ObsHealth:
        client.observations["health"] = float(data)
        #print(client.observations)

    if packet_id == PacketTypes.ObsPosition:
        #print("data pre split", data)
        x, y = data.split(" ")
        x, y = normalize_position(float(x), float(y))
        client.observations["position"] = (x, y)
        #print(client.observations)
    if packet_id == PacketTypes.ObsEnemyPositions:
        #print("data pre split", data)
        pairs = data.split(",")
        enemy_positions = []
        for pair in pairs:
            #print("pair" , pair)
            x, y, hp = pair.split(" ")
            x, y = normalize_position(float(x), float(y))
            enemy_positions.append((x, y, float(hp)))
        client.observations["enemy_positions+health"] = enemy_positions
    if packet_id == PacketTypes.ObsProjectiles:
        pairs = data.split(",")
        projectile_positions = []
        for pair in pairs:
            dmg, x, y, dx, dy = pair.split(" ")
            x, y = normalize_position(float(x), float(y))
            dx,dy = normalize_proj_velocity(float(dx), float(dy))
            projectile_positions.append((float(dmg), x, y, dx, dy))
        client.observations["projectiles"] = projectile_positions
        #print(client.observations["projectile_positions"])
    if packet_id == PacketTypes.ObsQuestPosition:
        x, y = data.split(" ")
        x, y = normalize_position(float(x), float(y))
        client.observations["quest_position"] = (x, y)
        #print(client.observations)

    if packet_id == PacketTypes.ObsDeath:
        client.in_realm = False
        print("Player died")

    if packet_id == PacketTypes.ObsBags:
        pairs = data.split(",")
        bags = []
        for pair in pairs:
            x, y = pair.split(" ")
            x, y = normalize_position(float(x), float(y))
            bags.append((x,y))
        client.observations["bags"] = bags
    if packet_id == PacketTypes.ObsNoWalkTiles:
        pairs = data.split(",")
        noWalkTiles = []
        for pair in pairs:
            x, y = pair.split(" ")
            x, y = normalize_position(float(x), float(y))
            noWalkTiles.append((x,y))
        client.observations["noWalkTiles"] = noWalkTiles
       # print("POS: ", client.observations["position"], " no walk tiles " ,client.observations["noWalkTiles"])
    #print(client.observations)
    #normalize_observation_data()
    #client.observations = parse_observations(data)

    # Compute the best action based on observations
def normalize_observation_data():
    pass
    # Normalize position data
    # Normalize health data
    # Normalize proj velocity data
MAP_SIZE = 2048
def normalize_position(x,y):
    return x/MAP_SIZE, y/MAP_SIZE
OBSERVED_MAX_PROJ_SPEED = 10
def normalize_proj_velocity(dx, dy):
    return dx/OBSERVED_MAX_PROJ_SPEED, dy/OBSERVED_MAX_PROJ_SPEED

def auto_aim(client):
    print(client.observations["enemy_positions+health"])
    if not client.observations["enemy_positions+health"]:
        return "move_none"  # No enemies to shoot at

    client_pos = client.observations["position"]
    closest_enemy = None
    min_distance = float('inf')

    for enemy_pos in client.observations["enemy_positions+health"]:
        distance = math.sqrt((enemy_pos[0] - client_pos[0]) ** 2 + (enemy_pos[1] - client_pos[1]) ** 2)
        if distance < min_distance:
            min_distance = distance
            closest_enemy = enemy_pos

    if closest_enemy is None:
        return "move_none"  # No enemies to shoot at

    dx = closest_enemy[0] - client_pos[0]
    dy = closest_enemy[1] - client_pos[1]
    angle = math.degrees(math.atan2(dy, dx))
    if angle < 0:
        angle += 360
    #print(f"Auto-aiming at {closest_enemy} with angle {angle:.2f}")
    return angle
def build_observations(data):
    observations = {}
    data = data.split("\n")
    #print(data)
    if data:
        observations = data
        #for d in data:
           # key, value = d.split(":")
            #[key] = value
    print(observations)
    return observations
def compute_action(observations, client):
    action = client.env.action_space.sample()
    next_state, reward, done, _ = client.env.step(action)

    if done:
        client.env.reset()

    return action

def random_choice():
    return random.choice(move_directions)


def random_choice_extra(client):
    move_idx = random.randint(0, 4)

    message = ""
    rand = random.randint(0, 10)
    if not client.in_realm:
            time.sleep(.6)
            message = "enter_realm"
            client.in_realm = True
    elif rand == 0:
            x = random.uniform(-100, 100) * client.ability_range * 5
            y = random.uniform(-100, 100) * client.ability_range * 5
            message = f"ability {x:.2f} {y:.2f}"
    elif 1 < rand < 6:
            message = move_directions[move_idx]
    elif rand >= 6:
            message = f"shoot {auto_aim(client)}"
            #print(f"Sent message: {message}")
    return message

if __name__ == "__main__":
    start_server()
