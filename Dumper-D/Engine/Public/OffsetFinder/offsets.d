module offsetfinder.offsets;

// Basic offset structure for Unreal Engine
struct Off
{
    struct InSDK
    {
        struct ProcessEvent
        {
            static int peIndex = 0;
            
            static void initPE(int index)
            {
                peIndex = index;
            }
        }
        
        struct Name
        {
            static bool bIsUsingAppendStringOverToString = false;
        }
    }
}