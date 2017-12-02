import socket

ip="localhost"
port=20003
client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
client.connect((ip, port))
while(True):
    msg = "Viu Joao Pedro!\n"

    client.send(msg)
    print("Enviado.")
    resp = client.recv(4096)

    print("Resposta recebida: " + resp)

client.close()
