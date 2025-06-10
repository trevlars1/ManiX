#import "N64ObjC.h"
#include "api/m64p_types.h"
#include "api/m64p_frontend.h"
#include "api/m64p_plugin.h"
#include "api/m64p_debug.h"

#include <stdio.h>
#include <stdlib.h>

@implementation N64ObjC

+ (instancetype)sharedInstance {
    static N64ObjC *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[N64ObjC alloc] init];
    });
    return sharedInstance;
}

- (void)startup {
    if (CoreStartup(FRONTEND_API_VERSION, 0, NULL, NULL, NULL) != M64ERR_SUCCESS) {
        printf("CoreStartup failed\n");
    } else {
        printf("Mupen64Plus core started\n");
    }
}

- (void)loadROM:(NSString *)path {
    FILE *f = fopen([path UTF8String], "rb");
    if (!f) {
        printf("Failed to open ROM file\n");
        return;
    }

    fseek(f, 0, SEEK_END);
    int size = ftell(f);
    rewind(f);

    uint8_t *romData = (uint8_t *)malloc(size);
    fread(romData, 1, size, f);
    fclose(f);

    if (CoreDoCommand(M64CMD_ROM_OPEN, size, romData) != M64ERR_SUCCESS) {
        printf("ROM failed to load\n");
    } else {
        printf("ROM loaded successfully\n");
    }

    free(romData);
}

- (void)runFrame {
    CoreDoCommand(M64CMD_EXECUTE_FRAME, 0, NULL);
}

- (void)shutdown {
    CoreDoCommand(M64CMD_ROM_CLOSE, 0, NULL);
    CoreShutdown();
    printf("Mupen64Plus core shut down\n");
}

@end
