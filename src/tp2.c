
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "tp2.h"
#include "helper/tiempo.h"
#include "helper/libbmp.h"
#include "helper/utils.h"
#include "helper/imagenes.h"

#define N 100

// ~~~ seteo de los filtros ~~~

extern filtro_t tresColores;
extern filtro_t efectoBayer;
extern filtro_t cambiaColor;
extern filtro_t edgeSobel;

filtro_t filtros[4];

// ~~~ fin de seteo de filtros ~~~

int main( int argc, char** argv ) {

	filtros[0] = tresColores; 
	filtros[1] = efectoBayer;
	filtros[2] = cambiaColor;
	filtros[3] = edgeSobel;

	configuracion_t config;
	config.dst.width = 0;
	config.bits_src = 32;
	config.bits_dst = 32;

	procesar_opciones(argc, argv, &config);
	// Imprimo info
	if (!config.nombre)
	{
		printf ( "Procesando...\n");
		printf ( "  Filtro             : %s\n", config.nombre_filtro);
		printf ( "  Implementación     : %s\n", C_ASM( (&config) ) );
		printf ( "  Archivo de entrada : %s\n", config.archivo_entrada);
	}

	snprintf(config.archivo_salida, sizeof  (config.archivo_salida), "%s/%s.%s.%s%s.bmp",
             config.carpeta_salida, basename(config.archivo_entrada),
             config.nombre_filtro,  C_ASM( (&config) ), config.extra_archivo_salida );

	if (config.nombre)
	{
		printf("%s\n", basename(config.archivo_salida));
		return 0;
	}

	filtro_t *filtro = detectar_filtro(&config);

	filtro->leer_params(&config, argc, argv);
	correr_filtro_imagen(&config, filtro->aplicador);
//	filtro->liberar(&config);

	return 0;
}

filtro_t* detectar_filtro(configuracion_t *config)
{
	for (int i = 0; filtros[i].nombre != 0; i++)
	{
		if (strcmp(config->nombre_filtro, filtros[i].nombre) == 0)
			return &filtros[i];
	}

	perror("Filtro desconocido\n");
	return NULL; // avoid C warning
}


void imprimir_tiempos_ejecucion(unsigned long long int start, unsigned long long int end, int cant_iteraciones) {
	unsigned long long int cant_ciclos = end-start;

	printf("Tiempo de ejecución:\n");
	printf("  Comienzo                          : %llu\n", start);
	printf("  Fin                               : %llu\n", end);
	printf("  # iteraciones                     : %d\n", cant_iteraciones);
	printf("  # de ciclos insumidos totales     : %llu\n", cant_ciclos);
	printf("  # de ciclos insumidos por llamada : %.3f\n", (float)cant_ciclos/(float)cant_iteraciones);
}

int compare(const void * a, const void * b) 
{ 
    return ( *(int*)a - *(int*)b ); 
} 

void correr_filtro_imagen(configuracion_t *config, aplicador_fn_t aplicador)
{
	imagenes_abrir(config);
	FILE *pfile = fopen(config->nombre_filtro,"a");
	unsigned long long mediciones[N];
	unsigned long long start, end;

	
	for (int i = 0; i < config->cant_iteraciones; i++) {
			MEDIR_TIEMPO_START(start)
			aplicador(config);
			MEDIR_TIEMPO_STOP(end)
			imprimir_tiempos_ejecucion(start, end, config->cant_iteraciones);
			unsigned long long int cant_ciclos = end-start;
			fprintf(pfile,"%llu\n", cant_ciclos);
			mediciones[i] = cant_ciclos;
	}
	qsort(mediciones,N,sizeof(double),compare);
	fprintf(pfile,"%llu\n", mediciones[(N/2)-1]);
	fclose(pfile);

	imagenes_guardar(config);
	imagenes_liberar(config);
	
}



