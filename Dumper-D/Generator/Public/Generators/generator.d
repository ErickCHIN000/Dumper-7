module generators.generator;

import std.file;
import std.path;
import std.stdio;
import std.string;
import std.conv;

import settings;
import unreal.objectarray;

// Generator interface/concept
interface GeneratorImplementation
{
    static string getMainFolderName();
    static string getSubfolderName();
    static void initPredefinedMembers();
    static void initPredefinedFunctions();
    static void generate();
}

class Generator
{
    private:
    static string dumperFolder;
    static bool bDumpedGObjects = false;

    public:
    static void initEngineCore()
    {
        /* manual override */
        //ObjectArray::Init(/*GObjects*/, /*Layout = Default*/); // FFixedUObjectArray (UEVersion < UE4.21)
        //ObjectArray::Init(/*GObjects*/, /*ChunkSize*/, /*Layout = Default*/); // FChunkedFixedUObjectArray (UEVersion >= UE4.21)

        //FName::Init(/*bForceGNames = false*/);
        //FName::Init(/*AppendString, FName::EOffsetOverrideType::AppendString*/);
        //FName::Init(/*ToString, FName::EOffsetOverrideType::ToString*/);
        //FName::Init(/*GNames, FName::EOffsetOverrideType::GNames, true/false*/);
 
        //Off::InSDK::ProcessEvent::InitPE(/*PEIndex*/);

        /* Back4Blood (requires manual GNames override) */
        // Implementation specific initialization would go here
    }

    static void initInternal()
    {
        Settings.initWeakObjectPtrSettings();
        Settings.initLargeWorldCoordinateSettings();
        Settings.initObjectPtrPropertySettings();
        Settings.initArrayDimSizeSettings();
    }

    private:
    static bool setupDumperFolder()
    {
        dumperFolder = Settings.Generator.sdkGenerationPath;
        
        try
        {
            if (!exists(dumperFolder))
            {
                mkdirRecurse(dumperFolder);
            }
            return true;
        }
        catch (Exception e)
        {
            stderr.writefln("Could not create dumper folder: %s", e.msg);
            return false;
        }
    }

    static bool setupFolders(ref string folderName, ref string outFolder)
    {
        string dummy = "";
        return setupFolders(folderName, outFolder, dummy, dummy);
    }

    static bool setupFolders(ref string folderName, ref string outFolder, ref string subfolderName, ref string outSubFolder)
    {
        // Make valid file names
        folderName = makeValidFileName(folderName);
        subfolderName = makeValidFileName(subfolderName);

        try
        {
            outFolder = buildPath(dumperFolder, folderName);
            outSubFolder = buildPath(outFolder, subfolderName);

            if (exists(outFolder))
            {
                string oldPath = outFolder ~ "_OLD";
                if (exists(oldPath))
                {
                    rmdirRecurse(oldPath);
                }
                rename(outFolder, oldPath);
            }

            mkdirRecurse(outFolder);

            if (subfolderName.length > 0)
            {
                mkdirRecurse(outSubFolder);
            }
        }
        catch (Exception e)
        {
            stderr.writefln("Could not create required folders! Info: %s", e.msg);
            return false;
        }

        return true;
    }

    static string makeValidFileName(string name)
    {
        import std.array : replace;
        import std.algorithm : canFind;
        
        string result = name;
        
        // Replace invalid characters
        static immutable char[] invalidChars = ['\\', '/', ':', '*', '?', '"', '<', '>', '|'];
        foreach (char c; invalidChars)
        {
            result = result.replace([c], "_");
        }
        
        return result;
    }

    public:
    static void generate(T)()
        if (is(T : GeneratorImplementation))
    {
        if (dumperFolder.length == 0)
        {
            if (!setupDumperFolder())
                return;

            if (!bDumpedGObjects)
            {
                bDumpedGObjects = true;
                // ObjectArray.dumpObjects(dumperFolder);

                // if (Settings.Internal.bUseFProperty)
                //     ObjectArray.dumpObjectsWithProperties(dumperFolder);
            }
        }

        string mainFolderName = T.getMainFolderName();
        string subfolderName = T.getSubfolderName();
        string mainFolder;
        string subfolder;
        
        if (!setupFolders(mainFolderName, mainFolder, subfolderName, subfolder))
            return;

        T.initPredefinedMembers();
        T.initPredefinedFunctions();

        // MemberManager.setPredefinedMemberLookupPtr(&T.PredefinedMembers);

        T.generate();
    }
}