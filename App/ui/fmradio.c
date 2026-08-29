/* Copyright 2023 Dual Tachyon
 * https://github.com/DualTachyon
 *
 * OURO_KA52 FM UI
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

#ifdef ENABLE_FMRADIO

#include <string.h>

#include "app/fm.h"
#include "driver/st7565.h"
#include "external/printf/printf.h"
#include "settings.h"
#include "ui/helper.h"
#include "ui/ui.h"

void UI_DisplayFM(void)
{
    char String[16];
    char memoryString[8];

    memset(gFrameBuffer, 0, sizeof(gFrameBuffer));
    
    for (uint8_t i = 2; i < FRAME_LINES; i++) 
    {
        gFrameBuffer[i][40] = 0xFF; 
        gFrameBuffer[i][41] = 0xFF; 
        gFrameBuffer[i][84] = 0xFF; 
        gFrameBuffer[i][85] = 0xFF; 
    }

    for (uint8_t x = 0; x < LCD_WIDTH; x++) 
    {
        gFrameBuffer[3][x] |= 0x08;
        gFrameBuffer[5][x] |= 0x08;
    }
    // Frequency in a large digital font, centered in the top area.
    memset(String, 0, sizeof(String));
    sprintf(String, "%3d.%d",
            gEeprom.FM_FrequencyPlaying / 10,
            gEeprom.FM_FrequencyPlaying % 10);
    UI_PrintString(String, 0, 128, 0, 10);

    // Keep the current scan and receiver states visible without borders.
    if (gFM_ManualMode)
        GUI_DisplaySmallestDark("MAN", 102, 6, false, true);
    else
        GUI_DisplaySmallestDark("AUTO", 102, 6, false, true);
    if (gFM_No_Rx)
        GUI_DisplaySmallestDark("NO RX", 3, 6, false, true);
    else
        GUI_DisplaySmallestDark("RX ON", 3, 6, false, true);

    // Nine frequency memory slots in a 3 x 3 grid.  The normal font polarity
    // leaves the LCD background clear and avoids separator lines.
    static const uint8_t memoryX[9] = {2, 44, 88, 2, 44, 88, 2, 44, 88};
    static const uint8_t memoryPage[9] = {2, 2, 2, 4, 4, 4, 6, 6, 6};

    for (uint8_t i = 0; i < 9; i++) {
        uint16_t frequency = gFM_Memory[i];
        if (frequency != 0)
            sprintf(memoryString, "%03d.%d", frequency / 10, frequency % 10);
        else
            sprintf(memoryString, " M%d",i+1);
        UI_PrintStringSmallBold(memoryString, memoryX[i], 0, memoryPage[i]);
    }

    ST7565_BlitFullScreen();
}

#endif
