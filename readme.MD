# Conta Cron

Um Script que analisa todos os crons do servidor e com base em pontos definidos e altera caso ultrapasse este valor.
Pode ser utilizado por exemplo em servidores compartilhados; onde clientes podem criar crons além do permitido ou com períodos muito curtos. 
Embora não esteja implementado é fácil atribuir a função de enviar um e-mail ou abrir um ticket através de API.

Junto com o script há um cron e uma pasta onde o log está sendo salvo, é necessário e recomendado que altere esses valores para os necessários da sua arquitetura.

## Variáveis que precisam ser alteradas dependendo do sistema:
### no arquivo conta_cron.pl
 - $pasta: É a localização do arquivo onde estão todos os crons. Em geral fica em */var/spool/cron/*
### No arquivo log.pm
 - $file: É o arquivo onde será salvo os logs

## Variáveis adicionais
### no arquivo conta_cron.pl
 - $PONTOS_MINUTOS: É o multiplicador por cada minuto que o cron é executado

 - $PONTOS_HORAS_SOMA: É o multiplicador da soma de execuções por hora. É usado para identificar quando há muitos crons.


