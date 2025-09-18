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

## Limitations

The D SDK is currently in development and has the following limitations:

1. **Basic Implementation**: The current implementation provides a foundation but many advanced features are not yet implemented.
2. **Function Bodies**: Function implementations need to be completed.
3. **Container Types**: Full implementation of TArray, TMap, etc. is pending.
4. **Platform Support**: Like the C++ version, this is designed for Windows platforms.

## Contributing

The D SDK generator is designed to be extensible. The main implementation is in:
- `Dumper/Generator/Public/Generators/DGenerator.h`
- `Dumper/Generator/Private/Generators/DGenerator.cpp`

Pull requests to improve the D language support are welcome!