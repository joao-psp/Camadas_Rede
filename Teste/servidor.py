import socket

ip = "localhost"
port = 20005

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.bind((ip, port))
server.listen(1)
connection, client = server.accept()
while(True):
    segment = connection.recv(4096)

    print("Mensagem: " + segment)

    connection.send("Resposta enviada.\n")

connection.close()
