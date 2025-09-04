module settings;

import std.string;
import std.stdio;
import std.file;
import std.conv;
import std.algorithm;
import core.sys.windows.windows;

import unreal.enums;

struct Settings
{
    static bool is32Bit()
    {
        version(Win64)
            return false;
        else version(Win32)
            return true;
        else
            return false;
    }

    static immutable string globalConfigPath = "C:/Dumper-7/Dumper-7.ini";

    struct Config
    {
        static int sleepTimeout = 0;
        static string sdkNamespaceName = "SDK";

        static void load()
        {
            import std.path : buildPath;
            import std.file : getcwd, exists;

            // Try local Dumper-7.ini
            string localPath = buildPath(getcwd(), "Dumper-7.ini");
            string configPath = null;

            if (exists(localPath))
            {
                configPath = localPath;
            }
            else if (exists(globalConfigPath))
            {
                configPath = globalConfigPath;
            }

            // If no config found, use defaults
            if (configPath is null)
                return;

            // Read config file (simple INI parser)
            try
            {
                string content = readText(configPath);
                foreach (line; content.splitLines())
                {
                    line = line.strip();
                    if (line.length == 0 || line.startsWith(";") || line.startsWith("#"))
                        continue;

                    auto parts = line.split("=");
                    if (parts.length == 2)
                    {
                        string key = parts[0].strip();
                        string value = parts[1].strip();

                        if (key == "SDKNamespaceName")
                            sdkNamespaceName = value;
                        else if (key == "SleepTimeout")
                            sleepTimeout = to!int(value);
                    }
                }
            }
            catch (Exception e)
            {
                // Ignore config file errors, use defaults
            }
        }
    }

    struct EngineCore
    {
        /* A special setting to fix UEnum::Names where the type is sometimes TArray<FName> and sometimes TArray<TPair<FName, Some8BitData>> */
        static immutable bool bCheckEnumNamesInUEnum = true;

        /* Enables support for TEncryptedObjectProperty */
        static immutable bool bEnableEncryptedObjectPropertySupport = false;
    }

    struct Generator
    {
        //Auto generated if no override is provided
        static string gameName = "";
        static string gameVersion = "";

        static immutable string sdkGenerationPath = "C:/Dumper-7";
    }

    struct CppGenerator
    {
        /* No prefix for files->FilePrefix = "" */
        static immutable string filePrefix = "";

        /* No seperate namespace for Params -> ParamNamespaceName = nullptr */
        static immutable string paramNamespaceName = "Params";

        /* XOR function name, that will be wrapped around any generated string. e.g. "xorstr_" -> xorstr_("Pawn") etc. */
        static immutable string xorString = null;
        /* XOR header file name. e.g. "xorstr.hpp" */
        static immutable string xorStringInclude = null;

        /* Customizable part of Cpp code to allow for a custom 'uintptr_t InSDKUtils::GetImageBase()' function */
        static immutable string getImageBaseFuncBody = 
`{
	return reinterpret_cast<uintptr_t>(GetModuleHandle(0));
}
`;
        /* Customizable part of Cpp code to allow for a custom 'InSDKUtils::CallGameFunction' function */
        static immutable string callGameFunction =
`
	template<typename FuncType, typename... ParamTypes>
	requires std::invocable<FuncType, ParamTypes...>
	inline auto CallGameFunction(FuncType Function, ParamTypes&&... Args)
	{
		return Function(std::forward<ParamTypes>(Args)...);
	}
`;
        /* An option to force the UWorld::GetWorld() function in the SDK to get the world through an instance of UEngine. Useful for games on which the dumper finds the wrong GWorld offset. */
        static immutable bool bForceNoGWorldInSDK = false;

        /* This will allow the user to manually initialize global variable addresses in the SDK (eg. GObjects, GNames, AppendString). */
        static immutable bool bAddManualOverrideOptions = true;

        /* Adds the 'final' specifier to classes with no loaded child class at SDK-generation time. */
        static immutable bool bAddFinalSpecifier = true;
    }

    struct MappingGenerator
    {
        /* Whether the MappingGenerator should check if a name was written to the nametable before. Exists to reduce mapping size. */
        static immutable bool bShouldCheckForDuplicatedNames = true;

        /* Whether EditorOnly should be excluded from the mapping file. */
        static immutable bool bExcludeEditorOnlyProperties = true;

        /* Which compression method to use when generating the file. */
        static immutable EUsmapCompressionMethod compressionMethod = EUsmapCompressionMethod.ZStandard;
    }

    /* Partially implemented  */
    struct Debug
    {
        /* Generates a dedicated file defining macros for static asserts (Make sure InlineAssertions are off) */
        static immutable bool bGenerateAssertionFile = true;

        /* Prefix for assertion macros in assertion file. Example for "MyPackage_params.hpp": #define DUMPER7_ASSERTS_PARAMS_MyPackage */
        static immutable string assertionMacroPrefix = "DUMPER7_ASSERTS_";


        /* Adds static_assert for struct-size, as well as struct-alignment */
        static immutable bool bGenerateInlineAssertionsForStructSize = false;

        /* Adds static_assert for member-offsets */
        static immutable bool bGenerateInlineAssertionsForStructMembers = false;


        /* Prints debug information during Mapping-Generation */
        static immutable bool bShouldPrintMappingDebugData = false;
    }

    //* * * * * * * * * * * * * * * * * * * * *// 
    // Do **NOT** change any of these settings //
    //* * * * * * * * * * * * * * * * * * * * *//
    struct Internal
    {
        /* Whether UEnum::Names stores only the name of the enum value, or a Pair<Name, Value> */
        static bool bIsEnumNameOnly = false; // EDemoPlayFailure

        /* Whether the 'Value' component in the Pair<Name, Value> UEnum::Names is a uint8 value, rather than the default int64 */
        static bool bIsSmallEnumValue = false;

        /* Whether TWeakObjectPtr contains 'TagAtLastTest' */
        static bool bIsWeakObjectPtrWithoutTag = false;

        /* Whether this games' engine version uses FProperty rather than UProperty */
        static bool bUseFProperty = false;

        /* Whether this game's engine version uses FNamePool rather than TNameEntryArray */
        static bool bUseNamePool = false;

        /* Whether UObject::Name or UObject::Class is first. Affects the calculation of the size of FName in fixup code. Not used after Off::Init(); */
        static bool bIsObjectNameBeforeClass = false;

        /* Whether this games uses case-sensitive FNames, adding int32 DisplayIndex to FName */
        static bool bUseCasePreservingName = false;

        /* Whether this games uses FNameOutlineNumber, moving the 'Number' component from FName into FNameEntry inside of FNamePool */
        static bool bUseOutlineNumberName = false;

        /* Whether this game uses the 'FFieldPathProperty' cast flags for a custom property 'FObjectPtrProperty' */
        static bool bIsObjPtrInsteadOfFieldPathProperty = false;

        /* Whether this games' engine version uses a contexpr flag to determine whether a FFieldVariant holds a UObject* or FField* */
        static bool bUseMaskForFieldOwner = false;

        /* Whether this games' engine version uses double for FVector, instead of float. Aka, whether the engine version is UE5.0 or higher. */
        static bool bUseLargeWorldCoordinates = false;

        /* Whether this game uses uint8 for UEProperty::ArrayDim, instead of int32 */
        static bool bUseUint8ArrayDim = false;
    }

    static void initWeakObjectPtrSettings()
    {
        import unreal.unrealobjects : UEStruct, UEFunction, UEProperty;
        import unreal.objectarray : ObjectArray;
        import unreal.enums : EClassCastFlags;

        const UEStruct loadAsset = ObjectArray.findObjectFast!UEFunction("LoadAsset", EClassCastFlags.Function);

        if (!loadAsset)
        {
            stderr.writeln("\nDumper-7: 'LoadAsset' wasn't found, could not determine value for 'bIsWeakObjectPtrWithoutTag'!");
            return;
        }

        const UEProperty asset = loadAsset.findMember("Asset", EClassCastFlags.SoftObjectProperty);
        if (!asset)
        {
            stderr.writeln("\nDumper-7: 'Asset' wasn't found, could not determine value for 'bIsWeakObjectPtrWithoutTag'!");
            return;
        }

        const UEStruct softObjectPath = ObjectArray.findStructFast("SoftObjectPath");

        enum int SizeOfFFWeakObjectPtr = 0x08;
        enum int OldUnrealAssetPtrSize = 0x10;

        // Continue with original logic...
    }

    static void initLargeWorldCoordinateSettings()
    {
        // Implementation details...
    }

    static void initObjectPtrPropertySettings()
    {
        // Implementation details...
    }

    static void initArrayDimSizeSettings()
    {
        Settings.Internal.bUseUint8ArrayDim = false;
        stderr.writefln("\nDumper-7: bUseUint8ArrayDim = %s", Settings.Internal.bUseUint8ArrayDim);
    }
}