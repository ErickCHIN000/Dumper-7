module unreal.unrealtypes;

import core.sys.windows.windows;
import std.string;
import std.conv;
import std.utf;
import std.algorithm;

import unreal.enums;
import unreal.unrealcontainers;
import offsetfinder.offsets;

// Forward declarations
string makeNameValid(wstring name);

// Template for implemented interfaces
struct TImplementedInterface(T)
{
    T interfaceClass;
    int32 pointerOffset;
    bool bImplementedByK2;
}

alias FImplementedInterface = TImplementedInterface!UEClass;

// FName class - critical for Unreal Engine string handling
class FName
{
    enum EOffsetOverrideType
    {
        AppendString,
        ToString,
        GNames
    }

    private:
    version(Win64)
    {
        static void function(const(void)*, ref FString) appendString = null;
    }
    else version(Win32)  
    {
        static extern(Windows) void function(const(void)*, ref FString) appendString = null;
    }

    // Fallback when AppendString was inlined
    static const(void)* function(uint32) getNameEntryFromName = null;
    static wstring function(const(void)*) toStr = null;

    const(ubyte)* address;

    public:
    this()
    {
        address = null;
    }

    this(const(void)* ptr)
    {
        address = cast(const(ubyte)*)ptr;
    }

    static void init(bool bForceGNames = false)
    {
        // Implementation would initialize the FName system
        // This involves finding GNames and setting up function pointers
    }

    static void initFallback()
    {
        // Fallback initialization
    }

    static void init(int32 overrideOffset, EOffsetOverrideType overrideType = EOffsetOverrideType.AppendString, 
                     bool bIsNamePool = false, const(char)* moduleName = null)
    {
        // Initialize with specific offset override
    }

    const(void)* getAddress() const 
    { 
        return address; 
    }

    wstring toWString() const
    {
        if (toStr !is null && address !is null)
        {
            return toStr(address);
        }
        return ""w;
    }

    wstring toRawWString() const
    {
        return toWString();
    }

    string toString() const
    {
        try
        {
            return toWString().toUTF8();
        }
        catch (Exception)
        {
            return "";
        }
    }

    string toRawString() const
    {
        return toString();
    }

    string toValidString() const
    {
        return makeNameValid(toWString());
    }

    int32 getCompIdx() const
    {
        if (address is null)
            return -1;
            
        // Implementation depends on Unreal Engine version
        return *cast(int32*)address;
    }

    uint32 getNumber() const
    {
        if (address is null)
            return 0;
            
        // Implementation depends on Unreal Engine version  
        return *cast(uint32*)(address + int32.sizeof);
    }

    bool opEquals(const FName other) const
    {
        if (address is null && other.address is null)
            return true;
        if (address is null || other.address is null)
            return false;
            
        return getCompIdx() == other.getCompIdx();
    }

    static string compIdxToString(int cmpIdx)
    {
        // Convert comparison index to string
        return cmpIdx.to!string();
    }

    static void* debugGetAppendString()
    {
        return cast(void*)appendString;
    }
}

// Make a name valid for code generation
string makeNameValid(wstring name)
{
    import std.array : appender;
    import std.ascii : isAlphaNum;
    
    if (name.length == 0)
        return "None";

    auto result = appender!string();
    
    // Convert to UTF-8 first
    string utf8Name;
    try
    {
        utf8Name = name.toUTF8();
    }
    catch (Exception)
    {
        return "InvalidName";
    }
    
    // Make sure first character is valid
    if (utf8Name.length > 0)
    {
        char first = utf8Name[0];
        if (first >= '0' && first <= '9')
        {
            result.put('_');
        }
    }
    
    // Replace invalid characters
    foreach (char c; utf8Name)
    {
        if (isAlphaNum(c) || c == '_')
        {
            result.put(c);
        }
        else
        {
            result.put('_');
        }
    }
    
    string resultStr = result.data;
    
    // Handle reserved keywords
    static immutable string[] reservedKeywords = [
        "abstract", "alias", "align", "asm", "assert", "auto",
        "body", "bool", "break", "byte", "case", "cast", "catch", "cdouble", "cent", "cfloat", "char",
        "class", "const", "continue", "creal", "dchar", "debug", "default", "delegate", "delete",
        "deprecated", "do", "double", "else", "enum", "export", "extern", "false", "final",
        "finally", "float", "for", "foreach", "foreach_reverse", "function", "goto", "idouble",
        "if", "ifloat", "immutable", "import", "in", "inout", "int", "interface", "invariant",
        "ireal", "is", "lazy", "long", "macro", "mixin", "module", "new", "nothrow", "null",
        "out", "override", "package", "pragma", "private", "protected", "public", "pure", "real",
        "ref", "return", "scope", "shared", "short", "static", "struct", "super", "switch",
        "synchronized", "template", "this", "throw", "true", "try", "typedef", "typeid", "typeof",
        "ubyte", "ucent", "uint", "ulong", "union", "unittest", "ushort", "version", "void",
        "volatile", "wchar", "while", "with", "__FILE__", "__MODULE__", "__LINE__", "__FUNCTION__",
        "__PRETTY_FUNCTION__", "__gshared", "__traits", "__vector", "__parameters"
    ];
    
    if (reservedKeywords.canFind(resultStr))
    {
        resultStr = resultStr ~ "_";
    }
    
    return resultStr.length > 0 ? resultStr : "None";
}

// Forward declaration for UE classes (will be implemented in unrealobjects.d)
abstract class UEObject {}
abstract class UEClass : UEObject {}
abstract class UEStruct : UEObject {}
abstract class UEFunction : UEStruct {}
abstract class UEProperty : UEObject {}

// Basic structure alignment
template AlignedBytes(int Size, uint Alignment)
{
    align(Alignment) struct AlignedBytes
    {
        ubyte[Size] pad;
    }
}

// Inline allocator template  
template TInlineAllocator(uint NumInlineElements)
{
    struct TInlineAllocator(T)
    {
        private:
        enum int ElementSize = T.sizeof;
        enum int ElementAlign = T.alignof;
        enum int InlineDataSizeBytes = NumInlineElements * ElementSize;

        AlignedBytes!(ElementSize, ElementAlign)[NumInlineElements] inlineData;
        T* secondaryData;

        public:
        this(int dummy) // Constructor to avoid default initialization issues
        {
            inlineData[] = AlignedBytes!(ElementSize, ElementAlign).init;
            secondaryData = null;
        }

        T* getInlineElements()
        {
            return cast(T*)inlineData.ptr;
        }

        T* getAllocation()
        {
            return secondaryData !is null ? secondaryData : getInlineElements();
        }

        void moveToEmpty(ref TInlineAllocator other)
        {
            // Move semantics - simplified
            secondaryData = other.secondaryData;
            other.secondaryData = null;
            
            if (secondaryData is null)
            {
                inlineData[] = other.inlineData[];
            }
        }
    }
}

// BitArray for representing sets of bits
struct TBitArray
{
    private:
    uint32* data;
    int32 numBits;
    int32 maxBits;

    public:
    this(int32 initialNumBits)
    {
        numBits = initialNumBits;
        maxBits = align!int32(initialNumBits, 32);
        if (maxBits > 0)
        {
            data = cast(uint32*)calloc(maxBits / 32, uint32.sizeof);
        }
        else
        {
            data = null;
        }
    }

    ~this()
    {
        if (data !is null)
        {
            free(data);
            data = null;
        }
    }

    bool opIndex(int32 index) const
    {
        if (index < 0 || index >= numBits)
            return false;
            
        int32 dwordIndex = index / 32;
        int32 bitIndex = index % 32;
        return (data[dwordIndex] & (1u << bitIndex)) != 0;
    }

    void opIndexAssign(bool value, int32 index)
    {
        if (index < 0 || index >= numBits)
            return;
            
        int32 dwordIndex = index / 32;
        int32 bitIndex = index % 32;
        
        if (value)
        {
            data[dwordIndex] |= (1u << bitIndex);
        }
        else
        {
            data[dwordIndex] &= ~(1u << bitIndex);
        }
    }

    int32 length() const
    {
        return numBits;
    }
}

extern(C) void* calloc(size_t num, size_t size);
extern(C) void free(void* ptr);