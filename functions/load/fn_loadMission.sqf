#include "script_component.hpp"

private _saveUnits = ([missionConfigFile >> "CfgGradPersistence", "saveUnits", 1] call BIS_fnc_returnConfigEntry) > 0;
if (_saveUnits) then {[] call FUNC(loadGroups)};

private _saveVehicles = ([missionConfigFile >> "CfgGradPersistence", "saveVehicles", 1] call BIS_fnc_returnConfigEntry) > 0;
if (_saveVehicles) then {[] call FUNC(loadVehicles)};

private _saveVehicles = ([missionConfigFile >> "CfgGradPersistence", "saveContainers", 1] call BIS_fnc_returnConfigEntry) > 0;
if (_saveVehicles) then {[] call FUNC(loadContainers)};

private _saveStatics = ([missionConfigFile >> "CfgGradPersistence", "saveStatics", 1] call BIS_fnc_returnConfigEntry) > 0;
if (_saveStatics) then {[] call FUNC(loadStatics)};

private _saveMarkers = ([missionConfigFile >> "CfgGradPersistence", "saveMarkers", 1] call BIS_fnc_returnConfigEntry) > 0;
if (_saveMarkers) then {[] call FUNC(loadMarkers)};

private _saveTeamAccounts = ([missionConfigFile >> "CfgGradPersistence", "saveTeamAccounts", 1] call BIS_fnc_returnConfigEntry) > 0;
if (_saveTeamAccounts) then {[] call FUNC(loadTeamAccounts)};

private _saveTasks = ([missionConfigFile >> "CfgGradPersistence", "saveTasks", 0] call BIS_fnc_returnConfigEntry) > 0;
if (_saveTasks) then {[] call FUNC(loadTasks)};

private _saveTriggers = ([missionConfigFile >> "CfgGradPersistence", "saveTriggers", 0] call BIS_fnc_returnConfigEntry) > 0;
if (_saveTriggers) then {[] call FUNC(loadTriggers)};
[] spawn {
	 waitUntil {time > 0};
	{
		_veh = (_x select 0);
		_veh_id = (_x select 1);
		{
			if ((_x select 1)==_veh_id) then {
				_loaded = _veh setVehicleCargo (_x select 0);
				if (!_loaded) then {
					(_x select 0) setVehiclePosition [(_x select 0),[],1,"NONE"];
				};
			};
		} forEach grad_viv_cargo_array;
	} forEach grad_viv_carrier_array;
	{(_x select 0) hideObject false;} forEach grad_viv_cargo_array;
};

INFO("mission loaded");
"grad-persistence: mission loaded" remoteExec ["systemChat",0,false];
