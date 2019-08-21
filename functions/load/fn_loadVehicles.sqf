#include "script_component.hpp"

if (!isServer) exitWith {};

private _missionTag = [] call grad_persistence_fnc_getMissionTag;
private _vehiclesTag = _missionTag + "_vehicles";
private _vehiclesData = [_vehiclesTag] call grad_persistence_fnc_getSaveData;

{

    private _thisVehicleHash = _x;
    private _type = [_thisVehicleHash,"type"] call CBA_fnc_hashGet;
    private _side = [_thisVehicleHash,"side"] call CBA_fnc_hashGet;
    private _hasCrew = [_thisVehicleHash,"hasCrew"] call CBA_fnc_hashGet;
    private _vehVarName = [_thisVehicleHash,"varName"] call CBA_fnc_hashGet;

    private _thisVehicle = objNull;
    private _editorVehicleFound = false;
    if (!isNil "_vehVarName") then {
        // editor-placed object that already exists
        private _editorVehicle = call compile _vehVarName;
        if (!isNil "_editorVehicle") then {
            _thisVehicle = _editorVehicle;
            _editorVehicleFound = true;
        };
    };

    if (!_editorVehicleFound) then {
        //idk, weird shit happens when you use createVehicle and add crew
        _thisVehicle = if (!_hasCrew) then {
            createVehicle [_type, [0,0,0], [], 0, "CAN_COLLIDE"]
        } else {
            ([[0,0,0],0,_type,_side] call BIS_fnc_spawnVehicle) select 0
        };

        if (!isNil "_vehVarName") then {
            [_thisVehicle,_vehVarName] remoteExec ["setVehicleVarName",0,_thisVehicle];
        };

    };

    [{!isNull (_this select 0)}, {
        params ["_thisVehicle","_thisVehicleHash"];

        private _posASL = [_thisVehicleHash,"posASL"] call CBA_fnc_hashGet;
        private _fuel = [_thisVehicleHash,"fuel"] call CBA_fnc_hashGet;
        private _vectorDirAndUp = [_thisVehicleHash,"vectorDirAndUp"] call CBA_fnc_hashGet;
        private _hitPointDamage = [_thisVehicleHash,"hitpointDamage"] call CBA_fnc_hashGet;
        private _turretMagazines = [_thisVehicleHash,"turretMagazines"] call CBA_fnc_hashGet;
        private _inventory = [_thisVehicleHash,"inventory"] call CBA_fnc_hashGet;
        private _isGradFort = [_thisVehicleHash,"isGradFort"] call CBA_fnc_hashGet;
    	private _vehicleVIVCargoID = [_thisVehicleHash,"VIVCargoID"] call CBA_fnc_hashGet;
    	private _vehicleCargoID = [_thisVehicleHash,"CargoID"] call CBA_fnc_hashGet;
        private _vehicleAnimSources = [_thisVehicleHash,"animationSources"] call CBA_fnc_hashGet;
        private _vehicleCargoMode = [_thisVehicleHash,"CargoEnabled"] call CBA_fnc_hashGet;
        private _vehicleSlingMode = [_thisVehicleHash,"SlingEnabled"] call CBA_fnc_hashGet;
        private _lockedCrew = [_thisVehicleHash,"lockedCrew"] call CBA_fnc_hashGet;
	private _hiddenSelections = [_thisVehicleHash,"hiddenSelections"] call CBA_fnc_hashGet;

        _thisVehicle setVectorDirAndUp _vectorDirAndUp;
        _thisVehicle setPosASL _posASL;
        _thisVehicle setFuel _fuel;

	_thisVehicle lockDriver (_lockedCrew select 0);
	{_thisVehicle lockTurret _x} forEach (_lockedCrew select 1);
	{_thisVehicle lockCargo _x} forEach (_lockedCrew select 2);

        _thisVehicle enableRopeAttach _vehicleSlingMode;
        _thisVehicle enableVehicleCargo _vehicleCargoMode;
        { _thisVehicle animateSource [_x select 0,_x select 1,true] } forEach _vehicleAnimSources;
        //{ _thisVehicle lockCargo [_x select 0, _x select 1] } forEach _lockedPassengers;
	{ _thisVehicle setObjectTexture [_forEachIndex,_x] } forEach _hiddenSelections;

        [_thisVehicle,_turretMagazines] call grad_persistence_fnc_loadTurretMagazines;
        [_thisVehicle,_hitPointDamage] call grad_persistence_fnc_loadVehicleHits;
        [_thisVehicle,_inventory] call grad_persistence_fnc_loadVehicleInventory;

        if (_isGradFort && {isClass (missionConfigFile >> "CfgFunctions" >> "GRAD_fortifications")}) then {
            [_thisVehicle,objNull] remoteExec ["grad_fortifications_fnc_initFort",0,true];
        };

        private _vars = [_thisVehicleHash,"vars"] call CBA_fnc_hashGet;
        [_vars,_thisVehicle] call FUNC(loadObjectVars);
        _thisVehicle setVariable ["vehicle_cargo_id",_vehicleCargoID];
        if (_vehicleVIVCargoID != "NO_ID_SET") then {
		grad_viv_cargo_array pushBack [_thisVehicle,_vehicleVIVCargoID];
		_thisVehicle hideObject true;
        };
        grad_viv_carrier_array pushBack [_thisVehicle,_vehicleCargoID];


    }, [_thisVehicle,_thisVehicleHash]] call CBA_fnc_waitUntilAndExecute;


} forEach _vehiclesData;

// delete all editor vehicles that were killed in a previous save
private _killedVarnames = [_missionTag + "_killedVarnames"] call FUNC(getSaveData);
private _killedVehiclesVarnames = _killedVarnames param [1,[]];
{
    private _editorVehicle = call compile _x;
    if (!isNil "_editorVehicle") then {deleteVehicle _editorVehicle};
} forEach _killedVehiclesVarnames;
