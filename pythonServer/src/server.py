import random
import socket
import struct
import time
import select

move_directions = ["move_left", "move_up", "move_right", "move_down", "move_none", "shoot", "ability"] #"move_none" for no movement

class Client:
    def __init__(self):
        self.position = (0, 0)
        self.health = 0
        self.speed = 0
        self.can_ability = False # Ability flag
        self.move_direction = "move_none"
        self.shoot_angle = 0
        self.projectile_positions = []
        self.projectile_velocities = []
        self.enemy_positions = []
        self.in_realm = False
        self.ability_range = 1
        self.last_reward = 0  # Reward to be used for RL
        self.observation = {
            "position": self.position,
            "health": self.health,
            "move_direction": self.move_direction,
            "shoot_angle": self.shoot_angle,
            "projectile_positions": self.projectile_positions,
            "projectile_velocities": self.projectile_velocities,
            "enemy_positions": self.enemy_positions,
        } # Observation to be used for RL

def start_server(host='127.0.0.1', port=65432):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind((host, port))
        s.listen()
        print(f"Server listening on {host}:{port}")
        s.setblocking(False)
        connections = {}
        move_idx = 0

        while True:
            readable, writeable, exceptional = select.select([s] + list(connections.keys()), list(connections.keys()), [])
            for conn in readable:
                if conn is s:
                    client_conn, addr = s.accept()
                    print(f"Connected by {addr}")
                    client_conn.setblocking(False)
                    connections[client_conn] = Client()
                else:
                    try:
                        data = conn.recv(1024)
                        if not data:
                            print(f"Connection closed by client: {conn.getpeername()}")
                            del connections[conn]
                            conn.close()
                    except ConnectionResetError:
                        print("Connection reset by peer, closing connection.")
                        del connections[conn]
                        conn.close()

            move_idx += 1
            if move_idx % 4 == 0:
                move_idx = 0

            for conn in writeable:
                if conn not in connections:
                    continue
                client = connections[conn]
                try:
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
                        message = "shoot" + " " + str(random.randint(0, 360))
                        print(f"Sent message: {message}")
                    if not message == "":
                        message_length = len(message)
                        header = struct.pack("!iB", message_length + 5, 1)
                        packet = header + message.encode()
                        conn.send(packet)
                        print(f"Sent message: {message}")
                        time.sleep(.01)
                except (OSError, ValueError):
                    print("Connection error, closing connection.")
                    if conn in connections:
                        del connections[conn]
                    conn.close()

            for conn in exceptional:
                print("Handling exceptional condition for", conn.getpeername())
                if conn in connections:
                    del connections[conn]
                conn.close()

def process_client_data(client, data):
    # Parse the received observation data
    observations = parse_observations(data)

    # Compute the best action based on observations
    action = compute_action(observations)

    # Prepare the response packet with action
    message_length = len(action)
    header = struct.pack("!iB", message_length + 5, 1)  # Example header
    packet = header + action.encode()

    return packet

def parse_observations(data):
    observations = {}
    data = data.split("\n")
    for d in data:
        key, value = d.split(":")
        observations[key] = value
    return observations
def compute_action(observations):
    action = ""
    # Implement RL algorithm here
    return action
if __name__ == "__main__":
    start_server()