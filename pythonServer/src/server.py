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

def start_server(host='127.0.0.1', port=65432):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind((host, port))
        s.listen()
        print(f"Server listening on {host}:{port}")
        s.setblocking(False)
        connections = [s]
        connected_clients = []

        move_idx = 0
        while True:
            readable, writable, exceptional = select.select(connections, connections, connections)
            for conn in readable:
                if conn is s:
                    client_conn, addr = s.accept()
                    print(f"Connected by {addr}")
                    client_conn.setblocking(False)
                    connections.append(client_conn)
                    connected_clients.append(Client())
                else:
                    try:
                        data = conn.recv(1024)
                        if not data:
                            print("Connection lost, closing connection.")
                            connections.remove(conn)
                            conn.close()
                    except ConnectionResetError:
                        print("Connection reset by peer, closing connection.")
                        connections.remove(conn)
                        conn.close()
            #Make the player move in square
            move_idx += 1
            if move_idx % 4 == 0:
                move_idx = 0

            for conn in writable:
                if conn is not s:
                    try:
                        message = move_directions[move_idx]
                        message_length = len(message)
                        header = struct.pack("!iB", message_length + 5, 1)
                        packet = header + message.encode()
                        conn.send(packet)
                        print(f"Sent message: {message}")
                        time.sleep(.1)
                    except (OSError, ValueError):
                        print("Connection error, closing connection.")
                        if conn in connections:
                            connections.remove(conn)
                        conn.close()

            for conn in exceptional:
                print("Handling exceptional condition for", conn.getpeername())
                connections.remove(conn)
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