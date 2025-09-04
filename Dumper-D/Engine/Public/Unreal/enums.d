module unreal.enums;

import std.traits;
import std.conv;
import std.algorithm;
import std.string;

// Type aliases for consistency with C++ version
alias int8 = byte;
alias int16 = short; 
alias int32 = int;
alias int64 = long;

alias uint8 = ubyte;
alias uint16 = ushort;
alias uint32 = uint;
alias uint64 = ulong;

T align(T)(T size, T alignment)
    if (isIntegral!T)
{
    assert(alignment != 0, "Alignment was 0, division by zero exception.");
    
    const T requiredAlign = alignment - (size % alignment);
    
    return size + (requiredAlign != alignment ? requiredAlign : 0);
}

// Enum operators template mixin
mixin template EnumOperators(E)
    if (is(E == enum))
{
    E opBinary(string op)(E right) const
        if (op == "|")
    {
        return cast(E)(cast(OriginalType!E)this | cast(OriginalType!E)right);
    }
    
    ref E opOpAssign(string op)(E right)
        if (op == "|")
    {
        this = cast(E)(cast(OriginalType!E)this | cast(OriginalType!E)right);
        return this;
    }
    
    bool opBinary(string op)(E right) const
        if (op == "&")
    {
        return ((cast(OriginalType!E)this & cast(OriginalType!E)right) == cast(OriginalType!E)right);
    }
}

enum EUsmapCompressionMethod : uint8
{
    None = 0,
    Oodle = 1,
    Brotli = 2,
    ZStandard = 3
}

enum EPropertyFlags : uint64
{
    None = 0x0000000000000000,

    Edit = 0x0000000000000001,   ///< Property is user-settable in the editor.
    ConstParm = 0x0000000000000002,   ///< This is a constant function parameter
    BlueprintVisible = 0x0000000000000004,   ///< This property can be read by blueprint code
    ExportObject = 0x0000000000000008,   ///< Object can be exported with actor.
    BlueprintReadOnly = 0x0000000000000010,   ///< This property cannot be modified by blueprint code
    Net = 0x0000000000000020,   ///< Property is relevant to network replication.
    EditFixedSize = 0x0000000000000040,   ///< Indicates that elements of an array can be modified, but its size cannot be changed.
    Parm = 0x0000000000000080,   ///< Function/When call parameter.
    OutParm = 0x0000000000000100,   ///< Value is copied out after function call.
    ZeroConstructor = 0x0000000000000200,   ///< memset is fine for construction
    ReturnParm = 0x0000000000000400,   ///< Return value.
    DisableEditOnTemplate = 0x0000000000000800,   ///< Disable editing of this property on an archetype/sub-blueprint
    
    Transient = 0x0000000000002000,   ///< Property is transient: shouldn't be saved or loaded, except for Blueprint CDOs.
    Config = 0x0000000000004000,   ///< Property should be loaded/saved as permanent profile.
    
    DisableEditOnInstance = 0x0000000000010000,   ///< Disable editing on an instance of this class
    EditConst = 0x0000000000020000,   ///< Property is uneditable in the editor.
    GlobalConfig = 0x0000000000040000,   ///< Load config from base class, not subclass.
    InstancedReference = 0x0000000000080000,   ///< Property is a component references.
    
    DuplicateTransient = 0x0000000000200000,   ///< Property should always be reset to the default value during any type of duplication (copy/paste, binary duplication, etc.)
    SubobjectReference = 0x0000000000400000,   ///< Property contains subobject references (TSubobjectPtr)
    SaveGame = 0x0000000001000000,   ///< Property should be serialized for save games, this is only checked for game-specific archives with ArIsSaveGame
    NoClear = 0x0000000002000000,   ///< Hide clear (and browse) button.
    
    ReferenceParm = 0x0000000008000000,   ///< Value is passed by reference; OutParam and Param should also be set.
    BlueprintAssignable = 0x0000000010000000,   ///< MC Delegates only.  Property should be exposed for assigning in blueprint code
    Deprecated = 0x0000000020000000,   ///< Property is deprecated.  Read it from an archive, but don't save it.
    IsPlainOldData = 0x0000000040000000,   ///< If this is set, then the property can be memcopied instead of CopyCompleteValue / CopySingleValue
    RepSkip = 0x0000000080000000,   ///< Not replicated. For non replicated properties in replicated structs 
    RepNotify = 0x0000000100000000,   ///< Notify actors when a property is replicated
    Interp = 0x0000000200000000,   ///< interpolatable property for use with cinematics
    NonTransactional = 0x0000000400000000,   ///< Property isn't transacted
    EditorOnly = 0x0000000800000000,   ///< Property should only be loaded in the editor
    NoDestructor = 0x0000001000000000,   ///< No destructor
    
    AutoWeak = 0x0000004000000000,   ///< Only used for weak pointers, means the export type is autoweak
    ContainsInstancedReference = 0x0000008000000000,   ///< Property contains component references.
    AssetRegistrySearchable = 0x0000010000000000,   ///< asset instances will add properties with this flag to the asset registry automatically
    SimpleDisplay = 0x0000020000000000,   ///< The property is visible by default in the editor details view
    AdvancedDisplay = 0x0000040000000000,   ///< The property is advanced and not visible by default in the editor details view
    Protected = 0x0000080000000000,   ///< property is protected from the perspective of script
    BlueprintCallable = 0x0000100000000000,   ///< MC Delegates only.  Property should be exposed for calling in blueprint code
    BlueprintAuthorityOnly = 0x0000200000000000,   ///< MC Delegates only.  This delegate accepts (only in blueprint) only events with BlueprintAuthorityOnly.
    TextExportTransient = 0x0000400000000000,   ///< Property shouldn't be exported to text format (e.g. copy/paste)
    NonPIEDuplicateTransient = 0x0000800000000000,   ///< Property should only be copied in PIE
    ExposeOnSpawn = 0x0001000000000000,   ///< Property is exposed on spawn
    PersistentInstance = 0x0002000000000000,   ///< A object referenced by the property is duplicated like a component. (Each actor should have an own instance.)
    UObjectWrapper = 0x0004000000000000,   ///< Property was parsed as a wrapper class like TSubclassOf<T>, FScriptInterface etc., rather than a USomething*
    HasGetValueTypeHash = 0x0008000000000000,   ///< This property can generate a meaningful hash value.
    NativeAccessSpecifierPublic = 0x0010000000000000,   ///< Public native access specifier
    NativeAccessSpecifierProtected = 0x0020000000000000,   ///< Protected native access specifier
    NativeAccessSpecifierPrivate = 0x0040000000000000,   ///< Private native access specifier
    SkipSerialization = 0x0080000000000000,   ///< Property shouldn't be serialized, can still be exported to text
}

enum ELifetimeCondition : uint8
{
    None                      = 0,   ///< This property has no condition, and will send anytime it changes
    InitialOnly               = 1,   ///< This property will only attempt to send on the initial bunch
    OwnerOnly                 = 2,   ///< This property will only send to the actor's owner
    SkipOwner                 = 3,   ///< This property send to every connection EXCEPT the owner
    SimulatedOnly             = 4,   ///< This property will only send to simulated actors
    AutonomousOnly            = 5,   ///< This property will only send to autonomous actors
    SimulatedOrPhysics        = 6,   ///< This property will send to simulated OR bRepPhysics actors
    InitialOrOwner            = 7,   ///< This property will send on the initial packet, or to the actors owner
    Custom                    = 8,   ///< This property has no particular condition, but wants the ability to toggle on/off via SetCustomIsActiveOverride
    ReplayOrOwner             = 9,   ///< This property will only send to the replay connection, or to the actors owner
    ReplayOnly                = 10,  ///< This property will only send to the replay connection
    SimulatedOnlyNoReplay     = 11,  ///< This property will send to actors only, but not to replay connections
    SimulatedOrPhysicsNoReplay = 12, ///< This property will send to simulated Or bRepPhysics actors, but not to replay connections
    SkipReplay                = 13,  ///< This property will not send to the replay connection
    Never                     = 15,  ///< This property will never be replicated
}

enum ERepFrequency : uint8
{
    NetRPC      = 0,
    NetActor    = 1
}

enum EPropertyType : uint64
{
    Unknown = 0,
    
    // Atomic types
    UInt8 = 1llu << 0,
    UInt16 = 1llu << 1,  
    UInt32 = 1llu << 2,
    UInt64 = 1llu << 3,
    Int8 = 1llu << 4,
    Int16 = 1llu << 5,
    Int32 = 1llu << 6,
    Int64 = 1llu << 7,
    Float = 1llu << 8,
    Double = 1llu << 9,
    Bool = 1llu << 10,
    Byte = 1llu << 11,
    
    // Complex types
    Interface = 1llu << 12,
    Name = 1llu << 13,
    String = 1llu << 14,
    Object = 1llu << 16,
    UInt16_2 = 1llu << 18,
    Struct = 1llu << 20,
    Array = 1llu << 21,
    Delegate = 1llu << 23,
    SoftObject = 1llu << 27,
    LazyObject = 1llu << 28,
    WeakObject = 1llu << 29,
    Text = 1llu << 30,
    SoftClass = 1llu << 33,
    Map = 1llu << 46,
    Set = 1llu << 47,
    Enum = 1llu << 48,
    MulticastInlineDelegate = 1llu << 50,
    MulticastSparseDelegate = 1llu << 51,
    ObjectPointer = 1llu << 53
}

enum EClassCastFlags : uint64
{
    None                                = 0x0000000000000000,

    Field                               = 0x0000000000000001,
    Int8Property                        = 0x0000000000000002,
    Enum                                = 0x0000000000000004,
    Struct                              = 0x0000000000000008,
    ScriptStruct                        = 0x0000000000000010,
    Class                               = 0x0000000000000020,
    ByteProperty                        = 0x0000000000000040,
    IntProperty                         = 0x0000000000000080,
    FloatProperty                       = 0x0000000000000100,
    UInt64Property                      = 0x0000000000000200,
    ClassProperty                       = 0x0000000000000400,
    UInt32Property                      = 0x0000000000000800,
    InterfaceProperty                   = 0x0000000000001000,
    NameProperty                        = 0x0000000000002000,
    StrProperty                         = 0x0000000000004000,
    Property                            = 0x0000000000008000,
    ObjectProperty                      = 0x0000000000010000,
    BoolProperty                        = 0x0000000000020000,
    UInt16Property                      = 0x0000000000040000,
    Function                            = 0x0000000000080000,
    StructProperty                      = 0x0000000000100000,
    ArrayProperty                       = 0x0000000000200000,
    Int64Property                       = 0x0000000000400000,
    DelegateProperty                    = 0x0000000000800000,
    NumericProperty                     = 0x0000000001000000,
    MulticastDelegateProperty           = 0x0000000002000000,
    ObjectPropertyBase                  = 0x0000000004000000,
    WeakObjectProperty                  = 0x0000000008000000,
    LazyObjectProperty                  = 0x0000000010000000,
    SoftObjectProperty                  = 0x0000000020000000,
    TextProperty                        = 0x0000000040000000,
    Int16Property                       = 0x0000000080000000,
    DoubleProperty                      = 0x0000000100000000,
    SoftClassProperty                   = 0x0000000200000000,
    Package                             = 0x0000000400000000,
    Level                               = 0x0000000800000000,
    Actor                               = 0x0000001000000000,
    PlayerController                    = 0x0000002000000000,
    Pawn                                = 0x0000004000000000,
    SceneComponent                      = 0x0000008000000000,
    PrimitiveComponent                  = 0x0000010000000000,
    SkinnedMeshComponent                = 0x0000020000000000,
    SkeletalMeshComponent               = 0x0000040000000000,
    Blueprint                           = 0x0000080000000000,
    DelegateFunction                    = 0x0000100000000000,
    StaticMeshComponent                 = 0x0000200000000000,
    MapProperty                         = 0x0000400000000000,
    SetProperty                         = 0x0000800000000000,
    EnumProperty                        = 0x0001000000000000,
    SparseDelegateFunction              = 0x0002000000000000,
    MulticastInlineDelegateProperty     = 0x0004000000000000,
    MulticastSparseDelegateProperty     = 0x0008000000000000,
    FieldPathProperty                   = 0x0010000000000000,
    LargeWorldCoordinatesRealProperty   = 0x0080000000000000,
    OptionalProperty                    = 0x0100000000000000,
    VValueProperty                      = 0x0200000000000000,
    VerseVMClass                        = 0x0400000000000000,
    VRestValueProperty                  = 0x0800000000000000,
    Utf8StrProperty                     = 0x1000000000000000,
    AnsiStrProperty                     = 0x2000000000000000,
    VCellProperty                       = 0x4000000000000000,
}

mixin EnumOperators!EClassCastFlags;

enum EClassFlags : uint32
{
    None                         = 0x00000000u,
    Abstract                     = 0x00000001u,
    DefaultConfig                = 0x00000002u,
    Config                       = 0x00000004u,
    Transient                    = 0x00000008u,
    Parsed                       = 0x00000010u,
    MatchedSerializers           = 0x00000020u,
    ProjectUserConfig            = 0x00000040u,
    Native                       = 0x00000080u,
    NoExport                     = 0x00000100u,
    NotPlaceable                 = 0x00000200u,
    PerObjectConfig              = 0x00000400u,
    ReplicationDataIsSetUp       = 0x00000800u,
    EditInlineNew                = 0x00001000u,
    CollapseCategories           = 0x00002000u,
    Interface                    = 0x00004000u,
    CustomConstructor            = 0x00008000u,
    Const                        = 0x00010000u,
    LayoutChanging               = 0x00020000u,
    CompiledFromBlueprint        = 0x00040000u,
    MinimalAPI                   = 0x00080000u,
    RequiredAPI                  = 0x00100000u,
    DefaultToInstanced           = 0x00200000u,
    TokenStreamAssembled         = 0x00400000u,
    HasInstancedReference        = 0x00800000u,
    Hidden                       = 0x01000000u,
    Deprecated                   = 0x02000000u,
    HideDropDown                 = 0x04000000u,
    GlobalUserConfig             = 0x08000000u,
    Intrinsic                    = 0x10000000u,
    Constructed                  = 0x20000000u,
    ConfigDoNotCheckDefaults     = 0x40000000u,
    NewerVersionExists           = 0x80000000u,
}

mixin EnumOperators!EClassFlags;

enum EFunctionFlags : uint32
{
    None                    = 0x00000000,

    Final                   = 0x00000001, ///< Function is final (prebindable, non-overridable function).
    RequiredAPI             = 0x00000002, ///< Indicates this function is DLL exported/imported.
    BlueprintAuthorityOnly  = 0x00000004, ///< Function will only run if the object has network authority
    BlueprintCosmetic       = 0x00000008, ///< Function is cosmetic in nature and should not be invoked on dedicated servers
    Net                     = 0x00000040, ///< Function is network-replicated.
    NetReliable             = 0x00000080, ///< Function should be sent reliably on the network.
    NetRequest              = 0x00000100, ///< Function is sent to a net service
    Exec                    = 0x00000200, ///< Executable from command line.
    Native                  = 0x00000400, ///< Native function.
    Event                   = 0x00000800, ///< Event function.
    NetResponse             = 0x00001000, ///< Function response from a net service
    Static                  = 0x00002000, ///< Static function.
    NetMulticast            = 0x00004000, ///< Function is networked multicast Server -> All Clients
    UbergraphFunction       = 0x00008000, ///< Function is used as the merge 'ubergraph' for a blueprint, only assigned when using the persistent 'ubergraph' frame
    MulticastDelegate       = 0x00010000, ///< Function is a multi-cast delegate signature (also requires Delegate to be set!)
    Public                  = 0x00020000, ///< Function is accessible in all classes.
    Private                 = 0x00040000, ///< Function is accessible only in the class it is defined in
    Protected               = 0x00080000, ///< Function is accessible only in the class it is defined in and subclasses
    Delegate                = 0x00100000, ///< Function is delegate signature (either single-cast or multi-cast, depending on whether MulticastDelegate is set.)
    NetServer               = 0x00200000, ///< Function is executed on servers (set by replication code if passes check)
    HasOutParms             = 0x00400000, ///< function has out (pass by reference) parameters
    HasDefaults             = 0x00800000, ///< function has structs that contain defaults
    NetClient               = 0x01000000, ///< function is executed on clients
    DLLImport               = 0x02000000, ///< function is imported from a DLL
    BlueprintCallable       = 0x04000000, ///< function can be called from blueprint code
    BlueprintEvent          = 0x08000000, ///< function can be overridden/implemented from a blueprint
    BlueprintPure           = 0x10000000, ///< function can be called from blueprint code, and is also pure (produces no side effects). If you set this, you should set BlueprintCallable as well.
    EditorOnly              = 0x20000000, ///< function can only be called from an editor scrippt.
    Const                   = 0x40000000, ///< function can be called from blueprint code, and only reads state (never writes state)
    NetValidate             = 0x80000000, ///< function must supply a _Validate implementation

    AllFlags                = 0xFFFFFFFF,
}

mixin EnumOperators!EFunctionFlags;

string classCastFlagsToString(EClassCastFlags castFlags)
{
    string retFlags = "";

    if (castFlags & EClassCastFlags.Field) retFlags ~= "Field, ";
    if (castFlags & EClassCastFlags.Int8Property) retFlags ~= "Int8Property, ";
    if (castFlags & EClassCastFlags.Enum) retFlags ~= "Enum, ";
    if (castFlags & EClassCastFlags.Struct) retFlags ~= "Struct, ";
    if (castFlags & EClassCastFlags.ScriptStruct) retFlags ~= "ScriptStruct, ";
    if (castFlags & EClassCastFlags.Class) retFlags ~= "Class, ";
    if (castFlags & EClassCastFlags.ByteProperty) retFlags ~= "ByteProperty, ";
    if (castFlags & EClassCastFlags.IntProperty) retFlags ~= "IntProperty, ";
    if (castFlags & EClassCastFlags.FloatProperty) retFlags ~= "FloatProperty, ";
    if (castFlags & EClassCastFlags.UInt64Property) retFlags ~= "UInt64Property, ";
    if (castFlags & EClassCastFlags.ClassProperty) retFlags ~= "ClassProperty, ";
    if (castFlags & EClassCastFlags.UInt32Property) retFlags ~= "UInt32Property, ";
    if (castFlags & EClassCastFlags.InterfaceProperty) retFlags ~= "InterfaceProperty, ";
    if (castFlags & EClassCastFlags.NameProperty) retFlags ~= "NameProperty, ";
    if (castFlags & EClassCastFlags.StrProperty) retFlags ~= "StrProperty, ";
    if (castFlags & EClassCastFlags.Property) retFlags ~= "Property, ";
    if (castFlags & EClassCastFlags.ObjectProperty) retFlags ~= "ObjectProperty, ";
    if (castFlags & EClassCastFlags.BoolProperty) retFlags ~= "BoolProperty, ";
    if (castFlags & EClassCastFlags.UInt16Property) retFlags ~= "UInt16Property, ";
    if (castFlags & EClassCastFlags.Function) retFlags ~= "Function, ";
    if (castFlags & EClassCastFlags.StructProperty) retFlags ~= "StructProperty, ";
    if (castFlags & EClassCastFlags.ArrayProperty) retFlags ~= "ArrayProperty, ";
    if (castFlags & EClassCastFlags.Int64Property) retFlags ~= "Int64Property, ";
    if (castFlags & EClassCastFlags.DelegateProperty) retFlags ~= "DelegateProperty, ";
    if (castFlags & EClassCastFlags.NumericProperty) retFlags ~= "NumericProperty, ";
    if (castFlags & EClassCastFlags.MulticastDelegateProperty) retFlags ~= "MulticastDelegateProperty, ";
    if (castFlags & EClassCastFlags.ObjectPropertyBase) retFlags ~= "ObjectPropertyBase, ";
    if (castFlags & EClassCastFlags.WeakObjectProperty) retFlags ~= "WeakObjectProperty, ";
    if (castFlags & EClassCastFlags.LazyObjectProperty) retFlags ~= "LazyObjectProperty, ";
    if (castFlags & EClassCastFlags.SoftObjectProperty) retFlags ~= "SoftObjectProperty, ";
    if (castFlags & EClassCastFlags.TextProperty) retFlags ~= "TextProperty, ";
    if (castFlags & EClassCastFlags.Int16Property) retFlags ~= "Int16Property, ";
    if (castFlags & EClassCastFlags.DoubleProperty) retFlags ~= "DoubleProperty, ";
    if (castFlags & EClassCastFlags.SoftClassProperty) retFlags ~= "SoftClassProperty, ";
    if (castFlags & EClassCastFlags.Package) retFlags ~= "Package, ";
    if (castFlags & EClassCastFlags.Level) retFlags ~= "Level, ";
    if (castFlags & EClassCastFlags.Actor) retFlags ~= "Actor, ";
    if (castFlags & EClassCastFlags.PlayerController) retFlags ~= "PlayerController, ";
    if (castFlags & EClassCastFlags.Pawn) retFlags ~= "Pawn, ";
    if (castFlags & EClassCastFlags.SceneComponent) retFlags ~= "SceneComponent, ";
    if (castFlags & EClassCastFlags.PrimitiveComponent) retFlags ~= "PrimitiveComponent, ";
    if (castFlags & EClassCastFlags.SkinnedMeshComponent) retFlags ~= "SkinnedMeshComponent, ";
    if (castFlags & EClassCastFlags.SkeletalMeshComponent) retFlags ~= "SkeletalMeshComponent, ";
    if (castFlags & EClassCastFlags.Blueprint) retFlags ~= "Blueprint, ";
    if (castFlags & EClassCastFlags.DelegateFunction) retFlags ~= "DelegateFunction, ";
    if (castFlags & EClassCastFlags.StaticMeshComponent) retFlags ~= "StaticMeshComponent, ";
    if (castFlags & EClassCastFlags.MapProperty) retFlags ~= "MapProperty, ";
    if (castFlags & EClassCastFlags.SetProperty) retFlags ~= "SetProperty, ";
    if (castFlags & EClassCastFlags.EnumProperty) retFlags ~= "EnumProperty, ";
    if (castFlags & EClassCastFlags.SparseDelegateFunction) retFlags ~= "SparseDelegateFunction, ";
    if (castFlags & EClassCastFlags.MulticastInlineDelegateProperty) retFlags ~= "MulticastInlineDelegateProperty, ";
    if (castFlags & EClassCastFlags.MulticastSparseDelegateProperty) retFlags ~= "MulticastSparseDelegateProperty, ";
    if (castFlags & EClassCastFlags.FieldPathProperty) retFlags ~= "MarkAsFieldPathPropertyRootSet, ";
    if (castFlags & EClassCastFlags.LargeWorldCoordinatesRealProperty) retFlags ~= "LargeWorldCoordinatesRealProperty, ";
    if (castFlags & EClassCastFlags.OptionalProperty) retFlags ~= "OptionalProperty, ";
    if (castFlags & EClassCastFlags.VValueProperty) retFlags ~= "VValueProperty, ";
    if (castFlags & EClassCastFlags.VerseVMClass) retFlags ~= "VerseVMClass, ";
    if (castFlags & EClassCastFlags.VRestValueProperty) retFlags ~= "VRestValueProperty, ";

    return retFlags.length > 2 ? retFlags[0..$-2] : retFlags;
}