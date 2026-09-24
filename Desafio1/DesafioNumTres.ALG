Algoritmo "LogiFast"
// Disciplina  : Algoritmo e Lógica de Programação
// Professor   : André Olímpio 
// Descrição   :
// Autor(a)    : Miguel Francisco Ribeiro dos Santos
// Data atual  : 22/09/2026
const

// ENUM SITUACAO
STATUS_AGUARDANDO = 0
STATUS_EM_TRANSPORTE = 1
STATUS_ENTREGUE = 2

// ENUM PRIORIDADE
PRIORIDADE_NORMAL = 0
PRIORIDADE_PRIORITARIO = 1
PRIORIDADE_URGENTE = 2

// ENUM REGIÕES
CENTRO = 0
NORTE = 1
SUL = 2
LESTE = 3
OESTE = 4

// CONSTANTES FORNECIDAS
MAX_ENTREGAS = 29
MAX_REGIOES = 4

VALOR_KM = 2.50


tipo
entrega = registro

        codigo: caracter
        destinatario: caracter
        origem: caracter
        destino: caracter

        peso_da_carga: real
        valor_mercadoria: real
        distancia: inteiro
        custo_estimado: real

        prioridade: inteiro
        status: inteiro

fimregistro

// PROCEDIMENTOS

// OPERACOES PRINCIPAIS
procedimento CadastrarEntrega()
var

inicio

fimprocedimento


procedimento ListarEntrega()
var

inicio

fimprocedimento


procedimento ConsultarEntrega()
var

inicio

fimprocedimento


procedimento ExibirFila()
var

inicio

fimprocedimento


procedimento IniciarTransporte()
var

inicio

fimprocedimento


procedimento FinalizarEntrega()
var

inicio

fimprocedimento


procedimento ExibirMatrizDeDistancias()
var

inicio

fimprocedimento


procedimento ExibirEstatisticas()
var

inicio

fimprocedimento


procedimento CalcularPercursoRecursivamente()
var

inicio

fimprocedimento


procedimento EncerrarSistema()
var

inicio

fimprocedimento

// TELA PRINCIPAL
procedimento TelaPrincipal()
var
input_usuario: inteiro

Inicio

// leia entrada
repita
      escreval("Digite a opção:")
      escreval("1. Cadastrar entrega")
      escreval("2. Listar entregas")
      escreval("3. Consultar entrega")
      escreval("4. Exibir fila de despacho")
      escreval("5. Iniciar transporte")
      escreval("6. Finalizar entrega")
      escreval("7. Exibir matriz de distâncias")
      escreval("8. Exibir estatísticas")
      escreval("9. Calcular percurso recursivamente")
      escreval("10. Encerrar sistema ")
      leia(input_usuario)
ate (input_usuario > 0) e (input_usuario <= 10)

escolha input_usuario
       caso 1
            CadastrarEntrega()
       caso 2
            ListarEntrega()
       caso 3
            ConsultarEntrega()
       caso 4
            ExibirFila()
       caso 5
            IniciarTransporte()
       caso 6
            FinalizarEntrega()
       caso 7
            ExibirMatrizDeDistancias()
       caso 8
            ExibirEstatisticas()
       caso 9
            CalcularPercursoRecursivamente()
       caso 10
            EncerrarSistema()
fimescolha

fimprocedimento

Var
DISTANCIAS_REGIOES: vetor[0..4, 0..4] de inteiro

entregas_atuais: vetor[1..MAX_ENTREGAS] de entrega

Inicio

TelaPrincipal()

Fimalgoritmo