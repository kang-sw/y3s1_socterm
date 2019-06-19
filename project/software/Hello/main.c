#include <system.h>
#include <stdio.h>
#include "gppcu.h"
#include <altera_avalon_pio_regs.h>
#include <nios2.h>
#include <string.h>


#define countof(v) (sizeof(v)/sizeof(*v))
#define BOOL int
#define TRUE 1
#define FALSE 0

void wait(int val)
{
	for(int i =0; i < val; ++i)
	{
		// nop;
	}
}

BOOL display_stat()
{
    BOOL prun, pdone;
    uint8_t szpertask, popmemend, popmemhead, ponumcycles, pocurcycleidx;
    gppcu_stat( &prun, &pdone, &szpertask, &popmemend, &popmemhead, &ponumcycles, &pocurcycleidx );
    printf(
        "is running ? %d\n"
        "is done ? %d\n"
        "sz per task: %d \n"
        "mem: %d/%d \n"
        "cycle: %d/%d \n",
        prun, pdone, szpertask, popmemhead, popmemend, pocurcycleidx, ponumcycles
    );
    return pdone;
}

int main()
{ 
	printf("Hello from Nios II! ... Launching ... \n");
      
#define INSTR_BUNDLE \
	    GPPCU_ASSEMBLE_INSTRUCTION_C(COND_ALWAYS, OPR_C_MVI, FALSE, 0x1, 0),                 \
    GPPCU_ASSEMBLE_INSTRUCTION_C( COND_ALWAYS, OPR_C_MVI, FALSE, 0x2, 0 ),                   \
        GPPCU_ASSEMBLE_INSTRUCTION_A( COND_ALWAYS, OPR_LDL, FALSE, 0x0, 0, 0, 0x2 ),         \
        GPPCU_ASSEMBLE_INSTRUCTION_A( COND_ALWAYS, OPR_STL, FALSE, 0b0, 0x0, 1, 0x1 ),       \
        GPPCU_ASSEMBLE_INSTRUCTION_A( COND_ALWAYS, OPR_STL, FALSE, 0b0, 0x0, 2, 0x1 ),       \
        GPPCU_ASSEMBLE_INSTRUCTION_A( COND_ALWAYS, OPR_STL, FALSE, 0b0, 0x0, 3, 0x1 ),       \
        GPPCU_ASSEMBLE_INSTRUCTION_A( COND_ALWAYS, OPR_STL, FALSE, 0b0, 0x0, 4, 0x1 ),       \
        GPPCU_ASSEMBLE_INSTRUCTION_A( COND_ALWAYS, OPR_STL, FALSE, 0b0, 0x0, 5, 0x1 ),       \
        GPPCU_ASSEMBLE_INSTRUCTION_A( COND_ALWAYS, OPR_LDL, FALSE, 0x2, 0b0, 5, 0x1 ),       \
        GPPCU_ASSEMBLE_INSTRUCTION_A( COND_ALWAYS, OPR_0_LSL, FALSE, 0x2, 0x2, 0, 0x2 ),     \
        GPPCU_ASSEMBLE_INSTRUCTION_A( COND_ALWAYS, OPR_STL, FALSE, 0b0, 0x2, 6, 0x1 ),
    uint32_t instrs[] = 
    {
        INSTR_BUNDLE
    };

    swk_gppcu gppcu;

    gppcu.MMAP_CMDOUT = PIO_CMD_BASE;
    gppcu.MMAP_DATIN = PIO_DATAIN_BASE;
    gppcu.MMAP_DATOUT = PIO_DATAOUT_BASE;

    gppcu_init( &gppcu, 24, 1024, 512 );
    gppcu_init_task( &gppcu, 16, 24 );
    memcpy( gppcu.marr, instrs, sizeof( instrs ) );
    gppcu.mnum = countof( instrs );

	int cc = 0;
	while(1)
	{ 
		++cc;
		
		printf("--- STEP %d ---\n", cc);
		const int max_iter = 16;
		const int max_rot  = 4;
		
		for(int i = 0; i < max_rot; ++i)
		{
			for(int j = 0; j < max_iter; ++j)
			{
				gppcu_data_wr_slow(i, j, j == 0 ? (i << 16) + cc : 0);
			}
		}
		
        gppcu_program_autofeed_device( &gppcu );
        while ( !display_stat() ); 
        wait( 5000000 );
        
        for(int rot = 0; rot < max_rot; ++rot)
        {
            printf("for thread %d\n", rot);
            for(int i=0; i<max_iter; ++i)
            {
                printf("%9x", i);
            }
            printf("\n");
            for(int i=0; i<max_iter; ++i)
            {
                gppcu_data_rd_slow(rot, i);
                printf("%9x", gppcu_data_rd_slow(rot, i));
            }
            printf("\n");
        } 
	} 
    //*/
	return 0;
}
