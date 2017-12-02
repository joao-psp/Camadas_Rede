-- Bibliotecas utilizadas
require('socket')
log = require('log')
-- Funções auxiliares locais
require('aux')

-- Preparando parâmetro de random
math.randomseed(os.time())

function client()
  -- Recebe da camada de rede
  print("Esperando um pacote para ser enviado...")
  local payload = connection_network:receive('*l')
  log.info("CAM_FIS: Pacote recebido da camada de rede!")
  print("Pacote recebido!")
  if(payload == nil) then -- parace ser aqui o problemaaaa
    print("Conexão finalzada")
    return
  end
  print("Payload vindo da camada de rede: " .. payload)

  -- Transformando o payload em bits
  payload = string_to_bits(payload)
  -- Aumentando o payload só para ter pelo menos alguma coisa grande sendo mandada
  while(string.len(payload) < 4096) do
    payload = payload .. "00000000"
  end

  -- Nesse momento é necessário iniciar a conexão para verificar qual o tamanho máximo de quadro é possível enviar
  -- Negociando tamanho com servidor
  log.info("CAM_FIS: Negociando TMQ com a outra camada física...")
  connection_physical:send("TMQ\n")
  local frame_size = tonumber(connection_physical:receive("*l"))
  log.info("CAM_FIS: TMQ negociado: " .. frame_size)
  print("Tamano do frame: " .. frame_size)

  -- Definindo partes do cabeçalho
  -- Preambulo -- frame_delimiter -- mac_destination -- mac_source -- tag -- ethertype -- payload -- frame_check_sequence -- interpacket_gap
  -- Tamanho total do cabeçalho : 336 bits
  local preambule = "00000000000000000000000000000000000000000000000000000000"
  local frame_delimiter = "00000000"
  local mac_destination = "000000000000000000000000000000000000000000000000"
  local mac_source = "000000000000000000000000000000000000000000000000"
  local tag = "00000000000000000000000000000000"
  local ethertype = "0000000000000000"
  local frame_check_sequence = "00000000000000000000000000000000"
  local interpacket_gap = "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
  -- Separando o que vem antes do payload do que vem depois do payload
  local before_payload = preambule .. frame_delimiter .. mac_destination .. mac_source .. tag .. ethertype
  local after_payload = frame_check_sequence .. interpacket_gap
  -- Tamanho do cabeçalho
  local header_size = string.len(before_payload .. after_payload) -- Da 336

  -- Antes de iniciar o envio, irei dividir o payload em tamanhos que serão referentes ao tamanho negociado
  -- Considerando que o cabeçalho já ocupará header_size bits, entao o tamanho dos pedaços de payload só podem ser frame_size - header_size
  local payload_piece_size = frame_size - header_size
  -- O payload vai ser divido em pedaços
  local payload_pieces = split_string(payload, payload_piece_size)

  -- Realizando o envio
  local i=0 -- Used in logging
  local frame
  local packet_lose_chance = math.random() * 10
  log.info("CAM_FIS: Iniciando o envio dos pacotes:")
  for index, payload_piece in pairs(payload_pieces) do
    -- Montando o frame
    frame = before_payload .. payload_piece .. after_payload
    -- Simulando peda de pacote
    while(true) do
  		if(packet_lose_chance < 4) then -- 40% de chance de perder o frame
  			print("Pacote Perdido!")
        log.info("CAM_FIS: Colisão!! Reenviando o frame")
        packet_lose_chance = math.random() * 10
  		else -- Envia o frame
        print("Frame enviado: " .. payload_piece)
        log.info("CAM_FIS: Parte " .. i .. "da mensagem enviada!")
        i = i + 1
  			connection_physical:send(frame .. "\n")
        packet_lose_chance = math.random() * 10
        socket.sleep(0.5)
  			break
  		end															--envia o conteudo de partialPayload ao cliente
  	end
  end

  -- Fim do envio
  -- Fim do envio
  -- Enviando mensagem de fim do envio
  print("Enviando FIN")
  connection_physical:send("__FIN__\n")
  log.info("CAM_FIS: Mensagem completamente enviada com sucesso!")
end

function server()
  -- Inicia recebimento da resposta da camada física
  -- Recebendo a mensagem pedindo o tamanho
  frame_size = "1024\n" -- Aqui entra o tamanho da mensagem
  local msg = connection_physical:receive("*l")
  log.info("CAM_FIS: Pedido de negociação de TMQ recebido!")
  if(msg == "TMQ") then -- Se for uma requisição de tamanho
    log.info("CAM_FIS: Enviando tamanho de TMQ: " .. frame_size)
    connection_physical:send(frame_size)
  end

  -- Recebendo o frame
  -- Dado que os headers ocupam 336 bits, o payload_pice_size será frame_size - 336
  local i = 0 -- Used in logging
  local payload_piece_size = 1024 - 336
  local frame = connection_physical:receive("*l")
  log.info("CAM_FIS: Iniciando recebimento de frame!")
  local payload = "" -- Começa vazio e vai concatenando até chegar o fim da conexão
  while(frame ~= "__FIN__") do-- Enquanto não for o fim da conexão
    -- Desmonta o frame para pegar o payload
    print("Frame Recebido: " .. frame)
    log.info("CAM_FIS: Parte " .. i .. " do frame recebida!")
    i = i + 1
    local preambule = string.sub(frame,1,56)
    local frame_delimiter = string.sub(frame,57,64)
    local mac_destination = string.sub(frame,65,112)
    local mac_source = string.sub(frame,113,160)
    local tag = string.sub(frame,161,192)
    local ethertype = string.sub(frame,193,208)
    local payload_piece = string.sub(frame,209,209 + payload_piece_size - 1) -- 4096
    -- local frame_check_sequence = string.sub(frame,4305,4336)
    -- local interpacket_gap = string.sub(frame,4337,4432)
    payload = payload .. payload_piece -- Formando o payload inteiro
    frame = connection_physical:receive("*l") -- Recebe o próximo frame
  end

  log.info("CAM_FIS: Mensagem completa recebida com sucesso!")
  -- O payload ainda está em bytes, tem que convertê-lo para enviar para a camada de transportes
  print("Payload recebido em bytes: " .. payload)
  payload = bits_to_string(payload)
  print("Payload final: " .. payload)

  -- Enviando payload para camada de rede
  log.info("CAM_FIS: Enviando frame para a camada de rede...")
  connection_network:send(payload)
end

function main()
  ip_network = "localhost"
  port_network = 20003
  ip_physical = "192.168.15.29" -- 10.0.125.196
  port_physical = 20004

  -- Socket from network layer
  socket_network = assert(socket.bind(ip_network, port_network))
  connection_network = assert(socket_network:accept())

  -- Socket to physical layer
  connection_physical = socket.connect(ip_physical, port_physical)

  while(true) do
    client()
    server()
  end
end

log.outfile = '../client_log.txt'
main()



--
-- -- Recebendo payload da camada de transporte
-- -- local sock_transport = assert(socket.bind("localhost", 20008))
-- local sock_transport = assert(socket.bind(arg[1], arg[2]))
--
-- local ip, port = sock_transport:getsockname()
--
-- local connection = assert(sock_transport:accept())
-- -- Recebendo o dado a ser enviado para o servidor
-- local payload = connection:receive('*a')
-- connection:close()
--
-- print("Payload vindo da camada de transporte: " .. payload)
--
-- -- Transformando o payload em bits
-- payload = string_to_bits(payload)
-- print("Payload vindo da camada de transporte em bits: " .. payload)
-- -- Aumentando o payload só para ter pelo menos alguma coisa grande sendo mandada
-- while(string.len(payload) < 4096) do
--   payload = payload .. "00000000"
-- end
--
-- -- Nesse momento é necessário iniciar a conexão para verificar qual o tamanho máximo de quadro é possível enviar
-- -- Iniciando dados da conexão
-- local server_ip = arg[3] -- Aqui entra o IP para a conexão com o servidor da camada física
-- local server_port = arg[4] -- Aqui entra a porta para a conexão com o servidor da camada física
--
-- -- Iniciando a conexão
-- local sock_client = socket.connect(server_ip, server_port)
-- if sock_client then
--   print("Conectado com sucesso.")
-- else
--   print("Falha na conexão para receber tamanho")
--   return
-- end
--
-- -- Negociando tamanho com servidor
-- sock_client:send("TMQ\n")
-- local frame_size = tonumber(sock_client:receive("*l"))
-- print("Tamano do frame: " .. frame_size)
-- socket.sleep(0.5)
--
--
-- -- Definindo partes do cabeçalho
-- -- Preambulo -- frame_delimiter -- mac_destination -- mac_source -- tag -- ethertype -- payload -- frame_check_sequence -- interpacket_gap
-- -- Tamanho total do cabeçalho : 336 bits
-- local preambule = "00000000000000000000000000000000000000000000000000000000"
-- local frame_delimiter = "00000000"
-- local mac_destination = "000000000000000000000000000000000000000000000000"
-- local mac_source = "000000000000000000000000000000000000000000000000"
-- local tag = "00000000000000000000000000000000"
-- local ethertype = "0000000000000000"
-- local frame_check_sequence = "00000000000000000000000000000000"
-- local interpacket_gap = "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
-- -- Separando o que vem antes do payload do que vem depois do payload
-- local before_payload = preambule .. frame_delimiter .. mac_destination .. mac_source .. tag .. ethertype
-- local after_payload = frame_check_sequence .. interpacket_gap
-- -- Tamanho do cabeçalho
-- local header_size = string.len(before_payload .. after_payload) -- Da 336
--
-- -- Antes de iniciar o envio, irei dividir o payload em tamanhos que serão referentes ao tamanho negociado
-- -- Considerando que o cabeçalho já ocupará header_size bits, entao o tamanho dos pedaços de payload só podem ser frame_size - header_size
-- local payload_piece_size = frame_size - header_size
-- -- O payload vai ser divido em pedaços
-- local payload_pieces = split_string(payload, payload_piece_size)
--
-- -- Realizando o envio
-- local frame
-- local packet_lose_chance = math.random() % 10
-- for index, payload_piece in pairs(payload_pieces) do
--   -- Montando o frame
--   frame = before_payload .. payload_piece .. after_payload
--   -- Simulando peda de pacote
--   while(true) do
-- 		if(packet_lose_chance < 8) then -- 20% de chance de perder o frame
-- 			print("Pacote Perdido!")
-- 			--socket.sleep(math.random()%2)
-- 		else -- Envia o frame
--       print("Frame enviado: " .. payload_piece)
-- 			sock_client:send(frame .. "\n")
--       socket.sleep(0.5)
-- 			break
-- 		end															--envia o conteudo de partialPayload ao cliente
-- 		packet_lose_chance = (packet_lose_chance + math.random()) % 10
-- 	end
-- end
--
-- -- Fim do envio
-- -- Enviando mensagem de fim do envio
-- print("Enviando FIN")
-- sock_client:send("__FIN__\n")
-- sock_client:close()
