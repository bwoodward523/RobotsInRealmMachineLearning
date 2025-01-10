import random
import socket
import struct
import time
import select
from Packets.PacketReader import PacketReader
from Packets.PacketTypes import PacketTypes
from Packets.incoming import *
from Packets.outgoing import *
from Packets.Packet import *
move_directions = ["move_left", "move_up", "move_right", "move_down", "move_none", "shoot", "ability"] #"move_none" for no movement

class Client:
    def __init__(self):
        self.buffer = b""
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
        self.observations = {
            "position": (0.0,0.0),
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

                        print("Data:", data)
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

def process_client_data(client, data):
    #Get the latest Packet ID from the client buffer
    data = data.decode()
    #print(data)
    packet_id = int(data[:3])
    print("pkt id ", packet_id, "data:", data[3:])
    data = data[3:]
    if packet_id == PacketTypes.ObsHealth:
        client.observations["health"] = int(data)
        print(client.observations)

    if packet_id == PacketTypes.ObsPosition:
        print("data pre split", data)
        x, y = data.split(" ")
        client.observations["position"] = (float(x), float(y))
        print(client.observations)

    # Parse the received observation data
    #client.observations = parse_observations(data)

    # Compute the best action based on observations


def build_observations(data):
    observations = {}
    data = data.split("\n")
    print(data)
    if data:
        observations = data
        #for d in data:
           # key, value = d.split(":")
            #[key] = value
    print(observations)
    return observations
def compute_action(observations, client):
    #health = observations.get("health")
    #position = observations.get("position")

    # Implement RL algorithm here

    #Old action for testing
    action = random_choice_extra(client)
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
            message = "shoot" + " " + str(random.random() * 360.0)
            #print(f"Sent message: {message}")
    return message

if __name__ == "__main__":
    start_server()

    # client = connections[conn]
    # try:
    #     header = conn.recv(5)
    #     if len(header) == 0:
    #         print("Error server send no bytes")
    #         del connections[conn]
    #         conn.close()
    #         continue
    #
    #     while len(header) < 5:
    #         header += conn.recv(5 - len(header))
    #
    #     packet_id = header[4]
    #     packet_len = struct.unpack("!i", header[:4])[0]
    #
    #     left_to_read = packet_len - 5
    #     data = bytearray()
    #
    #     while left_to_read > 0:
    #         try:
    #             buf = conn.recv(left_to_read)
    #             if not buf:  # Connection closed by client
    #                 print("Client closed the connection.")
    #                 del connections[conn]
    #                 conn.close()
    #                 return None
    #             data.extend(buf)
    #             left_to_read -= len(buf)
    #             print(left_to_read)
    #         except BlockingIOError:
    #             # No data available at the moment, try again later
    #             continue
    #
    #     if left_to_read == 0:
    #         packet = Packet(header, data, packet_id)
    #         response = process_client_data(client, packet)
    #         conn.send(response)

    # Remove the processed packet from the buffer
    # else:
    #     print(f"Connection closed by client: {conn.getpeername()}")
    #     del connections[conn]
    #     conn.close()