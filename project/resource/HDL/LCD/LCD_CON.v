module LCD_CON#
(
    parameter
    THD    = 800, 
    TVD    = 480,
    
    THB   = 46,
    THFP  = 23,
    THPW  = 20,
    
    TVB   = 23,
    TVFP   = 22,
    TVPW  = 10
)
(
    iCLK, 
    inRST,
    
    oDCLK,
    oDE,
    oMODE,
    onRST,
    
    oHSYNC,
    oVSYNC,
    
    oPOW,
    
    oBRAM_CLK,
    
    oHADDR,
    oVADDR,
    oADDR
);
    function[5:0] bit_fit;
        input reg[31:0] val;
        begin
            bit_fit = 0;
            while(val > 0) begin
                val = val >> 1;
                bit_fit = bit_fit + 1;
            end
        end
    endfunction
    
    // @note. bit_fit(N) == floor(log(N, 2))
    localparam HBW = bit_fit(THD + THB + THFP + THPW - 1);
    localparam VBW = bit_fit(TVD + TVB + TVFP + TVPW - 1);
    localparam ABW = HBW + VBW;
    
    localparam HDBW = bit_fit(THD - 1);
    localparam VDBW = bit_fit(TVD - 1);
    
    // Port declarations
    input iCLK;
    input inRST;
    
    output oDCLK;
    output oDE;
    output oMODE;
    output onRST;
    
    output oHSYNC;
    output oVSYNC;
    output oPOW;
    
    output oBRAM_CLK;
    
    output[HDBW-1:0] oHADDR;
    output[VDBW-1:0] oVADDR;
    output[ ABW-1:0] oADDR;
    
    // Port registers
    reg oHSYNC;
    reg oVSYNC;
    // reg oDE;
    // reg oBRAM_CLK;
    
    reg[HDBW-1:0] oHADDR;
    reg[VDBW-1:0] oVADDR;
    reg[ ABW-1:0] oADDR;

    // Local variable declarations
    reg[HBW-1:0] hcnt;
    reg[VBW-1:0] vcnt;

    // Route port
    assign oMODE = 1;
    assign oPOW = 1;
    assign onRST = inRST;
    
    assign oDCLK = iCLK;
    assign oBRAM_CLK = oDE & oDCLK;
    
    // Logics
    // always @(oDCLK) oBRAM_CLK <= oDE;
    
    // State counter
    always @(posedge iCLK or negedge inRST) begin
        if(~inRST)
            hcnt <= 0;
        else 
            hcnt <= hcnt < THD + THB + THFP + THPW ? hcnt + 1 : 0;
    end
    
    always @(posedge oHSYNC or negedge inRST) begin
        if(~inRST) 
            vcnt <= 0;
        else 
            vcnt <= vcnt < TVD + TVB + TVFP + TVPW ? vcnt + 1 : 0;
    end

    // Address assignment
    always @(posedge oDCLK) begin
        oHADDR <=   oDE ? hcnt - THPW - THB : 0;
        oVADDR <=   oDE ? vcnt - TVPW - TVB : 0;
        oADDR  <=   ~oVSYNC 
                    ? 0 
                    : oDE 
                        ? oADDR + 1 
                        : oADDR;
    end

    // Horizontal generator    
    always @(posedge oDCLK) begin
        if     (hcnt < THPW) begin
            oHSYNC <= 0;
            // oDE <= 0;
        end
        else if(hcnt < THPW + THB) begin 
            oHSYNC <= 1;
            // oDE <= 0;
        end
        else if(hcnt < THPW + THB + THD) begin
            oHSYNC <= 1;
            // oDE <= TVPW + TVB <= vcnt && vcnt < TVPW + TVB + TVD;
        end
        else if (hcnt < THPW + THB + THD + THFP) begin
            oHSYNC <= 1;
            // oDE <= 0;
        end
    end
    assign oDE  =  THPW + THB <= hcnt && hcnt < THPW + THB + THD
                && TVPW + TVB <= vcnt && vcnt < TVPW + TVB + TVD;
    
    always @(posedge oDCLK) begin
        if (vcnt < TVPW) 
            oVSYNC <= 0;
        // Can be omitted.
        // else if(vcnt < TVPW + TVB)
        //     oVSYNC <= 1;
        // else if(vcnt < TVPW + TVB + TVD)
        //     oVSYNC <= 1;
        // ~
        else if(vcnt < TVPW + TVB + TVD + TVFP) 
            oVSYNC <= 1;
    end
endmodule
 
`timescale 1ns / 1ns
module TFT_DRIVE_CON_testbench;
    
    reg iCLK = 0;
    reg inRST = 1;
    wire oDCLK;
    wire oDE;
    wire oMODE;
    wire onRST;
    wire oHSYNC;
    wire oVSYNC;
    wire oPOW;
    wire oBRAM_CLK;
    wire[9:0] oHADDR;
    wire[8:0] oVADDR;
    TFT_DRIVE_CON tft_drive_con
    (
        .iCLK(iCLK), 
        .inRST(inRST),
        .oDCLK(oDCLK),
        .oDE(oDE),
        .oMODE(oMODE),
        .onRST(onRST),
        .oHSYNC(oHSYNC),
        .oVSYNC(oVSYNC),
        .oPOW(oPOW),
        .oBRAM_CLK(oBRAM_CLK),
        .oHADDR(oHADDR),
        .oVADDR(oVADDR)
    );
    
    always #200 iCLK = ~iCLK;
    
    initial begin
        inRST = 0;
        #4000;
        inRST = 1;
    end
    
endmodule