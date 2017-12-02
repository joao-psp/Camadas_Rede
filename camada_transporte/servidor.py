# -*- coding: utf-8 -*-
import socket
import logging
from aux import * # Biblioteca local, criada pelos autores maravilhosos

# Configuring logging filename='../log.txt'
logging.basicConfig(filename='../server_log.txt', format='%(asctime)s %(message)s' ,level=logging.INFO)

def udp_receive(ip="localhost", port=20006):
    # Comunicação através do protocolo UDP

    logging.info("CAM_TRANSP: iniciando comunicação UDP...")
    # Recebendo solicitação da camada física
    logging.info("CAM_TRANSP: Esperando o segmento...")
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind((ip, port))
    server.listen(1)
    connection, client = server.accept()
    segment = connection.recv(4096)
    logging.info("CAM_TRANSP: Segmento da camada de redes recebido.")

    # Desmonta o pacote
    # É necessário acprintrescentar o 0 pois em algum momento da transferencia realizou-se um shift para a direita
    src_port = int(segment[0:15] + "0", 2)
    dest_port = int(segment[16:31] + "0", 2)
    length = int(segment[32:47] + "0", 2)
    checksum = int(segment[48:63] + "0", 2)


    payload = segment[64:]
    # Realizando a verificação do checksum
    logging.info("CAM_TRANSP: Verificando checksum...")
    if(checksum <= len(payload) + 1):
        logging.info("CAM_TRANSP: Checksum correto. Mensagem recebida com sucesso.")
    else:
        logging.error("CAM_TRANSP: Checksum não confere. Comunicação abortada.")

    # Enviando payload para a camada de aplicação
    logging.info("CAM_TRANSP: Enviando segmento para a camada de aplicação...")
    ip_app="localhost"
    port_app=20007
    client_app = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    client_app.connect((ip_app, port_app))
    client_app.send(payload)
    logging.info("CAM_TRANSP: Payload enviado.")

    # Recebendo a resposta da requisição feita à camada de aplicação
    response = client_app.recv(4096)
    logging.info("CAM_TRANSP: Mensagem de resposta do servidor recebida!")
    # client_app.close()

    # Mandando a resposta da requisição de volta
    logging.info("CAM_TRANSP: Enviando a resposta de volta para a camada de rede...")
    connection.send(response)
    # connection.close()

def tcp_receive():
    # Comunicação através do protocolo TCP

    # Criando socket com a camada física
    ip = "localhost"
    port = 20006
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind((ip, port))
    server.listen(1)
    connection, client = server.accept()
    # THREE WAY HANDSHAKE
    # Receive a SYN, send an A CK and then receive the message to send to the app layer

    # Recebendo o SYN
    segment_syn = connection.recv(4096)
    logging.info("SYN recebido!")
    segment_syn = unmount_tcp_segment(segment_syn)

    # Enviando o ACK
    logging.info("CAM_TRANSP: Enviando o ACK...")
    # Tamanho da janela baseado em valores comuns de sistemas reais (no caso, Windows 2000 em Ethernet utiliza o valor 17520 bits)
    window = to_16_bits(17520)

    segment_ack = (segment_syn['src_port'] + segment_syn['dest_port'] + segment_syn['seq_number'] +
        segment_syn['ack_number'] + segment_syn['data_offset'] + segment_syn['reserved'] + segment_syn['urg'] +
        segment_syn['ack'] + segment_syn['psh'] + segment_syn['rst'] + segment_syn['syn'] + segment_syn['fin'] +
        window + segment_syn['checksum'] + segment_syn['urgent_pointer'] + segment_syn['options'] + segment_syn['padding'] + "Host: 192.168.15.29")
    connection.send(segment_ack)

    # Recebendo SYNACK
    logging.info("CAM_TRANSP: SYNACK recebido!")

    # Recebendo mensagem

    segment = connection.recv(4096)
    logging.info("Mensagem recebida da camada de rede.")
    segment = unmount_tcp_segment(segment)
    payload = segment['payload']

    # Enviando payload para a camada de aplicação
    logging.info("CAM_TRANSP: Enviando payload para a camada de aplicação...")
    ip_app="localhost"
    port_app=20007
    client_app = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    client_app.connect((ip_app, port_app))
    client_app.send(payload)

    # Recebendo a resposta da requisição feita à camada de aplicação
    response = client_app.recv(4096)
    logging.info("CAM_TRANSP: Resposta do servidor de aplicação recebida!")
    # client_app.close()

    # Mandando a resposta da requisição de volta
    logging.info("CAM_TRANSP: Mandando resposta de volta a resposta para a camada de rede...")
    connection.send(response)
    # connection.close()

# Main do Programa
# Escolhendo qual o envio será utilizado
print("Qual o protocolo deseja utilizar (1 - UDP, 2 - TCP)?")
choice = input()
if(choice != 1 and choice != 2):
    print("Resposta inválida!")
    exit()

if(choice == 1):
    udp_receive()
else:
    tcp_receive()
