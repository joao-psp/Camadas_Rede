-- Bibliotecas utilizadas
require("socket")
log = require('log')

-- Funções auxiliares
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
  port_network = 20005
  ip_physical = "192.168.15.8"
  port_physical = 20004

  -- Socket to physical layer
  socket_physical = assert(socket.bind(ip_physical, port_physical))
  connection_physical = assert(socket_physical:accept())

  -- Socket from network layer
  connection_network = socket.connect(ip_network, port_network)


  while(true) do
    server()
    client()
  end
end

log.outfile = '../server_log.txt'
main()





-- -- arg[1] ip entrada
-- -- arg[2] porta entrada
-- -- arg[3] ip saída
-- -- arg[4] porta saída
--
-- -- Iniciando valores de conexão com camada física
-- local ip = arg[1] -- Aqui entra o ip do client físico
-- local port = arg[2] -- Aqui entra a porta do client físico
--
-- -- Criando o socket geral que vai escutar pra fazer os outros sockets
-- local server = assert(socket.bind(ip, port))
--
-- -- Esperando a conexão
-- print("Connect to " .. ip .. "/" .. port)
-- local connection = assert(server:accept())
--
-- -- Recebendo a mensagem pedindo o tamanho
-- local frame_size = "1024\n" -- Aqui entra o tamanho da mensagem
-- local msg = connection:receive("*l")
-- if(msg == "TMQ") then -- Se for uma requisição de tamanho
--   connection:send(frame_size)
-- end
--
-- -- Recebendo o frame
-- -- Dado que os headers ocupam 336 bits, o payload_pice_size será frame_size - 336
-- local payload_pice_size = 1024 - 336
-- local frame = connection:receive("*l")
-- local payload = "" -- Começa vazio e vai concatenando até chegar o fim da conexão
-- while(frame ~= "__FIN__") do-- Enquanto não for o fim da conexão
--   -- Desmonta o frame para pegar o payload
--   print("Frame Recebido: " .. frame)
--   local preambule = string.sub(frame,1,56)
--   local frame_delimiter = string.sub(frame,57,64)
--   local mac_destination = string.sub(frame,65,112)
--   local mac_source = string.sub(frame,113,160)
--   local tag = string.sub(frame,161,192)
--   local ethertype = string.sub(frame,193,208)
--   local payload_piece = string.sub(frame,209,209 + payload_pice_size - 1) -- 4096
--   -- local frame_check_sequence = string.sub(frame,4305,4336)
--   -- local interpacket_gap = string.sub(frame,4337,4432)
--   payload = payload .. payload_piece -- Formando o payload inteiro
--   frame = connection:receive("*l") -- Recebe o próximo frame
-- end
--
-- -- O payload ainda está em bytes, tem que convertê-lo para enviar para a camada de transportes
-- print("Payload recebido em bytes: " .. payload)
-- payload = bits_to_string(payload)
-- print("Payload final: " .. payload)
-- -- Finalizando a conexão
-- --connection:close()
--
--
-- -- Terminado o recebimento da PDU
--
-- -- Enviando o payload para a próxima camada
-- local transport_server_ip = arg[3]
-- local transport_connect_port = arg[4]
-- local connection = socket.connect(transport_server_ip, transport_connect_port)
--
-- if connection then
-- 	io.write("Conectado à camada de transporte.")
-- else
-- 	io.write("Falha na conexão")
-- end
--
-- io.write("Enviando payload")
-- connection:send(payload)
-- connection:close()
