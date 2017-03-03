params [
    ["_savePlayerInventory",([missionConfigFile >> "CfgGradPersistence", "savePlayerInventory", 1] call BIS_fnc_returnConfigEntry) == 1],
    ["_savePlayerDamage",([missionConfigFile >> "CfgGradPersistence", "savePlayerDamage", 0] call BIS_fnc_returnConfigEntry) == 1],
    ["_savePlayerPosition",([missionConfigFile >> "CfgGradPersistence", "savePlayerPosition", 0] call BIS_fnc_returnConfigEntry) == 1]
];

_allPlayers = allPlayers select {_x isKindOf "Man"};

{
    [_x,false,_savePlayerInventory,_savePlayerDamage,_savePlayerPosition] call grad_persistence_fnc_savePlayer;
} count _allPlayers;

saveProfileNamespace;
