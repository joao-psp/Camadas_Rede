require 'socket'
include Socket::Constants

ip = "localhost"
port = 20005
server = Socket.new(AF_INET, SOCK_STREAM,0)
server.bind(Socket.sockaddr_in(port, ip))
server.listen(1)
connection, client = server.accept()
while(TRUE)
    segment = connection.recv(4096)

    print("Mensagem: " + segment)

    connection.send("Resposta enviada.\n",0)
end
connection.close()
