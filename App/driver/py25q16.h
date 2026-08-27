/* Copyright 2025 muzkr
 * https://github.com/muzkr
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

#ifndef DRIVER_PY25Q16_H
#define DRIVER_PY25Q16_H

#include <stdint.h>
#include <stdbool.h>
#define SECTOR_SIZE 0x1000

void PY25Q16_Init();
void PY25Q16_ReadBuffer(uint32_t Address, void *pBuffer, uint32_t Size);
void PY25Q16_WriteBuffer(uint32_t Address, const void *pBuffer, uint32_t Size, bool Append);
void PY25Q16_SectorErase(uint32_t Address);
void PY25Q16_ClearBlockProtect(void);  // clear Block Protect bits before erasing

/* Drop the internal write cache after raw multiboot slot/profile operations,
 * and before multiboot reuses the cache storage as a RAM overlay. */
void PY25Q16_InvalidateCache(void);

#ifdef ENABLE_FEAT_F4HWN_MULTIBOOT
/* Addresses below the calibration boundary are transparently redirected into
 * the selected firmware slot's private settings bank. Calibration, logo,
 * firmware slots and multiboot state remain shared. */
#define PY25Q16_PROFILE_SHARED_FROM  0x00010000u
void PY25Q16_SetProfileBase(uint32_t Base);
#endif

#endif
