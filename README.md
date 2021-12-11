# RBXDeepEngine
WIP

Deep Engine; Deep Game Framework; DGF

Game framework for Roblox, used by myself and my developer group dubbed Studio Deep

Dynamese(Enduo) 
July 1st, 2021

Assets:
    Please follow the Template asset and Template asset class structuring for
    asset creation in your game
    The "FORBIDDEN" bool value is a marker to disallow a client from downloading it
    This could also be used to detect data-mining
    
Client:
    This is the client environment and where the client's game code will entirely reside
    Any classes, enums, services, etc. defined here will only be accessible from the client
    
Server:
    This is the server environment and where the server's game code will entirely reside
    Any classes, enums, services, etc. defined here will only be accessible from the server
    
Shared:
    Anything in this folder will be cloned into both the client and server environments
    HOWEVER THE CLONED CONTENTS !! DO NOT !! REPLICATE STATE DURING RUNTIME
    
Roblox:
    This folder's contents will be automatically distributed to Roblox Services
    such as the Router remote into ReplicatedStorage

Classes:
    Custom classes go here, see ClassTemplate for syntax
    
Enums:
    Enumerators are accessible from any service module, each enum is defined as a key:value mapping
    to be used in a manner such as Engine.Enums.NetProtocol.Response, see TemplateEnum for syntax
        
Modules:
    External modules that are not immediately loaded before runtime and are instead required 
    on first reference by other code during runtime
    There are no requirements imposed on these modules
    
Services:
    The meat of your game will be defined in services, see TemplateService for syntax
    Every service has the following injected into "self":
        Services
        Enums
        Instancer
        RBXServices
        LocalPlayer -> ONLY ON THE CLIENT
        Priority -> DEFAULT 0
    Priority determines the ordering by which services are initialized via Service:EngineInit()
        A more positive priority gaurantees an earlier initialization
        0 is default
        1000 is SyncService
        1001 is MetronomeService

Plugins:
    Any modules placed inside the Plugins folder(s) are guaranteed to automatically 
    run AFTER the environment has 100% started
    There are no requirements imposed on these modules

Preloads:
    Modules placed inside this folder will be interpreted as lists of BaseIDs to
    preload into the client's asset cache
    Please format these modules to return an array-like e.g.
    
    return {
        "FF0";
        "FF1";
    }
    
    return { "FF0"; "FF1"; }
        
Loading Screen:
    See Roblox.ReplicatedFirst.DeepLoad
    
Using Deep Engine from an external-to-the-framework code container:
    _G.Deep
    _G.DeepEngineOnline
    
Extending Deep Engine:

    -- Adds functionality to the Framework such as a Network service,
    --	eliminating the extra "Services" layer when indexing from an Framework module
    --	e.g. self.Services.Network -> self.Network
    -- @param key
    -- @param value
    Engine:ExtendEngine(key, value)

    -- Writes a value to a key at the Framework level (Engine.Blackboard)
    -- @param key
    -- @param value
    Engine:SetEngineVariable(key, value)

    -- Retrieves a value stored in Engine.Blackboard[key]
    -- @param key
    -- @return value
    Engine:GetEngineVariable(key)
