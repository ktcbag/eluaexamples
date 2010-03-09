/*
 * ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * Felipe Maimon wrote this file. As long as you retain this notice you
 * can do whatever you want with this stuff. If we meet some day, and you think
 * this stuff is worth it, you can buy me a beer in return.       Felipe Maimon
 * ----------------------------------------------------------------------------
 */

#ifndef _VFD_FSM_H_
#define _VFD_FSM_H_

#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/eeprom.h>
#include <util/delay.h>
#include <util/atomic.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include "VFD.h"
#include "timeout.h"
#include "usart.h"
#include "boost.h"
#include "max6921.h"


// Enum com todos os estados possíveis da máquina de estados

enum estados { SM_IDLE,
				 SM_START, 
					SM_GET_CMD,
						SM_WRITE, SM_WR_SP, SM_WR_KP, SM_WR_KI, SM_WR_LD,
						SM_READ,
				 SM_END,
				 SM_ERROR
				};


/* 
Comandos para o conversor boost:

Todas as mensagens iniciam com o caracter 'b', seguido por um caracter
de comando ('r', para comandos de leitura, ou 'w', para comandos de escrita), 
seguidos de seus parâmetros. Em nenhum parâmetro do conversor boost a string
possui caracteres terminadores, como o /0 do C. Ao final de todos os comandos
de escrita ou leitura, o caracter '!' é enviado para a serial, confirmando que
o comando foi executado. Caso receba "?x" (x é um número), o erro x aconteceu.
Os valores de x estão descritos mais abaixo.

Escrita:
	-  O valor do set-point deverá ser enviado como uma string, com valor em formato 6.2
	  (basicamente basta multiplicar por 4) e deve ter valor entre 20 e 60 volts. Todos
	  os 3 caracteres do valor devem ser enviados. A mudança de set-point gera um pulso
	  no pino PD4 que pode ser utilizado para o trigger do osciloscópio, permitindo ver
	  como a tensão de saída varia ao mudar seu valor.
	  Exemplos:

	  Mudança de set-point para 20 V:  bws080
	  Mudança de set-point para 40 V:  bws160


	- Para os valores de Kp e Ki, basta mandar 4 caracteres numéricos com o valor
	  desejado da constante.
	  Exemplos:

	  Mudança do Kp para 2000:  bwp2000
	  Mudança do Ki para 100 :  bwi0100


	- Mudança de estado do pino PD5. Comando que usei para testar como o conversor
	  responde a variação de cargas. Este comando também gera um pulso no pino PD4
	  para trigger do osciloscópio.
	  Exemplo:

	  Toggle no PD5: bwl

Leitura:
	- Leitura do set point. Retorna o set point no mesmo formato da escrita.
	Exemplo:

	Set point em 20V: brs	-> 080! aparece na serial
	Set point em 40V: brs	-> 160! aparece na serial


	- Leitura dos valores de Kp e e Ki.	Exemplo:
	Ler Kp atual:	brp
	Ler Ki atual:	bri

	- Leitura da tensão de entrada * 10. brv

	- Leitura da tensão de saida * 10. bro

*/
#define CB_INICIO		'b'
#define CB_CMD_RD		'r'
#define CB_CMD_WR		'w'
#define CB_WR_SP		's'
#define CB_WR_KP		'p'
#define CB_WR_KI		'i'
#define CB_WR_LD		'l'
#define CB_RD_SP		's'
#define CB_RD_KP		'p'
#define CB_RD_KI		'i'
#define CB_RD_VI		'v'
#define CB_RD_VO		'o'
#define CB_FINAL_MSG	'!'

// Valores de erro para a máquina de estado
#define CB_ERROR_MSG	'?'
#define CB_ERROR_START	1		// Caracter de início inválido
#define CB_ERROR_CMD	2		// Caracter de comando inválido
#define CB_ERROR_SP		3		// Valor de Set Point inválido
#define CB_ERROR_WR		4		// Caracter de escrita inválido
#define CB_ERROR_RD		5		// Caracter de leitura inválido
#define CB_ERROR_TO		6		// Timeout na serial

#define VFD_INICIO		'v'

void State_Machine (void);

#endif
