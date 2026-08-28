/* Copyright 2023 Dual Tachyon
 * https://github.com/DualTachyon
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 */

#include <string.h>

#include "ui/inputbox.h"

char    gInputBox[8];
char    inputBoxAscii[9];
uint8_t gInputBoxIndex;

static KEY_Code_t frequencyInput[10];
static uint8_t frequencyInputIndex;
static uint8_t frequencyInputDotIndex;
static uint32_t frequencyInputValue;
static char frequencyInputString[11];

void INPUTBOX_Append(const KEY_Code_t Digit)
{
    if (gInputBoxIndex >= sizeof(gInputBox))
        return;

    if (gInputBoxIndex == 0)
        memset(gInputBox, 10, sizeof(gInputBox));

    if (Digit != KEY_INVALID)
        gInputBox[gInputBoxIndex++] = (char)(Digit - KEY_0);
}

const char* INPUTBOX_GetAscii()
{
    for(int i = 0; i < 8; i++) {
        char c = gInputBox[i];
        inputBoxAscii[i] = (c==10)? '-' : '0' + c;
    }
    return inputBoxAscii;
}

static void INPUTBOX_ResetFrequency(void)
{
    frequencyInputValue = 0;
    memset(frequencyInputString, '-', sizeof(frequencyInputString) - 1);
    frequencyInputString[sizeof(frequencyInputString) - 1] = '\0';
}

void INPUTBOX_FrequencyBegin(void)
{
    frequencyInputIndex = 0;
    frequencyInputDotIndex = 0;
    INPUTBOX_ResetFrequency();
}

bool INPUTBOX_FrequencyUpdate(const KEY_Code_t key)
{
    if (key != KEY_EXIT && frequencyInputIndex >= 10)
        return false;

    if (key == KEY_STAR) {
        if (frequencyInputIndex == 0 || frequencyInputDotIndex != 0)
            return false;
        frequencyInputDotIndex = frequencyInputIndex;
        frequencyInput[frequencyInputIndex++] = key;
    } else if (key == KEY_EXIT) {
        if (frequencyInputIndex == 0)
            return false;
        frequencyInputIndex--;
        if (frequencyInputDotIndex == frequencyInputIndex)
            frequencyInputDotIndex = 0;
    } else if (key >= KEY_0 && key <= KEY_9) {
        frequencyInput[frequencyInputIndex++] = key;
    } else {
        return false;
    }

    INPUTBOX_ResetFrequency();

    const uint8_t dotIndex = frequencyInputDotIndex == 0
        ? frequencyInputIndex : frequencyInputDotIndex;
    for (uint8_t i = 0; i < frequencyInputIndex; i++) {
        frequencyInputString[i] = frequencyInput[i] <= KEY_9
            ? (char)('0' + frequencyInput[i] - KEY_0) : '.';
    }

    uint32_t base = 100000;
    for (int i = (int)dotIndex - 1; i >= 0; i--) {
        frequencyInputValue += (frequencyInput[i] - KEY_0) * base;
        base *= 10;
    }

    base = 10000;
    for (uint8_t i = dotIndex + 1; i < frequencyInputIndex; i++) {
        frequencyInputValue += (frequencyInput[i] - KEY_0) * base;
        base /= 10;
    }

    return true;
}

bool INPUTBOX_FrequencyIsActive(void)
{
    return frequencyInputIndex != 0;
}

uint8_t INPUTBOX_FrequencyLength(void)
{
    return frequencyInputIndex;
}

uint32_t INPUTBOX_FrequencyValue(void)
{
    return frequencyInputValue;
}

const char *INPUTBOX_FrequencyGetString(void)
{
    return frequencyInputString;
}