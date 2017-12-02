# Camadas_Redes
Implementações das camadas de redes de computadores

### Alunos:
- João Pedro Silva 
- André Borges
- André Fonseca
- Pedro Silva


# Diagrama para comunicação:

<img src="https://github.com/joao-psp/Camadas_Rede/blob/master/Diagrama.png" alt="Diagrma Comunicação" width="800" height="400"/>

<p></p>

### Instalação:
```
* Camada Física:
	$ sudo apt-get install lua5.1
	$ sudo apt-get install luarocks
	$ sudo luarocks install luasocket

 * Camada Transporte:
	$ sudo apt-get install python

 * Camada Rede:
	$ sudo apt-get install ruby-full

 * Camada Aplicação:
	$ sudo apt-get install nodejs-legacy
	$ sudo apt-get install npm
```
<p></p>


### Execução:
```
 * Camada Física:
		Servidor:  $ lua servidor.lua
	Cliente:     $ lua cliente.lua

 * Camada Transporte:
	Servidor:  $ python servidor.py
	Cliente:    $ python cliente.py

 * Camada Rede:
	Servidor:  $ ruby server.rb
	Cliente:    $ ruby  client.rb

 * Camada Aplicação:
	Servidor: $ node server.js
	Cliente:   $ npm start
```
