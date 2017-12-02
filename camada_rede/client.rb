#client receive file from server
# puts ip
# host = Socket.gethostname
# puts host
#
# ip = UDPSocket.open {|s| s.connect("64.233.187.99", 1); s.addr.last}
# puts ip ->>>>>>> PEGAR IP DO SOCKET

require 'socket'
require 'logger'
include Socket::Constants

# ---------------------- GLOBAL ---------------------------------------------
$transp_port = 20002
$physic_port = 20003
$host = '127.0.0.1'
$sourceIP = "192.168.15.8" #--> Colocar o endereço da maquina
$destIP = '0.0.0.0'

# Criando socket com a camada de transporte
$transport = Socket.new(AF_INET, SOCK_STREAM, 0) ## recebe segmento da camada de tranporte
$transport.bind(Socket.sockaddr_in($transp_port, $host))
$transport.listen(1)
$connection, client = $transport.accept()

# Criando o socket com a camada física
$physic = Socket.new(AF_INET, SOCK_STREAM, 0)
sockaddr = Socket.sockaddr_in($physic_port, $host)
$physic.connect(sockaddr)

$logger = Logger.new('../client_log.txt')

# ----------------------------------------------------------------------------

def criaPacote(segmento, sourceIP, destIP)

  s_sourceIP = sourceIP.split('.')
  s_destIP = destIP.split('.')

  versionIHL = sprintf("%04b", 15)+sprintf("%04b", 15)
  typeService = sprintf("%08b", 0)
  totalLength = sprintf("%016b", segmento.length+20)
  identification = sprintf("%016b", 0)
  flags = sprintf("%03b", 0)
  fragOffset = sprintf("%013b", 0)
  ttl = sprintf("%08b", 10)
  protocol = sprintf("%08b", 6)
  headerChecksum = sprintf("%016b", 0)
  sourceADD = sprintf("%08b", s_sourceIP[0])+sprintf("%08b", s_sourceIP[1])+
    sprintf("%08b", s_sourceIP[2])+sprintf("%08b", s_sourceIP[3])
  destADD = sprintf("%08b", s_destIP[0])+sprintf("%08b", s_destIP[1])+
    sprintf("%08b", s_destIP[2])+sprintf("%08b", s_destIP[3])
  options = sprintf("%024b",0)
  padding = sprintf("%08b",255)

  header = versionIHL+typeService+totalLength+identification+flags+fragOffset+ttl+
    protocol+headerChecksum+sourceADD+destADD+options+padding

  pacote = header + segmento
  return pacote
end

def separaPacote(pacote)

  versionIHL = pacote[0..7]
  typeService = pacote[8..15]
  totalLength = pacote[16..31]
  identification = pacote[32..47]
  flags = pacote[48..50]
  fragOffset = pacote[51..63]
  ttl = pacote[64..71]
  protocol = pacote[72..79]
  headerChecksum = pacote[80..95]
  sourceADD = pacote[96..127]
  destADD = pacote[128..159]
  options = pacote[160..183]
  padding = pacote[184..191]

  payload = pacote[192..pacote.length-1] # estava mandando muitos 0 n sei de onde... COLOCAR 214

  return payload

end

def calculaRede(ipDestino, mascara)

  puts "------"
  puts ipDestino
  puts "------"

  ipDestino = ipDestino.split('.')


  ipDestino[0]=ipDestino[0].to_i().to_s(2).rjust(8,'0')
  ipDestino[1]=ipDestino[1].to_i().to_s(2).rjust(8,'0')
  ipDestino[2]=ipDestino[2].to_i().to_s(2).rjust(8,'0')
  ipDestino[3]=ipDestino[3].to_i().to_s(2).rjust(8,'0')

  mascara = '255.255.255.0'
  mascara = mascara.split('.')
  mascara[0]=mascara[0].to_i().to_s(2).rjust(8,'0')
  mascara[1]=mascara[1].to_i().to_s(2).rjust(8,'0')
  mascara[2]=mascara[2].to_i().to_s(2).rjust(8,'0')
  mascara[3]=mascara[3].to_i().to_s(2).rjust(8,'0')


  ip = ipDestino[0] + ipDestino[1] + ipDestino[2] + ipDestino[3]
  masc  = mascara[0] + mascara[1] + mascara[2] + mascara[3]


  add = Array.new()
  result = ip.to_i(2) & masc.to_i(2)
  result = result.to_s(2)

  while result.length < 32
    result = '0'+result
  end

  re = /\w{8}/
  result.scan(re) do |match|
      add << match.to_i(2).to_s(10)
  end

  ipRede = add[0]+'.'+add[1]+'.'+add[2]+'.'+add[3]

  return ipRede
end

def router_table(pacote)

  # testa o next HOP
  file = open('nextHopClient', "rb")
  fileContent = file.read

  fo = fileContent.split(' ')
  ipRede = fo[0]
  mascara = fo[1]
  nextHop = fo[2]

  get_destIP(pacote)

  if ipRede == calculaRede($destIP, mascara)
    puts("Pacote encaminhado AND b-b funcionou")
    $logger.info("CAM_RED: Pacote encaminhado AND b-b funcionou")
  else
    puts("Pacote Descartado, nao conheco o destino")
    $logger.info("CAM_RED: Pacote Descartado, nao conheco o destino")
    return 404
  end
  file.close()
  return

end



def conect_physic(pacote)

  if(router_table(pacote)==404) then
    exit()
  end

  puts ('Enviando para a Física')

  #pacote = pacote +"\n"

  $logger.info("CAM_RED: Enviando pacote para a camada física...")
  puts " enviado para fisica"
  puts (pacote)
  puts " "
  $physic.send(pacote + "\n",0)
  puts ("Aguradndo recebimento")
  resposta = $physic.recv(4096)
  $logger.info("CAM_RED: Frame recebido da camada física!")
  # socket.close()

  return resposta

end

def get_destIP(pacote)
  destIP = pacote[/Host: (.*)/]
  puts
  puts "-------"
  puts(destIP)
  puts
  destIP = destIP.split(' ')
  printf("\n", destIP,"\n")
  $destIP = destIP[1]
  printf("--------- "+$destIP)

end


def main

  # RECEBER COISAS -> TCPSocket
  # MANDAR COISAS  -> TCPServer
  segmento = $connection.recv(4096)

  if segmento.length >0
    $logger.info("CAM_RED: Segmento recebido da camada de transporte!")
    puts("Payload recebido!")
    print(segmento)
    # ip = IPSocket.getaddress(Socket.gethostname)

    $logger.info("CAM_RED: Verificando IP de destino...")
    get_destIP(segmento)
    $logger.info("CAM_RED: IP encontrado: " + $destIP)

    pacote = criaPacote(segmento,$sourceIP, $destIP)
    resposta = conect_physic(pacote)

    frame = separaPacote(resposta)

    puts "Pacote enviado para camada de Transporte"
    puts frame

    #enviar transport novamente
    $logger.info("CAM_RED: Enviando pacote para a camada de transporte...")
    $connection.puts(frame)
  end
end

loop{
  main
}
# $transport.close()
