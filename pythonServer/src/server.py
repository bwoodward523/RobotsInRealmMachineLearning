import socket
import struct


def start_server(host='127.0.0.1', port=65432):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind((host, port))
        s.listen()
        print(f"Server listening on {host}:{port}")
        conn, addr = s.accept()
        with conn:
            print(f"Connected by {addr}")
            while True:
                header = conn.recv(5)
                if len(header) == 0:
                    print("Client sent 0 bytes, closing connection.")
                    break

                while len(header) != 5:
                    header += conn.recv(5 - len(header))

                packet_id = header[4]
                expected_packet_length = struct.unpack("!i", header[:4])[0]
                left_to_read = expected_packet_length - 5
                data = bytearray()

                while left_to_read > 0:
                    buf = conn.recv(left_to_read)
                    data += buf
                    left_to_read -= len(buf)

                packet = Packet(header, data, packet_id)
                print(f"Received packet with ID: {packet.packet_id}, Data: {packet.data}")

if __name__ == "__main__":
    start_server()