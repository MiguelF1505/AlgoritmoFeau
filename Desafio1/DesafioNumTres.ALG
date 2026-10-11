Algoritmo "LogiFast"
// Disciplina  : Algoritmo e Lógica de Programação
// Professor   : André Olímpio
// Descrição   : LogiFast - Sistema Inteligente de Gerenciamento de Entregas
// Autor(a)    : Miguel Francisco Ribeiro dos Santos
// Data atual  : 22/09/2026

const
   // ENUM SITUAÇÃO (status da entrega)
   STATUS_AGUARDANDO    = 1
   STATUS_EM_TRANSPORTE = 2
   STATUS_ENTREGUE      = 3

   // ENUM PRIORIDADE
   PRIORIDADE_URGENTE     = 1
   PRIORIDADE_PRIORITARIA = 2
   PRIORIDADE_NORMAL      = 3

   // ENUM REGIÕES (códigos usados como índices da matriz de distâncias)
   CENTRO = 1
   NORTE  = 2
   SUL    = 3
   LESTE  = 4
   OESTE  = 5

   // CAPACIDADES
   MAX_ENTREGAS = 30
   MAX_REGIOES  = 5
   MAX_PERCURSO = 10
   MIN_PERCURSO = 2
   PESO_MAXIMO  = 1000.0

   // CUSTO
   VALOR_KM = 2.50

   // FAIXAS DE PESO (kg) E ACRÉSCIMOS
   LIMITE_PESO_LEVE            = 5.0
   LIMITE_PESO_MEDIO           = 20.0
   LIMITE_PESO_PESADO          = 50.0
   ACRESCIMO_PESO_MEDIO        = 0.10
   ACRESCIMO_PESO_PESADO       = 0.20
   ACRESCIMO_PESO_MUITO_PESADO = 0.35

   // ACRÉSCIMOS POR PRIORIDADE
   ACRESCIMO_PRIORITARIA = 0.15
   ACRESCIMO_URGENTE     = 0.30

   // MENU
   OPCAO_ENCERRAR = 10

tipo
   entrega = registro
      codigo: inteiro
      destinatario: caracter
      origem: inteiro
      destino: inteiro

      peso_da_carga: real
      valor_mercadoria: real
      distancia: inteiro
      custo_estimado: real

      prioridade: inteiro
      status: inteiro
   fimregistro

// VARIAVEIS GLOBAIS
// Justificativa: dados compartilhados por praticamente todas as sub-rotinas
// (o VisuAlg não permite passar vetores/matrizes como parâmetro).
var
   DISTANCIAS_REGIOES: vetor[1..MAX_REGIOES, 1..MAX_REGIOES] de inteiro
   entregas_atuais: vetor[1..MAX_ENTREGAS] de entrega
   qtd_entregas: inteiro
   percurso: vetor[1..MAX_PERCURSO] de inteiro

// =====================================================================
// FUNÇÕES AUXILIARES (nomes, validações, cálculos)
// =====================================================================

// Retorna o nome da região a partir do código
funcao NomeRegiao(codigo_regiao: inteiro): caracter
var
   nome: caracter
inicio
   nome <- "Inválida"
   se codigo_regiao = CENTRO entao
      nome <- "Centro"
   fimse
   se codigo_regiao = NORTE entao
      nome <- "Norte"
   fimse
   se codigo_regiao = SUL entao
      nome <- "Sul"
   fimse
   se codigo_regiao = LESTE entao
      nome <- "Leste"
   fimse
   se codigo_regiao = OESTE entao
      nome <- "Oeste"
   fimse
   retorne nome
fimfuncao

// Retorna o nome da prioridade
funcao NomePrioridade(codigo_prioridade: inteiro): caracter
var
   nome: caracter
inicio
   nome <- "Inválida"
   se codigo_prioridade = PRIORIDADE_URGENTE entao
      nome <- "Urgente"
   fimse
   se codigo_prioridade = PRIORIDADE_PRIORITARIA entao
      nome <- "Prioritária"
   fimse
   se codigo_prioridade = PRIORIDADE_NORMAL entao
      nome <- "Normal"
   fimse
   retorne nome
fimfuncao

// Retorna o nome do status
funcao NomeStatus(codigo_status: inteiro): caracter
var
   nome: caracter
inicio
   nome <- "Inválido"
   se codigo_status = STATUS_AGUARDANDO entao
      nome <- "Aguardando"
   fimse
   se codigo_status = STATUS_EM_TRANSPORTE entao
      nome <- "Em transporte"
   fimse
   se codigo_status = STATUS_ENTREGUE entao
      nome <- "Entregue"
   fimse
   retorne nome
fimfuncao

// Valida se o código pertence ao intervalo de regiões existentes
funcao RegiaoValida(codigo_regiao: inteiro): logico
inicio
   retorne (codigo_regiao >= CENTRO) e (codigo_regiao <= MAX_REGIOES)
fimfuncao

// Valida se a prioridade está entre as opções existentes
funcao PrioridadeValida(codigo_prioridade: inteiro): logico
inicio
   retorne (codigo_prioridade >= PRIORIDADE_URGENTE) e (codigo_prioridade <= PRIORIDADE_NORMAL)
fimfuncao

// Consulta a matriz: distancia[origem, destino] (nunca digitada pelo usuário)
funcao ObterDistancia(regiao_origem, regiao_destino: inteiro): inteiro
inicio
   retorne DISTANCIAS_REGIOES[regiao_origem, regiao_destino]
fimfuncao

// Custo = distancia * VALOR_KM * (1 + acréscimo de peso + acréscimo de prioridade)
// Os parâmetros são apenas consultados (passagem por valor)
funcao CalcularCusto(dist_km: inteiro; peso_kg: real; prioridade_entrega: inteiro): real
var
   custo_base, acrescimo_peso, acrescimo_prioridade: real
inicio
   custo_base <- dist_km * VALOR_KM

   // acréscimo por faixa de peso (até 5 kg: sem acréscimo)
   acrescimo_peso <- 0
   se (peso_kg > LIMITE_PESO_LEVE) e (peso_kg <= LIMITE_PESO_MEDIO) entao
      acrescimo_peso <- ACRESCIMO_PESO_MEDIO
   fimse
   se (peso_kg > LIMITE_PESO_MEDIO) e (peso_kg <= LIMITE_PESO_PESADO) entao
      acrescimo_peso <- ACRESCIMO_PESO_PESADO
   fimse
   se peso_kg > LIMITE_PESO_PESADO entao
      acrescimo_peso <- ACRESCIMO_PESO_MUITO_PESADO
   fimse

   // acréscimo por prioridade (normal: sem acréscimo)
   acrescimo_prioridade <- 0
   se prioridade_entrega = PRIORIDADE_PRIORITARIA entao
      acrescimo_prioridade <- ACRESCIMO_PRIORITARIA
   senao
      se prioridade_entrega = PRIORIDADE_URGENTE entao
         acrescimo_prioridade <- ACRESCIMO_URGENTE
      fimse
   fimse

   retorne custo_base * (1 + acrescimo_peso + acrescimo_prioridade)
fimfuncao

// Busca sequencial pelo código. Retorna o índice (1..total) ou 0 se não encontrar
funcao LocalizarEntrega(codigo_busca, total: inteiro): inteiro
var
   i, indice: inteiro
inicio
   indice <- 0
   i <- 1
   enquanto (i <= total) e (indice = 0) faca
      se entregas_atuais[i].codigo = codigo_busca entao
         indice <- i
      fimse
      i <- i + 1
   fimenquanto
   retorne indice
fimfuncao

// Regra de transição de status: AGUARDANDO -> EM TRANSPORTE -> ENTREGUE
funcao TransicaoStatusValida(status_atual, novo_status: inteiro): logico
inicio
   retorne ((status_atual = STATUS_AGUARDANDO) e (novo_status = STATUS_EM_TRANSPORTE)) ou ((status_atual = STATUS_EM_TRANSPORTE) e (novo_status = STATUS_ENTREGUE))
fimfuncao

// Compara dois registros do vetor (índices a e b) e diz se "a" deve vir antes de "b".
// Entregas AGUARDANDO vêm primeiro. Entre elas, os critérios são:
// 1) prioridade (menor número primeiro)  2) maior valor
// 3) maior peso                          4) menor código
funcao DeveVirAntes(a, b: inteiro): logico
var
   resultado, a_espera, b_espera: logico
inicio
   a_espera <- (entregas_atuais[a].status = STATUS_AGUARDANDO)
   b_espera <- (entregas_atuais[b].status = STATUS_AGUARDANDO)

   se a_espera e (nao b_espera) entao
      resultado <- verdadeiro
   senao
      se (nao a_espera) e b_espera entao
         resultado <- falso
      senao
         se a_espera entao
            // ambas aguardando: aplica os 4 critérios em cascata
            se entregas_atuais[a].prioridade <> entregas_atuais[b].prioridade entao
               resultado <- (entregas_atuais[a].prioridade < entregas_atuais[b].prioridade)
            senao
               se entregas_atuais[a].valor_mercadoria <> entregas_atuais[b].valor_mercadoria entao
                  resultado <- (entregas_atuais[a].valor_mercadoria > entregas_atuais[b].valor_mercadoria)
               senao
                  se entregas_atuais[a].peso_da_carga <> entregas_atuais[b].peso_da_carga entao
                     resultado <- (entregas_atuais[a].peso_da_carga > entregas_atuais[b].peso_da_carga)
                  senao
                     resultado <- (entregas_atuais[a].codigo < entregas_atuais[b].codigo)
                  fimse
               fimse
            fimse
         senao
            // nenhuma aguardando: mantém ordem por código
            resultado <- (entregas_atuais[a].codigo < entregas_atuais[b].codigo)
         fimse
      fimse
   fimse
   retorne resultado
fimfuncao

// FUNÇÃO RECURSIVA: soma das distâncias do percurso a partir de "posicao"
// distanciaTotal(pos) = dist(percurso[pos], percurso[pos+1]) + distanciaTotal(pos+1)
// Caso-base: posicao >= total (última região do percurso, não há próximo trecho) -> 0
funcao DistanciaPercurso(posicao, total: inteiro): inteiro
var
   resultado: inteiro
inicio
   se posicao >= total entao
      resultado <- 0
   senao
      resultado <- ObterDistancia(percurso[posicao], percurso[posicao + 1]) + DistanciaPercurso(posicao + 1, total)
   fimse
   retorne resultado
fimfuncao

// =====================================================================
// PROCEDIMENTOS DE ENTRADA / SAIDA REUTILIZÁVEIS
// =====================================================================

// Parâmetros "var" = passagem por referência (o procedimento devolve o valor lido)
procedimento LerTexto(mensagem: caracter; var texto: caracter)
inicio
   escreva(mensagem)
   leia(texto)
fimprocedimento

procedimento LerInteiro(mensagem: caracter; var numero: inteiro)
inicio
   escreva(mensagem)
   leia(numero)
fimprocedimento

procedimento LerReal(mensagem: caracter; var numero: real)
inicio
   escreva(mensagem)
   leia(numero)
fimprocedimento

procedimento ExibirRegioes()
var
   i: inteiro
inicio
   escreva("Regiões:")
   para i de 1 ate MAX_REGIOES faca
      escreva("  ", i, "-", NomeRegiao(i))
   fimpara
   escreval("")
fimprocedimento

// Mostra todos os dados de uma entrega (índice no vetor)
procedimento ExibirEntrega(indice: inteiro)
inicio
   escreval("Código        : ", entregas_atuais[indice].codigo)
   escreval("Destinatário  : ", entregas_atuais[indice].destinatario)
   escreval("Origem        : ", NomeRegiao(entregas_atuais[indice].origem))
   escreval("Destino       : ", NomeRegiao(entregas_atuais[indice].destino))
   escreval("Peso          : ", entregas_atuais[indice].peso_da_carga:8:2, " kg")
   escreval("Valor         : R$ ", entregas_atuais[indice].valor_mercadoria:10:2)
   escreval("Prioridade    : ", NomePrioridade(entregas_atuais[indice].prioridade))
   escreval("Distância     : ", entregas_atuais[indice].distancia, " km")
   escreval("Status        : ", NomeStatus(entregas_atuais[indice].status))
   escreval("Custo estimado: R$ ", entregas_atuais[indice].custo_estimado:10:2)
fimprocedimento

// =====================================================================
// PROCEDIMENTOS DE PROCESSAMENTO
// =====================================================================

// Preenche a matriz: zera tudo, define o triângulo superior e espelha (simétrica)
procedimento InicializarMatriz()
var
   i, j: inteiro
inicio
   para i de 1 ate MAX_REGIOES faca
      para j de 1 ate MAX_REGIOES faca
         DISTANCIAS_REGIOES[i, j] <- 0
      fimpara
   fimpara

   DISTANCIAS_REGIOES[CENTRO, NORTE] <- 12
   DISTANCIAS_REGIOES[CENTRO, SUL]   <- 15
   DISTANCIAS_REGIOES[CENTRO, LESTE] <- 10
   DISTANCIAS_REGIOES[CENTRO, OESTE] <- 14
   DISTANCIAS_REGIOES[NORTE, SUL]    <- 25
   DISTANCIAS_REGIOES[NORTE, LESTE]  <- 18
   DISTANCIAS_REGIOES[NORTE, OESTE]  <- 20
   DISTANCIAS_REGIOES[SUL, LESTE]    <- 16
   DISTANCIAS_REGIOES[SUL, OESTE]    <- 19
   DISTANCIAS_REGIOES[LESTE, OESTE]  <- 22

   // espelha o triângulo superior no inferior
   para i de 1 ate MAX_REGIOES faca
      para j de i + 1 ate MAX_REGIOES faca
         DISTANCIAS_REGIOES[j, i] <- DISTANCIAS_REGIOES[i, j]
      fimpara
   fimpara
fimprocedimento

// Grava a entrega já validada: obtém distância na matriz, calcula custo, define status inicial
procedimento GravarEntrega(codigo_novo: inteiro; destinatario_novo: caracter; origem_nova, destino_novo, prioridade_nova: inteiro; peso_novo, valor_novo: real)
var
   novo: inteiro
inicio
   novo <- qtd_entregas + 1
   entregas_atuais[novo].codigo           <- codigo_novo
   entregas_atuais[novo].destinatario     <- destinatario_novo
   entregas_atuais[novo].origem           <- origem_nova
   entregas_atuais[novo].destino          <- destino_novo
   entregas_atuais[novo].peso_da_carga    <- peso_novo
   entregas_atuais[novo].valor_mercadoria <- valor_novo
   entregas_atuais[novo].prioridade       <- prioridade_nova
   entregas_atuais[novo].distancia        <- ObterDistancia(origem_nova, destino_novo)
   entregas_atuais[novo].custo_estimado   <- CalcularCusto(entregas_atuais[novo].distancia, peso_novo, prioridade_nova)
   entregas_atuais[novo].status           <- STATUS_AGUARDANDO
   qtd_entregas <- novo

   escreval("Entrega cadastrada com sucesso!")
   ExibirEntrega(novo)
fimprocedimento

// Troca dois registros do vetor campo a campo (usada pela ordenação)
procedimento TrocarEntregas(i, j: inteiro)
var
   aux_destinatario: caracter
   aux_codigo, aux_origem, aux_destino, aux_distancia, aux_prioridade, aux_status: inteiro
   aux_peso, aux_valor, aux_custo: real
inicio
   aux_codigo       <- entregas_atuais[i].codigo
   aux_destinatario <- entregas_atuais[i].destinatario
   aux_origem       <- entregas_atuais[i].origem
   aux_destino      <- entregas_atuais[i].destino
   aux_peso         <- entregas_atuais[i].peso_da_carga
   aux_valor        <- entregas_atuais[i].valor_mercadoria
   aux_distancia    <- entregas_atuais[i].distancia
   aux_custo        <- entregas_atuais[i].custo_estimado
   aux_prioridade   <- entregas_atuais[i].prioridade
   aux_status       <- entregas_atuais[i].status

   entregas_atuais[i].codigo           <- entregas_atuais[j].codigo
   entregas_atuais[i].destinatario     <- entregas_atuais[j].destinatario
   entregas_atuais[i].origem           <- entregas_atuais[j].origem
   entregas_atuais[i].destino          <- entregas_atuais[j].destino
   entregas_atuais[i].peso_da_carga    <- entregas_atuais[j].peso_da_carga
   entregas_atuais[i].valor_mercadoria <- entregas_atuais[j].valor_mercadoria
   entregas_atuais[i].distancia        <- entregas_atuais[j].distancia
   entregas_atuais[i].custo_estimado   <- entregas_atuais[j].custo_estimado
   entregas_atuais[i].prioridade       <- entregas_atuais[j].prioridade
   entregas_atuais[i].status           <- entregas_atuais[j].status

   entregas_atuais[j].codigo           <- aux_codigo
   entregas_atuais[j].destinatario     <- aux_destinatario
   entregas_atuais[j].origem           <- aux_origem
   entregas_atuais[j].destino          <- aux_destino
   entregas_atuais[j].peso_da_carga    <- aux_peso
   entregas_atuais[j].valor_mercadoria <- aux_valor
   entregas_atuais[j].distancia        <- aux_distancia
   entregas_atuais[j].custo_estimado   <- aux_custo
   entregas_atuais[j].prioridade       <- aux_prioridade
   entregas_atuais[j].status           <- aux_status
fimprocedimento

// SELECTION SORT próprio sobre o vetor de registros.
// A cada passada escolhe o "melhor" registro (DeveVirAntes) e o coloca na posição i.
procedimento OrdenarEntregas()
var
   i, j, melhor: inteiro
inicio
   para i de 1 ate qtd_entregas - 1 faca
      melhor <- i
      para j de i + 1 ate qtd_entregas faca
         se DeveVirAntes(j, melhor) entao
            melhor <- j
         fimse
      fimpara
      se melhor <> i entao
         TrocarEntregas(i, melhor)
      fimse
   fimpara
fimprocedimento

// Aplica a mudança de status validando a sequência obrigatória
procedimento AlterarStatus(indice, novo_status: inteiro)
var
   status_atual: inteiro
inicio
   status_atual <- entregas_atuais[indice].status
   se TransicaoStatusValida(status_atual, novo_status) entao
      entregas_atuais[indice].status <- novo_status
      escreval("Status atualizado: ", NomeStatus(status_atual), " -> ", NomeStatus(novo_status))
   senao
      se status_atual = STATUS_ENTREGUE entao
         escreval("ERRO: entrega já concluída não pode ser modificada.")
      senao
         se novo_status = STATUS_EM_TRANSPORTE entao
            escreval("ERRO: o transporte desta entrega já foi iniciado (entrega já enviada).")
         senao
            escreval("ERRO: entrega ainda está aguardando. Inicie o transporte antes de finalizar.")
         fimse
      fimse
   fimse
fimprocedimento

// Pede o código, localiza e tenta aplicar o novo status
procedimento ProcessarMudancaStatus(novo_status: inteiro)
var
   codigo_busca, indice: inteiro
inicio
   LerInteiro("Código da entrega: ", codigo_busca)
   indice <- LocalizarEntrega(codigo_busca, qtd_entregas)
   se indice = 0 entao
      escreval("Entrega não encontrada.")
   senao
      AlterarStatus(indice, novo_status)
   fimse
fimprocedimento

// Percorre a matriz (repetições aninhadas) e devolve maior, menor (!= 0) e média
// sem considerar a diagonal principal. Resultados via passagem por referência.
procedimento AnalisarMatriz(var maior: inteiro; var menor: inteiro; var media: real)
var
   i, j, soma, contador: inteiro
inicio
   maior <- DISTANCIAS_REGIOES[1, 1]
   menor <- DISTANCIAS_REGIOES[1, 2]
   soma <- 0
   contador <- 0
   para i de 1 ate MAX_REGIOES faca
      para j de 1 ate MAX_REGIOES faca
         se DISTANCIAS_REGIOES[i, j] > maior entao
            maior <- DISTANCIAS_REGIOES[i, j]
         fimse
         se i <> j entao
            soma <- soma + DISTANCIAS_REGIOES[i, j]
            contador <- contador + 1
            se (DISTANCIAS_REGIOES[i, j] <> 0) e (DISTANCIAS_REGIOES[i, j] < menor) entao
               menor <- DISTANCIAS_REGIOES[i, j]
            fimse
         fimse
      fimpara
   fimpara
   media <- soma / contador
fimprocedimento

// =====================================================================
// OPERAÇÕES DO MENU
// =====================================================================

procedimento CadastrarEntrega()
var
   destinatario: caracter
   codigo, origem, destino, prioridade: inteiro
   peso, valor: real
   dados_ok: logico
inicio
   escreval("--- CADASTRAR ENTREGA ---")
   dados_ok <- verdadeiro

   // 1) existe espaço?
   se qtd_entregas >= MAX_ENTREGAS entao
      escreval("ERRO: capacidade máxima de ", MAX_ENTREGAS, " entregas atingida.")
      dados_ok <- falso
   fimse

   // 2) código duplicado?
   se dados_ok entao
      LerInteiro("Código da entrega: ", codigo)
      se codigo <= 0 entao
         escreval("ERRO: o código deve ser um número inteiro maior que zero.")
         dados_ok <- falso
      senao
         se LocalizarEntrega(codigo, qtd_entregas) <> 0 entao
            escreval("ERRO: o código informado já está cadastrado.")
            dados_ok <- falso
         fimse
      fimse
   fimse

   // 3) destinatário e origem
   se dados_ok entao
      LerTexto("Destinatário: ", destinatario)
      ExibirRegioes()
      LerInteiro("Região de origem: ", origem)
      se nao RegiaoValida(origem) entao
         escreval("ERRO: região de origem inexistente.")
         dados_ok <- falso
      fimse
   fimse

   // 4) destino
   se dados_ok entao
      LerInteiro("Região de destino: ", destino)
      se nao RegiaoValida(destino) entao
         escreval("ERRO: região de destino inexistente.")
         dados_ok <- falso
      fimse
   fimse

   // 5) origem diferente do destino
   se dados_ok entao
      se origem = destino entao
         escreval("ERRO: a origem não pode ser igual ao destino.")
         dados_ok <- falso
      fimse
   fimse

   // 6) peso
   se dados_ok entao
      LerReal("Peso da carga (kg): ", peso)
      se peso <= 0 entao
         escreval("ERRO: o peso deve ser maior que zero.")
         dados_ok <- falso
      senao
         se peso > PESO_MAXIMO entao
            escreval("ERRO: peso acima da capacidade permitida (", PESO_MAXIMO:6:0, " kg).")
            dados_ok <- falso
         fimse
      fimse
   fimse

   // 7) valor da mercadoria
   se dados_ok entao
      LerReal("Valor da mercadoria (R$): ", valor)
      se valor < 0 entao
         escreval("ERRO: o valor da mercadoria não pode ser negativo.")
         dados_ok <- falso
      fimse
   fimse

   // 8) prioridade
   se dados_ok entao
      escreval("Prioridade: ", PRIORIDADE_URGENTE, "-Urgente  ", PRIORIDADE_PRIORITARIA, "-Prioritária  ", PRIORIDADE_NORMAL, "-Normal")
      LerInteiro("Prioridade: ", prioridade)
      se nao PrioridadeValida(prioridade) entao
         escreval("ERRO: prioridade inexistente.")
         dados_ok <- falso
      fimse
   fimse

   // tudo válido: grava
   se dados_ok entao
      GravarEntrega(codigo, destinatario, origem, destino, prioridade, peso, valor)
   senao
      escreval("Cadastro cancelado.")
   fimse
fimprocedimento

procedimento ListarEntrega()
var
   i: inteiro
inicio
   escreval("--- LISTA DE ENTREGAS ---")
   se qtd_entregas = 0 entao
      escreval("Nenhuma entrega cadastrada.")
   senao
      para i de 1 ate qtd_entregas faca
         escreval("Entrega ", i, " de ", qtd_entregas)
         ExibirEntrega(i)
         escreval("-------------------------")
      fimpara
   fimse
fimprocedimento

procedimento ConsultarEntrega()
var
   codigo_busca, indice: inteiro
inicio
   escreval("--- CONSULTAR ENTREGA ---")
   LerInteiro("Código da entrega: ", codigo_busca)
   indice <- LocalizarEntrega(codigo_busca, qtd_entregas)
   se indice = 0 entao
      escreval("Entrega não encontrada.")
   senao
      ExibirEntrega(indice)
   fimse
fimprocedimento

// Ordena o vetor e mostra apenas as entregas AGUARDANDO (a fila lógica)
procedimento ExibirFila()
var
   i, posicao: inteiro
inicio
   escreval("--- FILA DE DESPACHO ---")
   OrdenarEntregas()
   posicao <- 0
   para i de 1 ate qtd_entregas faca
      se entregas_atuais[i].status = STATUS_AGUARDANDO entao
         posicao <- posicao + 1
         escreval(posicao, "º | Cód: ", entregas_atuais[i].codigo, " | ", NomePrioridade(entregas_atuais[i].prioridade), " | Valor: R$ ", entregas_atuais[i].valor_mercadoria:9:2, " | Peso: ", entregas_atuais[i].peso_da_carga:7:2, " kg | ", NomeRegiao(entregas_atuais[i].origem), " -> ", NomeRegiao(entregas_atuais[i].destino))
      fimse
   fimpara
   se posicao = 0 entao
      escreval("Nenhuma entrega aguardando transporte.")
   fimse
fimprocedimento

procedimento IniciarTransporte()
inicio
   escreval("--- INICIAR TRANSPORTE ---")
   ProcessarMudancaStatus(STATUS_EM_TRANSPORTE)
fimprocedimento

procedimento FinalizarEntrega()
inicio
   escreval("--- FINALIZAR ENTREGA ---")
   ProcessarMudancaStatus(STATUS_ENTREGUE)
fimprocedimento

// Exibe a matriz completa e a análise regional (maior, menor, média)
procedimento ExibirMatrizDeDistancias()
var
   i, j, maior, menor: inteiro
   media: real
inicio
   escreval("--- MATRIZ DE DISTÂNCIAS (km) ---")
   escreva("          ")
   para j de 1 ate MAX_REGIOES faca
      escreva(NomeRegiao(j):8)
   fimpara
   escreval("")
   para i de 1 ate MAX_REGIOES faca
      escreva(NomeRegiao(i):10)
      para j de 1 ate MAX_REGIOES faca
         escreva(DISTANCIAS_REGIOES[i, j]:8)
      fimpara
      escreval("")
   fimpara

   AnalisarMatriz(maior, menor, media)
   escreval("Maior distância                  : ", maior, " km")
   escreval("Menor distância (diferente de 0) : ", menor, " km")
   escreval("Média das distâncias entre regiões: ", media:6:2, " km")
fimprocedimento

procedimento ExibirEstatisticas()
var
   i, aguardando, em_transporte, entregues: inteiro
   urgentes, prioritarias, normais: inteiro
   idx_valor, idx_peso, idx_distancia, regiao_top: inteiro
   total_peso, total_valor, total_custo: real
   peso_medio, valor_medio, custo_medio: real
   recebidas: vetor[1..MAX_REGIOES] de inteiro
inicio
   escreval("--- ESTATÍSTICAS ---")
   se qtd_entregas = 0 entao
      escreval("Nenhuma entrega cadastrada.")
   senao
      // zera contadores e acumuladores
      aguardando <- 0
      em_transporte <- 0
      entregues <- 0
      urgentes <- 0
      prioritarias <- 0
      normais <- 0
      total_peso <- 0
      total_valor <- 0
      total_custo <- 0
      idx_valor <- 1
      idx_peso <- 1
      idx_distancia <- 1
      para i de 1 ate MAX_REGIOES faca
         recebidas[i] <- 0
      fimpara

      // uma única passada pelo vetor
      para i de 1 ate qtd_entregas faca
         se entregas_atuais[i].status = STATUS_AGUARDANDO entao
            aguardando <- aguardando + 1
         fimse
         se entregas_atuais[i].status = STATUS_EM_TRANSPORTE entao
            em_transporte <- em_transporte + 1
         fimse
         se entregas_atuais[i].status = STATUS_ENTREGUE entao
            entregues <- entregues + 1
         fimse

         se entregas_atuais[i].prioridade = PRIORIDADE_URGENTE entao
            urgentes <- urgentes + 1
         fimse
         se entregas_atuais[i].prioridade = PRIORIDADE_PRIORITARIA entao
            prioritarias <- prioritarias + 1
         fimse
         se entregas_atuais[i].prioridade = PRIORIDADE_NORMAL entao
            normais <- normais + 1
         fimse

         total_peso <- total_peso + entregas_atuais[i].peso_da_carga
         total_valor <- total_valor + entregas_atuais[i].valor_mercadoria
         total_custo <- total_custo + entregas_atuais[i].custo_estimado

         se entregas_atuais[i].valor_mercadoria > entregas_atuais[idx_valor].valor_mercadoria entao
            idx_valor <- i
         fimse
         se entregas_atuais[i].peso_da_carga > entregas_atuais[idx_peso].peso_da_carga entao
            idx_peso <- i
         fimse
         se entregas_atuais[i].distancia > entregas_atuais[idx_distancia].distancia entao
            idx_distancia <- i
         fimse

         recebidas[entregas_atuais[i].destino] <- recebidas[entregas_atuais[i].destino] + 1
      fimpara

      // região que mais recebeu (em empate, a de menor código)
      regiao_top <- 1
      para i de 2 ate MAX_REGIOES faca
         se recebidas[i] > recebidas[regiao_top] entao
            regiao_top <- i
         fimse
      fimpara

      escreval("Total de entregas      : ", qtd_entregas)
      escreval("Aguardando             : ", aguardando)
      escreval("Em transporte          : ", em_transporte)
      escreval("Entregues              : ", entregues)
      escreval("Urgentes               : ", urgentes)
      escreval("Prioritárias           : ", prioritarias)
      escreval("Normais                : ", normais)
      escreval("Peso total             : ", total_peso:10:2, " kg")
      peso_medio <- total_peso / qtd_entregas
      valor_medio <- total_valor / qtd_entregas
      custo_medio <- total_custo / qtd_entregas
      escreval("Peso médio             : ", peso_medio:10:2, " kg")
      escreval("Valor total            : R$ ", total_valor:10:2)
      escreval("Valor médio            : R$ ", valor_medio:10:2)
      escreval("Custo total estimado   : R$ ", total_custo:10:2)
      escreval("Custo médio            : R$ ", custo_medio:10:2)
      escreval("Entrega de maior valor : ", entregas_atuais[idx_valor].codigo, " (R$ ", entregas_atuais[idx_valor].valor_mercadoria:9:2, ")")
      escreval("Entrega de maior peso  : ", entregas_atuais[idx_peso].codigo, " (", entregas_atuais[idx_peso].peso_da_carga:7:2, " kg)")
      escreval("Entrega de maior dist. : ", entregas_atuais[idx_distancia].codigo, " (", entregas_atuais[idx_distancia].distancia, " km)")
      escreval("Região que mais recebeu: ", NomeRegiao(regiao_top), " (", recebidas[regiao_top], " entrega(s))")
   fimse
fimprocedimento

// Lê um percurso, guarda no vetor global e calcula a distância total recursivamente
procedimento CalcularPercursoRecursivamente()
var
   quantidade, i, regiao, total: inteiro
   percurso_ok: logico
inicio
   escreval("--- CÁLCULO RECURSIVO DE PERCURSO ---")
   ExibirRegioes()
   LerInteiro("Quantas regiões tem o percurso? ", quantidade)
   se (quantidade < MIN_PERCURSO) ou (quantidade > MAX_PERCURSO) entao
      escreval("ERRO: o percurso deve ter de ", MIN_PERCURSO, " a ", MAX_PERCURSO, " regiões.")
   senao
      percurso_ok <- verdadeiro
      i <- 1
      enquanto (i <= quantidade) e percurso_ok faca
         escreva("Região ", i, " do percurso: ")
         leia(regiao)
         se nao RegiaoValida(regiao) entao
            escreval("ERRO: região inexistente.")
            percurso_ok <- falso
         senao
            se i > 1 entao
               se regiao = percurso[i - 1] entao
                  escreval("ERRO: regiões consecutivas não podem ser iguais.")
                  percurso_ok <- falso
               fimse
            fimse
            se percurso_ok entao
               percurso[i] <- regiao
               i <- i + 1
            fimse
         fimse
      fimenquanto

      se percurso_ok entao
         escreva("Percurso: ")
         para i de 1 ate quantidade faca
            escreva(NomeRegiao(percurso[i]))
            se i < quantidade entao
               escreva(" -> ")
            fimse
         fimpara
         escreval("")
         total <- DistanciaPercurso(1, quantidade)
         escreval("Distância total: ", total, " km")
      senao
         escreval("Cálculo cancelado.")
      fimse
   fimse
fimprocedimento

procedimento EncerrarSistema()
inicio
   escreval("Sistema LogiFast encerrado. Até logo!")
fimprocedimento

// =====================================================================
// TELA PRINCIPAL (menu com múltipla escolha, repete até encerrar)
// =====================================================================
procedimento TelaPrincipal()
var
   opcao: inteiro
inicio
   repita
      escreval("")
      escreval("LOGIFAST - SISTEMA DE GERENCIAMENTO DE ENTREGAS")
      escreval("1. Cadastrar entrega")
      escreval("2. Listar entregas")
      escreval("3. Consultar entrega")
      escreval("4. Exibir fila de despacho")
      escreval("5. Iniciar transporte")
      escreval("6. Finalizar entrega")
      escreval("7. Exibir matriz de distâncias")
      escreval("8. Exibir estatísticas")
      escreval("9. Calcular percurso recursivamente")
      escreval("10. Encerrar sistema")
      LerInteiro("Digite a opção: ", opcao)
      escreval("")

      escolha opcao
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
         outrocaso
            escreval("ERRO: opção inválida. Digite um número de 1 a 10.")
      fimescolha
   ate opcao = OPCAO_ENCERRAR
fimprocedimento

inicio
   qtd_entregas <- 0
   InicializarMatriz()
   TelaPrincipal()
fimalgoritmo