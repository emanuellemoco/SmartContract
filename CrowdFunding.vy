# @version ^0.2.0

# SmartContract for CrowdFounding developed by Emanuelle Moço

# Struct que agrupa os dados de uma doacao
struct Donator:
    owner: address # Dono da doacao
    price: uint256 # Valor da doacao
    # valid: bool # Indicação se a doação é valida (ao ser resgatada se torna invalida)

# Dicionário que indica se o usuário fez uma doacao
users: public(HashMap[address, Donator])

# Meta de arrecadação
priceGoal: uint256

# Variável utilizada para pegar o valor price atual do doador
tempPrice : uint256

# Endereço do dono do contrato (vai receber o valor da doacao)
owner: address

# Data máxima para doacao
limit: uint256
deadLine: uint256

# Montante total das doacoes
count: uint256


end: bool


# Função que roda quando é feito o deploy do contrato
@external
def __init__(priceGoal: uint256, limit: uint256):
    # Guarda o Endereço do dono do contrato na variável
    self.owner = msg.sender
    self.priceGoal = priceGoal
    self.limit = limit
    self.count = 0
    self.tempPrice = 0
    self.deadLine = block.timestamp + limit
    self.end = False

# Função que encerra o evento
@external
def finish():
    # Caso o evento já tenha terminado
    assert self.end == False, "Crowdfunding already finished"

    # # Testa se o evento já foi encerrado (passou a data limite)
    # assert block.timestamp > self.deadLine, "Crowdfunding still in progress"

    # Testa se é o dono do contrato
    assert msg.sender == self.owner, "Only the owner can finish the event"
    
    # Testa se o evento alcançou o minimo de doacao
    assert self.count >= self.priceGoal, "Not reached the goal"

    # Sinaliza e saca o dinheiro do contrato
    self.end = True
    selfdestruct(msg.sender)

@external # Habilita para interação externa (função chamável)
@payable # Habilita o recebimento de valores pela função
def donate():
    # Testa se o evento ainda não acabou
    assert block.timestamp < self.deadLine, "Crowdfunding has finished"
    assert self.end == False, "Crowdfunding has finished"

    # checar se a doacao é valida > 0
    assert msg.value > 0, "Donation must be greater than 0"

    # msg.sender existe para toda função e não precisa entrar como argumento (end de quem chamou a funcao)
    self.count += msg.value  # Incrementa o valor total das doacoes

    # adiciona o valor da doacao atual com o valor que essa pessoa ja tinha em value
    self.tempPrice = self.users[msg.sender].price + msg.value # uma pessoa pode doar várias vezes
    self.users[msg.sender] =  Donator({
        owner: msg.sender,
        price: self.tempPrice,
        # valid: True
        })
    

# Função para pedir refound de uma doacao caso a meta não tenha sido atingida
@external
def refound():
    # Checa se o evento acabou
    assert block.timestamp > self.deadLine, "Crowdfunding still in progress"

    # Testa se o evento acabou sem bater a meta
    assert self.count <= self.priceGoal, "We reached the goal"

    # Chega se o msg.value é menor ou igual ao valor que a pessoa doou

    # # Checa se o msg.sender fez uma doacao e se ela é valida para retirada
    assert self.users[msg.sender].price > 0, "You don't have anything to withdraw"

    # Transfere o dinheiro para a pessoa
    send(msg.sender, self.users[msg.sender].price)
    # self.users[msg.sender].valid = False
    
