# -*- coding: utf-8 -*-
import socket
import logging
from aux import * # Biblioteca local, criada pelos autores maravilhosos

# Configuring logging filename='../log.txt',
logging.basicConfig(filename='../client_log.txt', format='%(asctime)s %(message)s', level=logging.INFO)

def udp_send(payload):
    # Recebe o payload e o redireciona para a camada física adicionando o cabeçalho UDP

    # Enviando o segmento
    logging.info("CAM_TRANSP: Inciando envio do segmento...")
    ip="localhost"
    port=20002
    client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    client.connect((ip, port))

    # Definindo partes do segmento
    src_port = 4000 # Aqui coloca a porta de origem
    dest_port = 4000 # Aqui coloca a porta de destino
    length = len(payload) # Aqui coloca o tamanho do segmento
    # O método de verificação escolhido foi o tamanho do payload + 1
    checksum = len(payload) + 1

    # Montando o segmento
    # Estou definindo para 16 bits por que sabendo os tamanhos fica mais fácil de desmontar o segmento no servidor
    segment = to_16_bits(src_port) + to_16_bits(dest_port) + to_16_bits(length) + to_16_bits(checksum) + payload
    client.send(segment)
    logging.info("CAM_TRANSP: Enviando segmento para a camada de rede...")

    # Recebendo resposta do servidor
    segment_response = client.recv(4096)
    print("Segmento da camada de trasporte: ")
    print(segment_response)
    logging.info("CAM_TRANSP: Pacote de resposta do servidor recebido.")
    # client.close()
    return segment_response;


def tcp_send(payload):
    # Envia um SYN, espera um ACK, envia um SYNACK e depois envia a mensagem

    logging.info("CAM_TRANSP: Inciando envio do segmento...")

    # Criando socket com a camada rede
    ip="localhost"
    port=20002
    client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    client.connect((ip, port))

    logging.info("CAM_TRANSP: Iniciando a conexão com three-way-handshake...")
    # Setando parâmetros do header inicial
    source_port = to_16_bits(4000)
    dest_port = to_16_bits(4000)
    seq_number = to_32_bits(1)
    ack_number = to_32_bits(1)
    data_offset = to_4_bits(0)
    reserved = to_6_bits(0)
    urg = "0"
    ack = "0"
    psh = "0"
    rst = "0"
    syn = "0"
    fin = "0"
    window = to_16_bits(0)
    checksum = to_16_bits(123)
    urgent_pointer = to_16_bits(123)
    options = to_24_bits(123)
    padding = to_8_bits(12)

    # Enviando o SYN
    logging.info("CAM_TRANSP: Enviando o SYN...")
    segment_syn = (source_port + dest_port + seq_number + ack_number + data_offset + reserved +
        urg + ack + psh + rst + syn + fin + window + checksum + urgent_pointer + options + padding + "Host: 192.168.15.8")
    client.send(segment_syn)

    # Recebendo o ACK
    segment_ack = client.recv(4096)
    logging.info("CAM_TRANSP: ACK recebido!")
    segment_ack = unmount_tcp_segment(segment_ack)
    window = int(segment_ack['window'] + "0", 2) # Salvando a janela utilizada
    logging.info("CAM_TRANSP: ACK recebido! Janela recebida: " + str(window))

    # Enviado o SYNACK
    # Como não importa se o outro lado recebe, vou só printar na tela
    # TODO: ver com o Sandro se pode ser só isso mesmo
    logging.info("CAM_TRANSP: Enviando SYNACK...")
    logging.info("CAM_TRANSP: three-way-handshake finalizado.")

    # Enviado a mensagem
    logging.info("CAM_TRANSP: Enviando a mensagem vinda da camada de aplicação...")
    # Verificando se o tamanho da mensagem sendo enviada está de acordo com o que o receptor pode receber
    if(len(payload) > window):
        logging.warning("CAM_TRANSP: Tamanho enviado maior do que a janela de recepção. Dividindo a mensagem")
    else:
        logging.info("CAM_TRANSP: Janela de recepção maior do que o tamanho enviado. Enviando mensagem normalmente.")

    segment = (source_port + dest_port + seq_number + ack_number + data_offset + reserved +
        urg + ack + psh + rst + syn + fin + to_16_bits(window) + checksum + urgent_pointer + options + padding + payload)
    client.send(segment)
    print("Mensagem enviada!")
    print("Esperando resposta do servidor...")

    # Recebendo resposta do servidor
    segment_response = client.recv(4096)
    logging.info("CAM_TRANSP: Pacote da resposta do servidor recebido.")
    # client.close()
    return segment_response;


# Main do Programa

# Escolhendo qual o envio será utilizado
print("Qual o protocolo deseja utilizar (1 - UDP, 2 - TCP)?")
choice = input()
if(choice != 1 and choice != 2):
    print("Resposta inválida!")
    exit()

# Criando socket com a camada de aplicação
ip = "localhost"
port = 20001
server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.bind((ip, port))
server.listen(1)
connection, client = server.accept()

# Recebendo o que vai ser enviado da camada de aplicação

payload = connection.recv(4096)
logging.info("CAM_TRANSP: Mensagem recebida da camada de aplicação.")

if(choice == 1):
    response = udp_send(payload)
else:
    response = tcp_send(payload)

# Enviando resposta para a camada de aplicação
logging.info("CAM_TRANSP: Enviando resposta do servidor para a camada de aplicação...")
connection.send(response)
# connection.close()
