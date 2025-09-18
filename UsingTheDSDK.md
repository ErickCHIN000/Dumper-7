# Using the D SDK

## Overview

Dumper-7 now supports generating SDK files for the D programming language in addition to the traditional C++ SDK. The D SDK provides D language bindings for Unreal Engine games, allowing you to write game modifications and tools using D instead of C++.

## Generating the D SDK

The D SDK generation is enabled by default. You can control this behavior in the `Settings.h` file:

```cpp
namespace DGenerator
{
    /* Whether the D language SDK generation is enabled */
    constexpr bool bEnabled = true;

    /* No prefix for files->FilePrefix = "" */
    constexpr const char* FilePrefix = "";

    /* Whether to generate D-style naming conventions (camelCase vs PascalCase) */
    constexpr bool bUseDNamingConventions = true;
}
```

## SDK Structure

When enabled, the D SDK will be generated in the `DSDK` folder alongside the `CppSDK` folder:

```
C:\Dumper-7\GameName-GameVersion\
├── CppSDK/          # C++ SDK files
└── DSDK/            # D SDK files
    ├── SDK.d        # Main SDK module (imports all others)
    ├── Basic.d      # Basic type definitions
    ├── UnrealContainers.d  # Container type implementations
    ├── PropertyFixup.d     # Property fixup utilities
    └── SDK/         # Generated package modules
        ├── Engine_classes.d
        ├── Engine_structs.d
        ├── CoreUObject_classes.d
        └── ...
```

## Type Mappings

The D SDK automatically converts C++ types to their D equivalents:

| C++ Type | D Type |
|----------|--------|
| `int8`   | `byte` |
| `uint8`  | `ubyte` |
| `int16`  | `short` |
| `uint16` | `ushort` |
| `int32`  | `int` |
| `uint32` | `uint` |
| `int64`  | `long` |
| `uint64` | `ulong` |
| `float`  | `float` |
| `double` | `double` |
| `bool`   | `bool` |
| `void`   | `void` |
| `Type*`  | `Type*` |
| `Type&`  | `Type*` (references become pointers) |
| `const Type` | `const(Type)` |

## Using the D SDK

1. **Import the SDK**: Add the generated SDK to your D project's import path.

2. **Import modules**: Import the main SDK module or specific modules:
   ```d
   import sdk;  // Import everything
   
   // Or import specific modules
   import sdk.engine_classes;
   import sdk.coreuobject_structs;
   ```

3. **Use UE types**: The generated D code provides access to all Unreal Engine classes, structures, and enums:
   ```d
   // Example usage (syntax will depend on actual implementation)
   import sdk;
   
   void main()
   {
       // Access UE objects and call functions
       // Note: This is a conceptual example - actual usage depends on 
       // the specific game and generated SDK
   }
   ```

## Configuration Options

You can configure the D SDK generation through the `Settings.h` file:

- `bEnabled`: Enable/disable D SDK generation
- `FilePrefix`: Add a prefix to all generated D files
- `bUseDNamingConventions`: Use D-style naming (camelCase) instead of UE naming

## Current Status

The D SDK generation includes:

1. **Complete Infrastructure**: Full D generator integrated into the build system
2. **Type System**: Automatic conversion from C++ to D types (int8→byte, uint8→ubyte, etc.)
3. **Module System**: D-style modules with proper import statements
4. **Container Types**: TArray with D-style operations (slicing, foreach support, etc.)
5. **UE Types**: FString, FName, FText, FVector, FRotator, FLinearColor implementations
6. **Enum Generation**: Complete enum generation with D syntax
7. **Struct Generation**: Foundation for struct and class generation

### Features Implemented

- ✅ **Basic Type Conversion**: All fundamental types mapped to D equivalents
- ✅ **Container Support**: TArray with D-style slicing and range interface
- ✅ **UE Core Types**: Basic implementations of FString, FName, FVector, etc.
- ✅ **Enum Generation**: Full enum support with proper D syntax
- ✅ **Module System**: Proper D module declarations and imports
- ✅ **Configuration**: Enable/disable via Settings.h
- ✅ **Memory Layout**: Proper padding and alignment preservation

## Contributing

The D SDK generator is designed to be extensible. The main implementation is in:
- `Dumper/Generator/Public/Generators/DGenerator.h`
- `Dumper/Generator/Private/Generators/DGenerator.cpp`

Pull requests to improve the D language support are welcome!