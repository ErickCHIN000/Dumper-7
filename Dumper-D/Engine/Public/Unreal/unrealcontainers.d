module unreal.unrealcontainers;

import std.traits;
import std.algorithm;
import std.range;
import core.stdc.stdlib : malloc, free;
import core.stdc.string : memcpy, memset;

import unreal.enums;

// Forward declarations
struct TArray(T);
struct TSparseArray(T);
struct TSet(T);
struct TMap(K, V);
struct TPair(K, V);

// Helper functions
private:

uint32 floorLog2(uint32 value)
{
    uint32 pos = 0;
    if (value >= 1 << 16) { value >>= 16; pos += 16; }
    if (value >= 1 << 8) { value >>= 8; pos += 8; }
    if (value >= 1 << 4) { value >>= 4; pos += 4; }
    if (value >= 1 << 2) { value >>= 2; pos += 2; }
    if (value >= 1 << 1) { pos += 1; }
    return pos;
}

uint32 countLeadingZeros(uint32 value)
{
    if (value == 0)
        return 32;
    
    return 31 - floorLog2(value);
}

// Core FString type
struct FString
{
    wchar_t* data;
    int32 numElements;
    int32 maxElements;

    this(const(wchar_t)* str)
    {
        if (str is null)
        {
            data = null;
            numElements = 0;
            maxElements = 0;
            return;
        }

        size_t len = 0;
        while (str[len] != 0) len++; // Calculate length

        numElements = cast(int32)len;
        maxElements = numElements + 1;
        data = cast(wchar_t*)malloc(wchar_t.sizeof * maxElements);
        
        if (data !is null)
        {
            memcpy(data, str, wchar_t.sizeof * numElements);
            data[numElements] = 0;
        }
    }

    this(string str)
    {
        import std.utf : toUTF16;
        
        if (str.length == 0)
        {
            data = null;
            numElements = 0;
            maxElements = 0;
            return;
        }

        wstring wstr = str.toUTF16();
        numElements = cast(int32)wstr.length;
        maxElements = numElements + 1;
        data = cast(wchar_t*)malloc(wchar_t.sizeof * maxElements);
        
        if (data !is null)
        {
            memcpy(data, wstr.ptr, wchar_t.sizeof * numElements);
            data[numElements] = 0;
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

    string toString() const
    {
        if (data is null || numElements == 0)
            return "";
            
        import std.utf : toUTF8;
        return toUTF8(data[0..numElements]);
    }

    wstring toWString() const
    {
        if (data is null || numElements == 0)
            return ""w;
            
        return data[0..numElements].idup;
    }
}

// FFreableString - special version that can be freed
struct FFreableString
{
    FString base;
    alias base this;

    this(uint32 numElementsToReserve)
    {
        if (numElementsToReserve > 0x1000000)
            return;

        base.data = cast(wchar_t*)malloc(wchar_t.sizeof * numElementsToReserve);
        base.numElements = 0;
        base.maxElements = numElementsToReserve;
    }

    void resetNum()
    {
        base.numElements = 0;
    }

    private void freeArray()
    {
        base.numElements = 0;
        base.maxElements = 0;
        if (base.data !is null)
        {
            free(base.data);
            base.data = null;
        }
    }
}

// TArray implementation
struct TArray(T)
{
    T* data;
    int32 numElements;
    int32 maxElements;

    this(size_t initialCapacity)
    {
        if (initialCapacity > 0)
        {
            data = cast(T*)malloc(T.sizeof * initialCapacity);
            numElements = 0;
            maxElements = cast(int32)initialCapacity;
        }
        else
        {
            data = null;
            numElements = 0;
            maxElements = 0;
        }
    }

    ~this()
    {
        clear();
    }

    void clear()
    {
        if (data !is null)
        {
            // Call destructors for non-trivial types
            static if (!__traits(isPOD, T))
            {
                for (int32 i = 0; i < numElements; i++)
                {
                    destroy(data[i]);
                }
            }
            free(data);
            data = null;
        }
        numElements = 0;
        maxElements = 0;
    }

    bool empty() const
    {
        return numElements == 0;
    }

    int32 length() const
    {
        return numElements;
    }

    int32 size() const
    {
        return numElements;
    }

    ref T opIndex(size_t index)
    {
        assert(index < numElements, "Array index out of bounds");
        return data[index];
    }

    ref const(T) opIndex(size_t index) const
    {
        assert(index < numElements, "Array index out of bounds");
        return data[index];
    }

    T[] opSlice()
    {
        if (data is null || numElements == 0)
            return [];
        return data[0..numElements];
    }

    const(T)[] opSlice() const
    {
        if (data is null || numElements == 0)
            return [];
        return data[0..numElements];
    }

    void add(T item)
    {
        if (numElements >= maxElements)
        {
            reserve(maxElements > 0 ? maxElements * 2 : 4);
        }
        
        data[numElements] = item;
        numElements++;
    }

    void reserve(int32 newCapacity)
    {
        if (newCapacity <= maxElements)
            return;

        T* newData = cast(T*)malloc(T.sizeof * newCapacity);
        if (newData !is null)
        {
            if (data !is null && numElements > 0)
            {
                memcpy(newData, data, T.sizeof * numElements);
                free(data);
            }
            data = newData;
            maxElements = newCapacity;
        }
    }

    bool isValidIndex(int32 index) const
    {
        return index >= 0 && index < numElements;
    }
}

// TPair implementation
struct TPair(K, V)
{
    K key;
    V value;

    this(K k, V v)
    {
        key = k;
        value = v;
    }
}

// TSet basic implementation
struct TSet(T)
{
    private:
    TArray!T elements;
    
    public:
    bool empty() const
    {
        return elements.empty();
    }

    int32 length() const
    {
        return elements.length();
    }

    void add(T item)
    {
        if (!contains(item))
        {
            elements.add(item);
        }
    }

    bool contains(T item) const
    {
        foreach (ref const element; elements[])
        {
            if (element == item)
                return true;
        }
        return false;
    }

    void clear()
    {
        elements.clear();
    }

    auto opSlice()
    {
        return elements[];
    }

    auto opSlice() const
    {
        return elements[];
    }
}

// TMap basic implementation  
struct TMap(K, V)
{
    private:
    TArray!(TPair!(K, V)) pairs;

    public:
    bool empty() const
    {
        return pairs.empty();
    }

    int32 length() const
    {
        return pairs.length();
    }

    ref V opIndex(K key)
    {
        foreach (ref pair; pairs[])
        {
            if (pair.key == key)
                return pair.value;
        }
        
        // Key not found, add new pair
        V defaultValue;
        pairs.add(TPair!(K, V)(key, defaultValue));
        return pairs[pairs.length() - 1].value;
    }

    const(V)* opBinaryRight(string op)(K key) const
        if (op == "in")
    {
        foreach (ref const pair; pairs[])
        {
            if (pair.key == key)
                return &pair.value;
        }
        return null;
    }

    void opIndexAssign(V value, K key)
    {
        foreach (ref pair; pairs[])
        {
            if (pair.key == key)
            {
                pair.value = value;
                return;
            }
        }
        
        // Key not found, add new pair
        pairs.add(TPair!(K, V)(key, value));
    }

    void clear()
    {
        pairs.clear();
    }

    auto keys()
    {
        struct KeyRange
        {
            TArray!(TPair!(K, V))* pairs;
            int32 index = 0;

            bool empty() const { return index >= pairs.length(); }
            ref K front() { return (*pairs)[index].key; }
            void popFront() { index++; }
        }
        
        return KeyRange(&pairs);
    }

    auto values()
    {
        struct ValueRange
        {
            TArray!(TPair!(K, V))* pairs;
            int32 index = 0;

            bool empty() const { return index >= pairs.length(); }
            ref V front() { return (*pairs)[index].value; }
            void popFront() { index++; }
        }
        
        return ValueRange(&pairs);
    }
}

// TSparseArray basic implementation
struct TSparseArray(T)
{
    private:
    TArray!T elements;
    TArray!bool allocated;

    public:
    bool empty() const
    {
        return elements.empty();
    }

    int32 length() const
    {
        return elements.length();
    }

    int32 addUninitialized()
    {
        int32 index = elements.length();
        elements.add(T.init);
        allocated.add(true);
        return index;
    }

    void removeAt(int32 index)
    {
        if (isValidIndex(index))
        {
            allocated[index] = false;
        }
    }

    bool isValidIndex(int32 index) const
    {
        return index >= 0 && index < allocated.length() && allocated[index];
    }

    ref T opIndex(int32 index)
    {
        assert(isValidIndex(index), "Sparse array index invalid");
        return elements[index];
    }

    ref const(T) opIndex(int32 index) const
    {
        assert(isValidIndex(index), "Sparse array index invalid");
        return elements[index];
    }

    void clear()
    {
        elements.clear();
        allocated.clear();
    }
}