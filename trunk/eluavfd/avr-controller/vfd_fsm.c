/*
 * ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * Felipe Maimon wrote this file. As long as you retain this notice you
 * can do whatever you want with this stuff. If we meet some day, and you think
 * this stuff is worth it, you can buy me a beer in return.       Felipe Maimon
 * ----------------------------------------------------------------------------
 */

#include "vfd_fsm.h"


// Só são usados aqui
enum estados CurState = SM_IDLE;

uint8_t TipoErro;
uint8_t SP_cntr;
uint16_t SP_novo;

void State_Machine (void)
{
	uint8_t uart_tmp;
	char buffer[8];

	// Início da máquina de estados para leitura da serial
		
	// Se deu timeout
	if (TimeOut)
	{
		CurState = SM_ERROR;
		TipoErro = CB_ERROR_TO;
		TOTicks = 0;
		TimeOut = FALSE;
	}

	// Se tiver algo no buffer, executa a máquina de estados.
	else if (CurState != SM_IDLE)
	{
		// Reseta os timers e contador de timeout para a serial
		TCNT2 = 0;					// Zera o timer 2
		GTCCR |= (1<<PSRASY);		// Zera o prescaler do timer2
		TOTicks = 0;
		TimeOut = FALSE;
	}

	switch (CurState)
	{
		case SM_IDLE:
			if (uart_rx_buffer_empty() == 0)		// Se tem alguma coisa no buffer
			{
				CurState = SM_START;
				TCCR2B = (1<<CS22) | (1<<CS21) | (1<<CS20);	// Inicia Timer2 p/ Timeout
			}
			break;

		// Confere se o primeiro byte é 'b', já que todos os comandos começam com ele
		case SM_START:
			if (CB_INICIO == uart_getc())
			{
					CurState = SM_GET_CMD;
			}
			else
			{
				CurState = SM_ERROR;
				TipoErro = CB_ERROR_START;
			}
			break;
				
		// Segundo byte - byte de comando
		// Verifica se é leitura ou escrita
		case SM_GET_CMD:

			switch (uart_getc())
			{
				case CB_CMD_RD:
					CurState = SM_READ;
					break;

			// Se for escrita, também inicializa as variáveis para
			// leitura dos novos valores
				case CB_CMD_WR:
					CurState = SM_WRITE;
					SP_cntr = 0;
					SP_novo = 0;
					break;

				default:
					CurState = SM_ERROR;
					TipoErro = CB_ERROR_CMD;
					break;
			}
			break;

		// Veririfica qual variável se quer escrever
		// Atualmente só pode mexer no set-point
		case SM_WRITE:
			switch (uart_getc())
			{
				case CB_WR_SP:
					CurState = SM_WR_SP;
					break;

				case CB_WR_KP:
					CurState = SM_WR_KP;
					break;

				case CB_WR_KI:
					CurState = SM_WR_KI;
					break;

				case CB_WR_LD:
					CurState = SM_WR_LD;
					break;

				default:
					CurState = SM_ERROR;
					TipoErro = CB_ERROR_WR;
					break;
			}
			break;

		// Lê os próximos 3 bytes que terão o valor do novo set point
		case SM_WR_SP:
			uart_tmp = uart_getc();

			// só aceita se for número
			if ((uart_tmp >='0') && (uart_tmp <= '9'))
			{
				SP_novo *= 10;
				SP_novo += uart_tmp - '0';		// converte para valor numérico
				SP_cntr++;

				if (SP_cntr > 2)				// Se já leu os 3 bytes
				{
					// verifica se está dentro da faixa aceitável
					if ((SP_novo >= 80 ) && (SP_novo <= 240))
					{
						// Converte e salva o valor do set-point novo
						// Teoricamente deveria multiplicar por 3,92, mas como
						// não dá, faz uma leve gambiarra para somente utilizar 
						// números inteiros.
						SP_novo = ((SP_novo * 136 + 25) / 50);

						ATOMIC_BLOCK(ATOMIC_FORCEON)
						{
							tPIsat_params.sp = SP_novo;
						}

						OSC_TRIGGER;

						eeprom_write_word(&ee_PI_SP, SP_novo);

						CurState = SM_END;
					}
					else 
					{
						CurState = SM_ERROR;
						TipoErro = CB_ERROR_SP;
					}
				}
			}
			else
			{
				CurState = SM_ERROR;
				TipoErro = CB_ERROR_SP;
			}
			break;

		// Lê os próximos 4 bytes que terão o valor do novo KP ou KI
		case SM_WR_KP: case SM_WR_KI:
			uart_tmp = uart_getc();

			// só aceita se for número
			if ((uart_tmp >='0') && (uart_tmp <= '9'))
			{
				SP_novo *= 10;
				SP_novo += uart_tmp - '0';		// converte para valor numérico
				SP_cntr++;

				if (SP_cntr > 3)				// Se já leu os 3 bytes
				{
					ATOMIC_BLOCK(ATOMIC_FORCEON)
					{
						if (SM_WR_KP == CurState)
						{
							tPIsat_params.w_kp_pu = SP_novo;
						}
						else
						{
							tPIsat_params.w_ki_pu = SP_novo;
						}
						tPIsat_params.l_integrator_dpu = 0;
					}

					if (SM_WR_KP == CurState)
					{
						eeprom_write_word(&ee_PI_kp, SP_novo);
					}
					else
					{
						eeprom_write_word(&ee_PI_ki, SP_novo);
					}

					CurState = SM_END;
				}
			}
			else
			{
				CurState = SM_ERROR;
				TipoErro = CB_ERROR_SP;
			}
			break;

		// Just toggle PD5
		case SM_WR_LD:
			OSC_TRIGGER;

			PIND |= (1<<PD5);			// Toggle PD5
			CurState = SM_END;
			break;

		// Em caso de leitura, verifica qual o valor que se quer ler
		case SM_READ:
			switch (uart_getc())
			{
				case CB_RD_SP:
					sprintf(buffer, "%03d", (tPIsat_params.sp * 50 + 68) / 136);
					break;

				case CB_RD_KP:
					sprintf(buffer, "%04d", tPIsat_params.w_kp_pu);
					break;

				case CB_RD_KI:
					sprintf(buffer, "%04d", tPIsat_params.w_ki_pu);
					break;

				case CB_RD_VI:
					sprintf(buffer, "%03d", (VoltInp * 10 + 41) / 82);
					break;

				case CB_RD_VO:
					ATOMIC_BLOCK(ATOMIC_FORCEON)
					{
						SP_novo = tPIsat_params.pv;
					}					
					sprintf(buffer, "%03d", (SP_novo * 100) / 272);
					break;
				
				default:
					CurState = SM_ERROR;
					TipoErro = CB_ERROR_RD;
					break;
			}

			if (CurState != SM_ERROR)
			{
				uart_puts(buffer);
				CurState = SM_END;
			} 
			break;

		case SM_END:
			TCCR2B = 0;					// Para Timer2
			uart_putc(CB_FINAL_MSG);
			CurState = SM_IDLE;
			break;

		case SM_ERROR:
			TCCR2B = 0;					// Para Timer2
			uart_putc(CB_ERROR_MSG);
			uart_putc(TipoErro + '0');
			CurState = SM_IDLE;
			break;

	}
}
