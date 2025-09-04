module utils.dumpspace.dsgen;

import std.json;
import std.string;
import std.file;
import std.path;
import std.datetime;
import std.conv;
import std.algorithm;
import std.array;

class DSGen
{
    // The EType enum describes the type of the member of a class, struct, enum or param of a function
    // or the class, struct, function, enum itself.
    // Setting the correct type is important for the dumspace website in order to know where to redirect
    // when clicking on the type.
    // Pointers or references dont play a role here, for example is the member UWorld* owningWorld a ET_Class.
    // More examples:
    // int itemCount -> ET_Default
    // EToastType type -> ET_Enum (if we can confirm EToastType is a enum)
    // FVector location -> ET_Struct (if we can confirm FVector is a struct)
    // AWeaponDef* weaponDefinition -> ET_Class (if we can confirm AWeaponDef is a class)
    // Template examples:
    // TMap<int, FVector> -> ET_Class, we ignore what the templates (int, FVector) are
    //
    // Keep in mind, if you have a member and its type is UNKNOWN, so not defined, mark the member as ET_Default.
    // Otherwise, the website will search for the type, resulting in a missing definition error.
    enum EType
    {
        ET_Default, // all types that are either undefined or default (int, bool, char,..., FType (undefined))
        ET_Struct, // all types that are a struct (FVector, Fquat)
        ET_Class, // all types that are a class (Uworld, UWorld*)
        ET_Enum, // all types that are a enum (EToastType)
        ET_Function //not needed, only needed for function definition
    }

    static string getTypeShort(EType type)
    {
        final switch (type)
        {
            case EType.ET_Default:
                return "D";
            case EType.ET_Struct:
                return "S";
            case EType.ET_Class:
                return "C";
            case EType.ET_Enum:
                return "E";
            case EType.ET_Function:
                return "F";
        }
    }

    // MemberType struct holds information about the members type
    struct MemberType
    {
        EType type; // the EType of the membertype
        string typeName; // the name of the type, e.g UClass (this should not contain any * or & !!)
        string extendedType; // if the type is a UClass* make sure the * is in here!! If not, this can be left empty
        bool reference = false; // only needed in function parameters. Ignore otherwise
        MemberType[] subTypes; // most of the times empty, just needed if the MemberType is a template, e.g TArray<abc>

        /**
         * \brief creates a JSON with all the information about the MemberType and SubTypes
         * \return returns a JSON with all the information about the MemberType and SubTypes
         */
        JSONValue jsonify() const
        {
            // create an array for the memberType
            JSONValue[] arr;
            arr ~= JSONValue(typeName); // first the typeName
            arr ~= JSONValue(getTypeShort(type)); // then the short Type
            arr ~= JSONValue(extendedType); // then any extended type
            
            JSONValue[] subTypeArr;
            foreach (const ref subType; subTypes)
                subTypeArr ~= subType.jsonify();
            
            arr ~= JSONValue(subTypeArr);

            return JSONValue(arr);
        }
    }

    // MemberDefinition contains all the information of the member needed
    struct MemberDefinition
    {
        MemberType memberType;
        string memberName;
        int offset;
        int bitOffset;
        int size;
        int arrayDim;
    }

    // FunctionHolder contains all the information about a function
    struct FunctionHolder
    {
        string functionName; // the name of the function e.g getWeapon
        string functionFlags; // flags how to call the function e.g Blueprint|Static|abc
        uintptr_t functionOffset; // offset of the function within the binary
        MemberType returnType; // the return type, if there's no, pass void
        Tuple!(MemberType, string)[] functionParams; // the function params with their type and name
    }

    // ClassHolder contains information about a struct or class
    struct ClassHolder
    {
        int classSize;
        EType classType;
        string className;
        string[] inheritedTypes;
        MemberDefinition[] members;
        FunctionHolder[] functions;
    }

    // EnumHolder contains information about an enum
    struct EnumHolder
    {
        string enumType; // enum type, uint32_t or int or uint64_t
        string enumName; // name of the enum 
        Tuple!(string, int)[] enumMembers; // enum members, their name and representative number (abc = 5)
    }

    private:
    static string directory;
    static string dumpTimeStamp;
    
    // Storage containers
    static JSONValue[string] offsets;
    static ClassHolder[] classes;
    static FunctionHolder[] functions;
    static ClassHolder[] structs;
    static EnumHolder[] enums;

    public:
    /**
     * \brief default constructor
     */
    this()
    {
    }

    /**
     * \brief sets the directory where all json files will be dumped to
     * \param directory the directory
     */
    static void setDirectory(string directoryPath)
    {
        directory = directoryPath;
        dumpTimeStamp = Clock.currTime().toISOExtString();
    }

    /**
     * \brief adds an offset to the offset json
     * \param name the name of the offset
     * \param offset the actual offset
     */
    static void addOffset(string name, uintptr_t offset)
    {
        offsets[name] = JSONValue(offset);
    }

    /**
     * \brief creates a ClassHolder or StructHolder
     * \param name name of the struct or class
     * \param isClass whether this is a class or struct
     * \param size size of the struct or class
     * \param inheritedClasses any inherited classes
     * \return a ClassHolder
     */
    static ClassHolder createStructOrClass(
        string name,
        bool isClass = true,
        int size = 0,
        string[] inheritedClasses = []
    )
    {
        ClassHolder holder;
        holder.className = name;
        holder.classType = isClass ? EType.ET_Class : EType.ET_Struct;
        holder.classSize = size;
        holder.inheritedTypes = inheritedClasses.dup;
        return holder;
    }

    /**
     * \brief creates a MemberType struct. Creating a MemberType is only really needed if the Member is a template type and has subTypes or if the Member is a subtype
     * \param type EType (e.g TArray<int> -> EType::ET_Class)
     * \param typeName the name (e.g TArray)
     * \param extendedType the extended type (e.g TArray<abc>& -> &, TArray<def>* -> *, or empty if there's no extended type)
     * \param subTypes any subtypes (e.g TArray<int> -> "int" is the subtype, or empty if there are no subtypes)
     * \param isReference leave this false, unless you create a memberType for a function which is a reference
     * \return the MemberType struct
     */
    static MemberType createMemberType(
        EType type,
        string typeName,
        string extendedType = "",
        MemberType[] subTypes = [],
        bool isReference = false
    )
    {
        MemberType memberType;
        memberType.type = type;
        memberType.typeName = typeName;
        memberType.extendedType = extendedType;
        memberType.subTypes = subTypes.dup;
        memberType.reference = isReference;
        return memberType;
    }

    // Convenience overload for the original C++ interface
    static void addMemberToStructOrClass(
        ref ClassHolder classHolder,
        string memberName,
        EType type,
        string typeName,
        string extendedType,
        int offset,
        int size,
        int arrayDim = 1,
        int bitOffset = -1
    )
    {
        MemberType memberType = createMemberType(type, typeName, extendedType);
        addMemberToStructOrClass(classHolder, memberName, memberType, offset, size, arrayDim, bitOffset);
    }

    /**
     * \brief adds a member to an existing ClassHolder
     * \param classHolder the target class or struct holder
     * \param memberName the name of the member
     * \param memberType the MemberType of the member
     * \param offset the offset within the struct or class
     * \param size the size of the member
     * \param arrayDim the array dimensions (default: 1)
     * \param bitOffset the bit offset (if this member is a bit flag), defaults to -1
     */
    static void addMemberToStructOrClass(
        ref ClassHolder classHolder,
        string memberName,
        const ref MemberType memberType,
        int offset,
        int size,
        int arrayDim = 1,
        int bitOffset = -1
    )
    {
        MemberDefinition m;
        m.memberType = memberType;
        m.memberName = memberName;
        m.offset = offset;
        m.size = size;
        m.arrayDim = arrayDim;
        m.bitOffset = bitOffset;

        classHolder.members ~= m;
    }

    /**
     * \brief creates a EnumHolder
     * \param enumName the name of the enum
     * \param enumType the type of the enum (int, uint32_t, uint64_t,...)
     * \param enumMembers enum members, their name and representative number (abc = 5)
     * \return the EnumHolder struct
     */
    static EnumHolder createEnum(
        string enumName,
        string enumType,
        Tuple!(string, int)[] enumMembers
    )
    {
        EnumHolder e;
        e.enumName = enumName;
        e.enumType = enumType;
        if (enumMembers.length > 0)
            e.enumMembers = enumMembers.dup;

        return e;
    }

    /**
     * \brief creates a FunctionHolder 
     * \param owningClass the owning class' or struct name this function resides in
     * \param functionName the name of the function e.g getWeapon
     * \param functionFlags flags how to call the function e.g Blueprint|Static|abc
     * \param functionOffset offset of the function within the binary
     * \param returnType the return type, if there's no, pass void
     * \param functionParams the function params with their type and name
     */
    static void createFunction(
        ref ClassHolder owningClass,
        string functionName,
        string functionFlags,
        uintptr_t functionOffset,
        const ref MemberType returnType,
        Tuple!(MemberType, string)[] functionParams = []
    )
    {
        FunctionHolder funcHolder;
        funcHolder.functionName = functionName;
        funcHolder.functionFlags = functionFlags;
        funcHolder.functionOffset = functionOffset;
        funcHolder.returnType = returnType;
        funcHolder.functionParams = functionParams.dup;

        owningClass.functions ~= funcHolder;
    }

    /**
     * \brief bakes a ClassHolder which gets later dumped
     * \param classHolder the classHolder that should get baked
     */
    static void bakeStructOrClass(ref ClassHolder classHolder)
    {
        if (classHolder.classType == EType.ET_Class)
        {
            classes ~= classHolder;
        }
        else
        {
            structs ~= classHolder;
        }
    }

    /**
     * \brief bakes a EnumHolder which gets later dumped
     * \param enumHolder the enumHolder that should get baked
     */
    static void bakeEnum(ref EnumHolder enumHolder)
    {
        enums ~= enumHolder;
    }

    /**
     * \brief dumps all baked information to disk. This should be the final step
     */
    static void dump()
    {
        if (directory.length == 0)
            throw new Exception("Please initialize a directory first!");

        enum int version_ = 10202;

        void saveToDisk(JSONValue json, string fileName, bool offsetFile = false)
        {
            JSONValue j;
            j["updated_at"] = JSONValue(dumpTimeStamp);
            j["data"] = json;
            j["version"] = JSONValue(version_);

            if (offsetFile)
            {
                JSONValue credit;
                credit["dumper_used"] = JSONValue("Dumper-7");
                credit["dumper_link"] = JSONValue("https://github.com/Encryqed/Dumper-7");
                j["credit"] = credit;
            }

            string filePath = buildPath(directory, fileName);
            std.file.write(filePath, j.toString());
        }

        saveToDisk(JSONValue(offsets), "OffsetsInfo.json", true);
        saveToDisk(convertClassesToJSON(classes), "ClassesInfo.json");
        saveToDisk(convertFunctionsToJSON(functions), "FunctionsInfo.json");
        saveToDisk(convertClassesToJSON(structs), "StructsInfo.json");
        saveToDisk(convertEnumsToJSON(enums), "EnumsInfo.json");
    }

    private:
    static JSONValue convertClassesToJSON(const ref ClassHolder[] holders)
    {
        JSONValue result = JSONValue.emptyObject();
        
        foreach (const ref holder; holders)
        {
            JSONValue classData = JSONValue.emptyObject();
            classData["size"] = JSONValue(holder.classSize);
            classData["inherited"] = JSONValue(holder.inheritedTypes);
            
            JSONValue[] membersArray;
            foreach (const ref member; holder.members)
            {
                JSONValue memberData = JSONValue.emptyArray();
                memberData.array ~= JSONValue(member.memberName);
                memberData.array ~= member.memberType.jsonify();
                memberData.array ~= JSONValue(member.offset);
                memberData.array ~= JSONValue(member.size);
                memberData.array ~= JSONValue(member.arrayDim);
                memberData.array ~= JSONValue(member.bitOffset);
                membersArray ~= memberData;
            }
            classData["members"] = JSONValue(membersArray);
            
            JSONValue[] functionsArray;
            foreach (const ref func; holder.functions)
            {
                JSONValue funcData = JSONValue.emptyObject();
                funcData["name"] = JSONValue(func.functionName);
                funcData["flags"] = JSONValue(func.functionFlags);
                funcData["offset"] = JSONValue(func.functionOffset);
                funcData["return_type"] = func.returnType.jsonify();
                
                JSONValue[] paramsArray;
                foreach (const ref param; func.functionParams)
                {
                    JSONValue paramData = JSONValue.emptyArray();
                    paramData.array ~= param[0].jsonify(); // MemberType
                    paramData.array ~= JSONValue(param[1]); // string name
                    paramsArray ~= paramData;
                }
                funcData["params"] = JSONValue(paramsArray);
                functionsArray ~= funcData;
            }
            classData["functions"] = JSONValue(functionsArray);
            
            result[holder.className] = classData;
        }
        
        return result;
    }

    static JSONValue convertFunctionsToJSON(const ref FunctionHolder[] functions)
    {
        JSONValue result = JSONValue.emptyObject();
        
        foreach (const ref func; functions)
        {
            JSONValue funcData = JSONValue.emptyObject();
            funcData["flags"] = JSONValue(func.functionFlags);
            funcData["offset"] = JSONValue(func.functionOffset);
            funcData["return_type"] = func.returnType.jsonify();
            
            JSONValue[] paramsArray;
            foreach (const ref param; func.functionParams)
            {
                JSONValue paramData = JSONValue.emptyArray();
                paramData.array ~= param[0].jsonify(); // MemberType
                paramData.array ~= JSONValue(param[1]); // string name
                paramsArray ~= paramData;
            }
            funcData["params"] = JSONValue(paramsArray);
            
            result[func.functionName] = funcData;
        }
        
        return result;
    }

    static JSONValue convertEnumsToJSON(const ref EnumHolder[] enums)
    {
        JSONValue result = JSONValue.emptyObject();
        
        foreach (const ref enumHolder; enums)
        {
            JSONValue enumData = JSONValue.emptyObject();
            enumData["type"] = JSONValue(enumHolder.enumType);
            
            JSONValue membersData = JSONValue.emptyObject();
            foreach (const ref member; enumHolder.enumMembers)
            {
                membersData[member[0]] = JSONValue(member[1]);
            }
            enumData["members"] = membersData;
            
            result[enumHolder.enumName] = enumData;
        }
        
        return result;
    }
}

// Helper alias for tuples  
import std.typecons : Tuple;