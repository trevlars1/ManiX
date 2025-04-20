//
//  NESEmulatorBridge.hpp
//  ManicEmu
//
//  Created by Riley Testut on 6/1/18.
//  Copyright © 2018 Riley Testut. All rights reserved.
//
//  Created by Aushuang Lee on 2025/3/6.
//  Copyright © 2025 Manic EMU. All rights reserved.

#ifndef NESEmulatorBridge_hpp
#define NESEmulatorBridge_hpp

#include <stdio.h>

#if defined(__cplusplus)
extern "C"
{
#endif
    typedef void (*BufferCallback)(const unsigned char *_Nonnull buffer, int size);
    typedef void (*VoidCallback)(void);
    
    double NESFrameDuration();
    
    void NESInitialize(const char *_Nonnull databasePath);
    
    bool NESStartEmulation(const char *_Nonnull gamePath);
    void NESStopEmulation();
    
    void NESRunFrame();
    
    void NESActivateInput(int input, int playerIndex);
    void NESDeactivateInput(int input, int playerIndex);
    void NESResetInputs();
    
    void NESSaveSaveState(const char *_Nonnull saveStatePath);
    void NESLoadSaveState(const char *_Nonnull saveStatePath);
    
    void NESSaveGameSave(const char *_Nonnull gameSavePath);
    void NESLoadGameSave(const char *_Nonnull gameSavePath);
    
    bool NESAddCheatCode(const char *_Nonnull cheatCode);
    void NESResetCheats();
    
    void NESSetAudioCallback(_Nullable BufferCallback audioCallback);
    void NESSetVideoCallback(_Nullable BufferCallback videoCallback);
    void NESSetSaveCallback(_Nullable VoidCallback saveCallback);
    
#if defined(__cplusplus)
}
#endif

#endif /* NESEmulatorBridge_hpp */
