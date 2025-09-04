module main;

import core.sys.windows.windows;
import std.stdio;
import std.datetime.stopwatch;
import std.conv;
import std.string;

import generators.cppgenerator;
import generators.mappinggenerator;
import generators.idamappinggenerator;
import generators.dumpspacegenerator;
import generators.generator;
import settings;

enum EFortToastType : ubyte
{
    Default = 0,
    Subdued = 1,
    Impactful = 2,
    EFortToastType_MAX = 3
}

extern(Windows) DWORD MainThread(HMODULE hModule)
{
    AllocConsole();
    freopen("CONOUT$", "w", stderr);
    freopen("CONIN$", "r", stdin);

    auto stopwatch = StopWatch(AutoStart.yes);

    stderr.writeln("Started Generation [Dumper-7]!");

    Settings.Config.load();

    if (Settings.Config.sleepTimeout > 0)
    {
        stderr.writefln("Sleeping for %dms...", Settings.Config.sleepTimeout);
        Sleep(Settings.Config.sleepTimeout);
    }

    Generator.initEngineCore();
    Generator.initInternal();

    if (Settings.Generator.gameName.length == 0 && Settings.Generator.gameVersion.length == 0)
    {
        // Only Possible in Main()
        import unreal.unrealtypes : FString;
        import unreal.unrealobjects : UEClass, UEFunction, ConcreteUEClass, ConcreteUEFunction;
        import unreal.objectarray : ObjectArray;

        FString name;
        FString version_;
        auto kismet = new ConcreteUEClass();
        auto getGameName = new ConcreteUEFunction();
        auto getEngineVersion = new ConcreteUEFunction();

        if (kismet !is null)
        {
            kismet.processEvent(getGameName, &name);
            kismet.processEvent(getEngineVersion, &version_);

            Settings.Generator.gameName = name.toString();
            Settings.Generator.gameVersion = version_.toString();
        }
    }

    stderr.writefln("GameName: %s", Settings.Generator.gameName);
    stderr.writefln("GameVersion: %s", Settings.Generator.gameVersion);
    stderr.writeln();

    Generator.generate!CppGenerator();
    Generator.generate!MappingGenerator();
    Generator.generate!IDAMappingGenerator();
    Generator.generate!DumpspaceGenerator();

    stopwatch.stop();
    
    stderr.writefln("\n\nGenerating SDK took (%s ms)\n\n", stopwatch.peek.total!"msecs");

    while (true)
    {
        if (GetAsyncKeyState(VK_F6) & 1)
        {
            fclose(stderr);
            FreeConsole();
            FreeLibraryAndExitThread(hModule, 0);
        }
        Sleep(100);
    }

    return 0;
}

extern(Windows) BOOL DllMain(HINSTANCE hModule, DWORD dwReason, LPVOID lpReserved)
{
    switch (dwReason)
    {
        case DLL_PROCESS_ATTACH:
            CreateThread(null, 0, &MainThread, hModule, 0, null);
            break;
        default:
            break;
    }
    return TRUE;
}