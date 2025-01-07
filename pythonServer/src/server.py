import random
import socket
import struct
import time
import select

move_directions = ["move_left", "move_up", "move_right", "move_down", "move_none", "shoot"] #"move_none" for no movement

class Client:
    def __init__(self):
        self.position = (0, 0)
        self.health = 0
        self.speed = 0
        #self.can_ability = False #can implement later
        self.move_direction = "move_none"
        self.shoot_angle = 0
        self.projectile_positions = []
        self.projectile_velocities = []
        self.enemy_positions = []
        self.in_realm = False

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
                client = connections[conn]
                try:
                    message = ""
                    rand = random.randint(0, 10)
                    if not client.in_realm:
                        time.sleep(.5)
                        message = "enter_realm"
                        client.in_realm = True
                    elif 0 < rand < 6:
                        message = move_directions[move_idx]
                    elif rand > 6:
                        message = "shoot" + " " + str(random.randint(0, 360))
                        print(f"Sent message: {message}")

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

                # #Listen to client
                # header = conn.recv(5)
                # if len(header) == 0:
                #     print("Client sent 0 bytes, closing connection.")
                #     break
                #
                # while len(header) != 5:
                #     header += conn.recv(5 - len(header))
                #
                # packet_id = header[4]
                # expected_packet_length = struct.unpack("!i", header[:4])[0]
                # left_to_read = expected_packet_length - 5
                # data = bytearray()
                #
                # while left_to_read > 0:
                #     buf = conn.recv(left_to_read)
                #     data += buf
                #     left_to_read -= len(buf)
                #     print("pakcet was received")
                #packet = Packet(header, data, packet_id)
                #print(f"Received packet with ID: {packet.ID}, Data: {packet.data}")

if __name__ == "__main__":
    start_server()