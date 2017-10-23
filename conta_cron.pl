#!/usr/bin/perl
use v5.10;
use strict;

###################################################################
#  Esse script analisa a pasta onde ficam os crons e verifica     #
# se não há nenhum cliente executando mais que o permitido.       #
#  Caso localize ele altera o cron e abre um chamado informando.  #
# Requisitos: Path::Tiny Data::Uniqid                             #
###################################################################

use Log;

use Path::Tiny qw(path);
use Tie::File;

# Variáveis globais
my $PONTOS_MINUTOS = 1;
my $PONTOS_HORAS_SOMA = 0.15;
my $pasta = "./crontab/";
my $uid;

main();

sub cv_minutos {
    my ($texto) = @_;
    my $pontos;
    my $total;
    my @container; # um array onde cada entrada corresponde a 15 minutos
    if($texto =~ /^\*$/) { # *
	$container[0] = $container[1] = $container[2] = $container[3] = 15;
	$pontos = ($PONTOS_MINUTOS*60)-4; #vezes usadas-que tem direito
    }
    else {
	if($texto =~/^\*\//) { # */numero
	    $' =~ /^[0-9]*/;
	    my $val_corrente = 0;
	    my $val_inicial = $&;
	    while($val_corrente < 60) {
		@container = localiza_conjunto($val_corrente,@container);
		$val_corrente += $val_inicial;
	    }
	}
	else {
	    if ($texto =~ /,/) { # 1,2,3
		my @minutos = split /,/, $texto;
		foreach my $minuto (@minutos) {
		    @container = localiza_conjunto($minuto,@container);
		}
	    }
	    else {
		if ($texto =~ /^[0-9]+/) { # numero
		    @container = localiza_conjunto($&,@container);
		}
		else {
		    @container[0] = -1;
		}
	    }
	}
    }
    $pontos = verifica_pontos(@container);
    $container[5] = $pontos;
    return @container,$pontos;

    sub localiza_conjunto {
	my ($numero,@container) = @_;
	if($numero <15) {
	    $container[0] += 1;
	}
	else {
	    if($numero <30) {
		$container[1] += 1;
	    }
	    else {
		if($numero <45) {
		    $container[2] += 1;
		}
		else {
		    $container[3] += 1;
		}
	    }
	}	
	return @container;
    }
    sub verifica_pontos {
	my(@container) = @_;
	my $pontos;
	foreach my $minutos15 (@container) {
	    my $diferenca = $minutos15 ? $minutos15-1 : 0;
	    $pontos += $diferenca*$PONTOS_MINUTOS ;
	}
	return $pontos;
    }
}
sub cv_horas {
    my ($texto) = @_;
    my %container;
    if($texto =~ /^\*$/) { # *
	$container{"todas"} = 1;
    }
    else {
	if($texto =~ /^\*\//) { # */numero
	    $' =~ /^[0-9]*/;
	    my $diferenca = $&;
	    my @todas_horas = ();
	    for (my $i=0; $i <= 23; $i += $diferenca) {
		push @todas_horas, $i;
	    }
	    $container{"lista_horas"} = \@todas_horas;
	}
	else {
	    if ($texto =~ /,/) { # 1,2,3
		my @todas_horas = split /,/, $texto;
		$container{"lista_horas"} = \@todas_horas;
	    }
	    else {
		if ($texto =~ /[0-9]+/) { # numero
		    my @todas_horas = ($texto);
		    $container{"lista_horas"} = \@todas_horas;
		}
		else {
		    $container{"error"} = 1;
		}
	    }
	}
    }

    return %container;
}
sub test_cv { #testa o módulo de minutos
    
    # use Test::Simple tests => 7;
    
    my @test_minutos = cv_minutos("*");
      ok ($test_minutos[0] == 15, "60 por hora");
    @test_minutos = cv_minutos("*/10");
      ok ($test_minutos[3] == 2, "executado a cada 10 minutos");
    @test_minutos = cv_minutos("8,23,39,47");
      ok ($test_minutos[1] == 1, " modelo 1,2,3 retorno direto ");
    @test_minutos = cv_minutos(12);
    ok ($test_minutos[0] == 1, "valor numerico");
    ok (cv_minutos("abas") == -1, "valor inválido");

}

sub test_cv_com_horas {
    # use Test::Simple tests => 10;

    #--test1 Tudo *
    my $test1 = "* * * * teste.sh";
    my ($minuto, $hora,$resto) = (split / /, $test1, 3);
    my @test_minuto = cv_minutos($minuto);
      ok($test_minuto[2] == 15, "Todos minutos");
    my %vezes_hora = cv_horas($hora);
      ok($vezes_hora{"todas"} == 1 , "Todas horas");
    
    #--test2 de tempos em tempos
    my $test2 = "*/10 */20 * * teste.sh";
    my ($minuto, $hora,$resto) = (split / /, $test2, 3);
    @test_minuto = cv_minutos($minuto);
      ok($test_minuto[2] == 2, "de 10 em 10 minutos");
    #todas as horas = *
    my %vezes_hora = cv_horas($hora);
    ok($vezes_hora{"lista_horas"}[1] == 20 , "Todas específicas");

    #--test3 valores fixos com ,
    my $test2 = "5,10 2,5 * * teste.sh";
    my ($minuto, $hora,$resto) = (split / /, $test2, 3);
    @test_minuto = cv_minutos($minuto);
     ok($test_minuto[0] == 2, "5 e 10 minutos");
    my %vezes_hora = cv_horas($hora);
     ok($vezes_hora{"lista_horas"}[1] == 5 , "2 e 5 horas");
    
    #--test4 valores fixos unitários
    my $test3 = "10 5 * * teste.sh";
    my ($minuto, $hora,$resto) = (split / /, $test3, 3);
    ok(cv_minutos($minuto) == 1, "10 minutos");
    my %vezes_hora = cv_horas($hora);
    ok($vezes_hora{"lista_horas"}[0] == 5 , "5 horas");

    #--test5 valores errados
    my $test4 = "a b * * teste.sh";
    my ($minuto, $hora,$resto) = (split / /, $test4, 3);
    @test_minuto = cv_minutos($minuto);
    ok($test_minuto[0] == -1, "minuto não reconhecido");
    %vezes_hora = cv_horas($hora);
    ok($vezes_hora{"error"} == 1 , "hora não reconhecida");
}

sub main {
    my @files = path($pasta)->children;
    foreach my $arquivo ( @files ) {

	if(path($arquivo)->basename eq "root") {
	    #Root manda. Não tem restrição
	    next;
	}
	    
	use Data::Uniqid qw ( luniqid );
	$uid = luniqid;
	
	Log::write($uid, "iniciando a analise da conta " . path($arquivo)->basename);
	
    	my %horas;
	my @pontos; # 0= minutos; 1= soma_horas

	my ($horas_ref, $pontos_ref) = analisa_cronfile($arquivo, %horas, @pontos);

	%horas = %$horas_ref;
	@pontos = @$pontos_ref;
	
	Log::write($uid,"horarios");
	
	foreach my $horario (sort keys %horas) {
	    my $total;
	    my $container = "$horario = ";
	    for(my $i = 1; $i <= 4; $i++) {
		my $valor_minutos;
		if($horario =~ /[0-9]/ ) { #adiciona o que já executado sempre em todas as horas
		    $valor_minutos = $horas{$horario}{'minutos'}[$i-1]+$horas{"todas"}{'minutos'}[$i-1];
		}
		else {
		    $valor_minutos = $horas{$horario}{'minutos'}[$i-1];
		}
		my $mult = $i*15;
		if ($horas{$horario}{'minutos'}[$i-1]) {
		    $container = $container . "[". ($mult-15) . "-" . ($mult-1) . "] = " . $valor_minutos . "; ";
		    $total += $valor_minutos;
		}
	    }
	    $container = $container . "total = $total";
	    Log::write($uid,$container);
	    
	    my $soma = ($total-4)*$PONTOS_HORAS_SOMA;
	    #$pontos[1] += ($soma > 0 ? $soma : 0);
	}
	Log::write($uid,"pontos: minutos = " . $pontos[0] . "; horas = " . $pontos[1]);
	my $total_pontos = ($pontos[0]+$pontos[1]);
	Log::write($uid,"total de pontos = " . $total_pontos);

	if($total_pontos > 4) { ## Cron será alterado
	    Log::write($uid,"precisa alterar");

            # Salva o Cron antes e depois da alteração para caso queira enviar um e-mail ou procedimento similar
	    my $cron_anterior = $arquivo->slurp_utf8; 
	    mudar_cron($arquivo, @pontos);
	    my $cron_posterior = $arquivo->slurp_utf8;
	    
	    my %novas_horas;
	    my @novos_pontos; # 0= minutos; 1= soma_horas
	    
	    # Nova análise após a alteração
	    my ($horas_ref, $pontos_ref) = analisa_cronfile($arquivo, %novas_horas, @novos_pontos);
	    
	    %novas_horas = %$horas_ref;
	    @novos_pontos = @$pontos_ref;

	}
	Log::write($uid, "fim da análise da conta " . path($arquivo)->basename);
    }
}
sub analisa_cronfile {
    my ($arquivo, %horas, @pontos) = @_;

    my @lines = $arquivo->lines_utf8;

    foreach my  $line ( @lines ) {
	chomp($line);
	if($line =~ /^(#|MAILTO|SHELL)/) {
	    #não analisa linhas desnecessarias
	    next;
	}
	
	my ($hora_ref,$pontos_ref) = analisa_cron($line,\%horas, @pontos);
	@pontos = @$pontos_ref;
	%horas = %$hora_ref;
    }
    foreach my $horario (sort keys %horas) {
	my $total;
	#Log::write($uid,"Buscando bug = $horario");
	for(my $i = 1; $i <= 4; $i++) {
	    my $valor_minutos;
	    if($horario =~ /[0-9]/ && exists $horas{"todas"} ) { #adiciona o que já executado sempre em todas as horas
		$valor_minutos = $horas{$horario}{'minutos'}[$i-1]+$horas{"todas"}{'minutos'}[$i-1];
	    }
	    else {
		$valor_minutos = $horas{$horario}{'minutos'}[$i-1];
	    }

	    if ($horas{$horario}{'minutos'}[$i-1]) {
		$total += $valor_minutos;
	    }
	}
	my $soma = ($total-4)*$PONTOS_HORAS_SOMA;
	$pontos[1] += ($soma > 0 ? $soma : 0);
    }
    return (\%horas, \@pontos);
}
sub analisa_cron {
    my ($line,$horas_ref, @pontos) = @_;
    my %horas = %$horas_ref;
    my ($minuto, $hora,$resto) = (split / /, $line, 3);
    my %vezes_hora = cv_horas($hora);
    my @minutos = cv_minutos($minuto);
    
    if($vezes_hora{"error"} == 1 | $minutos[0] == -1) {
	Log::write($uid,"valor não identificado: $line");
	next;
    }
    $pontos[0] += $minutos[5];
    Log::write($uid,$line);
    if($vezes_hora{"todas"}){
	#print "todas horas\n";
	$horas{"todas"}{'minutos'}[0] += $minutos[0];
	$horas{"todas"}{'minutos'}[1] += $minutos[1];
	$horas{"todas"}{'minutos'}[2] += $minutos[2];
	$horas{"todas"}{'minutos'}[3] += $minutos[3];
    }
    else {
	for $hora (@{$vezes_hora{"lista_horas"}}) {
	    $horas{$hora}{'minutos'}[0] += $minutos[0];
	    $horas{$hora}{'minutos'}[1] += $minutos[1];
	    $horas{$hora}{'minutos'}[2] += $minutos[2];
	    $horas{$hora}{'minutos'}[3] += $minutos[3];
	}
    }
    return (\%horas,\@pontos);
}
sub mudar_cron {
    
    my ($arquivo, @pontos) = @_;
    Log::write($uid, "Mudando " . path($arquivo)->basename);

    path($arquivo)->copy("/tmp/" . path($arquivo)->basename); #arquivo para edição
    path($arquivo)->copy("/tmp/" . path($arquivo)->basename . ".bkp"); #arquivo de backup
    
    tie my @array, 'Tie::File',  "/tmp/" . path($arquivo)->basename or die "erro";
    if($pontos[1] > $pontos[0]) {#pontosHora > pontosMinutos
	Log::write($uid,"mudando hora");
	my $hora = 1;
	foreach my $line (@array) {
	    $line =~ s/^[^\ ]+ [^\ ]+/\*\/20 $hora/g;
	    $hora = ($hora == 23 ? 0 : $hora+1);
	}	
    }else {
	Log::write($uid,"mudando minutos");
	foreach my $line (@array) {
	    $line =~ s/^\* /\*\/20 /g;
	    $line =~ s/^\*\/1?[0-9] /\*\/20 /g;
	}
    }
    my $comando = "crontab -u " . path($arquivo)->basename . " /tmp/" . path($arquivo)->basename;
    `$comando`;
}
