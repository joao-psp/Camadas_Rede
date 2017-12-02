require 'socket'
include Socket::Constants

ip="localhost"
port=20003
client = Socket.new(AF_INET, SOCK_STREAM,0)
client.connect(Socket.sockaddr_in(port, ip))
while(TRUE)
    msg = "Viu Joao Pedro!\n"

    client.send(msg,0)
    print("Enviado.")
    resp = client.recv(4096)

    print("Resposta recebida: " + resp)
end
client.close()
