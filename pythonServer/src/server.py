import socket
import struct

import rsa

from src.Packets.Packet import Packet
from src.Packets.PacketTypes import PacketTypes
from src.Packets.outgoing import *

publicKey = rsa.PublicKey.load_pkcs1_openssl_pem(
    b"-----BEGIN PUBLIC KEY-----\nMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDTa2VXtjKzQ8HO2hCRuXZPhezl0HcWdO0QxUhz1b+N5xJIXjvPGYpawLnJHgVgjcTI4dqDW9sthI3hEActKdKV6Zm/dpPMuCvgEXq1ajOcr8WEX+pDji5kr9ELH0iZjjlvgfzUiOBI6q4ba3SRYiAJFgOoe1TCC1sDk+rDZEPcMwIDAQAB\n-----END PUBLIC KEY-----")
# Load the RSA private key
private_key = (b"""-----BEGIN RSA PRIVATE KEY-----
MIICXgIBAAKBgQDTa2VXtjKzQ8HO2hCRuXZPhezl0HcWdO0QxUhz1b+N5xJIXjvP
GYpawLnJHgVgjcTI4dqDW9sthI3hEActKdKV6Zm/dpPMuCvgEXq1ajOcr8WEX+pD
ji5kr9ELH0iZjjlvgfzUiOBI6q4ba3SRYiAJFgOoe1TCC1sDk+rDZEPcMwIDAQAB
AoGBAKB+m81NFAoAOuVjp0Zoy0atPVxst6rFkp2zlj/RGPyJWNi1KKQcGGqyeZcS
gjR9CtEQm0gy+B0Czo33E+uWHzSrh80lvmYxeHVgPfnyKf1bfCRvYdmm5YsWnvhV
Dsif5kC8BWfH9wxdmY3Li7UC38kzcqzYAbpMhBDFMtDh/xIJAkEA6uwmAbXk3sth
9GibetDdudJDSk2Xbf10GF2aiRlfHeKCj5OPwR/3rI0RBVcuA9LAPuYgWIJHEvWa
goQmjFI6RwJBAOZjaqd8ljbmhDEsQBrIxU2IBRLND8hJlmH/dSfkfq6GaptYtLdf
o7/caVCIDdmotNsmcUfiGIM9GR55DI0GGLUCQQCNtJzIc1v3OF+B+oeu8caNjFOi
wmMRqc0Z1XyeLnu9nyB6Utxn9kyD/SPDQO80xy/HwTDJsuwEd7oX+Hb4NbGJAkAC
dfVhrJb+JyAqVkqo/pP87AMB3GbawM52ZYAe2PXxb0YcOqpTexYIqpYFYi6jsIWe
AZ8cIXIZlMF77dcQeowxAkEAgCEggW6P+y0GKQDazGQiFEbq/tmu7vw/YqTnmEbP
aaLMuU/Y0INAj0MidC1vxVhS69+ceUK9WDxuAGULPYDYNw==
-----END RSA PRIVATE KEY-----""")
def rsa_decrypt(packet):
    return rsa.decrypt(packet, private_key)

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

                decrypted_data = rsa_decrypt(data)
                packet = Packet(header, decrypted_data, packet_id)
                print(f"Received packet with ID: {packet.ID}")
                if packet.ID == PacketTypes.Move:
                    p = Move()
                    p.read(packet)
                    p.PrintString()


if __name__ == "__main__":
    start_server()