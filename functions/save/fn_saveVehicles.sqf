#include "script_component.hpp"

if (!isServer) exitWith {};

params [["_area",false],["_allVariableClasses",[]]];

if (_area isEqualType []) then {
    _area params ["_center","_a","_b",["_angle",0],["_isRectangle",false],["_c",-1]];
    if (isNil "_b") then {_b = _a};
    _area = [_center,_a,_b,_angle,_isRectangle,_c];
};

private _allVehicleVariableClasses = _allVariableClasses select {
    ([_x,"varNamespace",""] call BIS_fnc_returnConfigEntry) == "vehicle"
};

private _missionTag = [] call FUNC(getMissionTag);
private _vehiclesTag = _missionTag + "_vehicles";
private _vehiclesData = [_vehiclesTag] call FUNC(getSaveData);
private _foundVehiclesVarnames = GVAR(allFoundVarNames) select 1;
_vehiclesData resize 0;

private _saveVehiclesMode = [missionConfigFile >> "CfgGradPersistence", "saveVehicles", 1] call BIS_fnc_returnConfigEntry;

private _allVehicles = vehicles select {
    !(_x isKindOf "Static") &&
    !((_x isKindOf "ThingX") && (([configfile >> "CfgVehicles" >> typeOf _x,"maximumLoad",0] call BIS_fnc_returnConfigEntry) > 0)) &&
    {alive _x} &&
    {!([_x] call FUNC(isBlacklisted))} &&
    {
        _saveVehiclesMode == 2 ||
        (_x getVariable [QGVAR(isEditorObject),false]) isEqualTo (_saveVehiclesMode == 1)
    } &&
    {if (_area isEqualType false) then {true} else {_x inArea _area}}
};

{
    private _thisVehicle = _x;
    private _hitPointDamage = getAllHitPointsDamage _thisVehicle;
    private _hitNames = [];
    private _hitDamages = [];
    if (count _hitPointDamage > 0) then {
        _hitNames = _hitPointDamage select 0;
        _hitDamages = _hitPointDamage select 2;
    };

    private _vehicleInventory = [_thisVehicle] call FUNC(getInventory);
    private _vehicleVIVCargo = (isVehicleCargo _thisVehicle);
    private _vehicleVIVCargoID = "NO_ID_SET";
    if (!isNull _vehicleVIVCargo) then {
	    _vehicleVIVCargoID = _vehicleVIVCargo getVariable ["vehicle_cargo_id","NO_ID_SET"];
	    if (_vehicleVIVCargoID isEqualTo "NO_ID_SET") then {
		private _tempPos = getPosASL _vehicleVIVCargo;
		_vehicleVIVCargoID = format ["%1_%2_%3_%4_%5",
			typeOf (_vehicleVIVCargo),
			floor((_tempPos select 0)*20),
			floor((_tempPos select 1)*20),
			floor((_tempPos select 2)*20),
			floor(getDir _vehicleVIVCargo)
		];
		_vehicleVIVCargo setVariable ["vehicle_cargo_id",_vehicleVIVCargoID];
	    };
    };
    private _vehicleAnimSources = [];
    private _vehicleCargoMode = vehicleCargoEnabled _thisVehicle;
    private _vehicleSlingMode = ropeAttachEnabled _thisVehicle;
    private _vehicleCamo = getObjectTextures _thisVehicle;
    private _vehicleCargoID = _thisVehicle getVariable ["vehicle_cargo_id","NO_ID_SET"];
    if (_vehicleCargoID isEqualTo "NO_ID_SET") then {
        private _tempPos = getPosASL _thisVehicle;
        _vehicleCargoID = format ["%1_%2_%3_%4_%5",
		typeOf (_thisVehicle),
		floor((_tempPos select 0)*20),
		floor((_tempPos select 1)*20),
		floor((_tempPos select 2)*20),
		floor(getDir _thisVehicleo)
	];
        _thisVehicle setVariable ["vehicle_cargo_id",_vehicleCargoID];
    };
        
   // private _lockedPassengers = [];
    private _lockedCargo = [];
    private _lockedDriver = lockedDriver _thisVehicle;
    private _lockedTurret = [];
    {
	if ((_x select 1)=="cargo") then {
		_lockedCargo pushBack [_x select 2,_thisVehicle lockedCargo (_x select 2)];
	};
	if ((_x select 1)=="Turret"||(_x select 1)=="gunner"||(_x select 1)=="commander") then {
		_lockedTurret pushBack [_x select 3, _thisVehicle lockedTurret (_x select 3)];
	};
    } forEach (fullCrew [_thisVehicle,"",true]);
    private _lockedCrew = [_lockedDriver,_lockedTurret,_lockedCargo];
    private _thisVehicleHash = [] call CBA_fnc_hashCreate;
    

    private _vehicleAnims = "getText (_x >> 'displayName')!=''" configClasses (configFile >> "cfgVehicles" >> (typeOf _thisVehicle) >> "AnimationSources");
    {
        _vehicleAnimSources pushBack [configName _x, (_thisVehicle animationSourcePhase (configName _x))];
    } forEach _vehicleAnims;
   // {
   //     _lockedPassengers pushBack [_x,(_thisVehicle lockedCargo _x)];
   // } forEach ((configFile >> "cfgVehicles" >> (typeOf _thisVehicle) >> "VIVPassengers") call bis_fnc_getCfgDataArray);


    private _vehVarName = vehicleVarName _thisVehicle;
    if (_vehVarName != "") then {
        [_thisVehicleHash,"varName",_vehVarName] call CBA_fnc_hashSet;
        _foundVehiclesVarnames deleteAt (_foundVehiclesVarnames find _vehVarName);
    };

    [_thisVehicleHash,"type",typeOf _thisVehicle] call CBA_fnc_hashSet;
    [_thisVehicleHash,"posASL",getPosASL _thisVehicle] call CBA_fnc_hashSet;
    [_thisVehicleHash,"vectorDirAndUp",[vectorDir _thisVehicle,vectorUp _thisVehicle]] call CBA_fnc_hashSet;
    [_thisVehicleHash,"hitpointDamage",[_hitNames,_hitDamages]] call CBA_fnc_hashSet;
    [_thisVehicleHash,"fuel",fuel _thisVehicle] call CBA_fnc_hashSet;
    [_thisVehicleHash,"hasCrew",{!isPlayer _thisVehicle} count (crew _thisVehicle) > 0] call CBA_fnc_hashSet;
    [_thisVehicleHash,"side",side _thisVehicle] call CBA_fnc_hashSet;
    [_thisVehicleHash,"turretMagazines", magazinesAllTurrets _thisVehicle] call CBA_fnc_hashSet;
    [_thisVehicleHash,"inventory", _vehicleInventory] call CBA_fnc_hashSet;
    [_thisVehicleHash,"isGradFort",!isNil {_thisVehicle getVariable "grad_fortifications_fortOwner"}] call CBA_fnc_hashSet;
    [_thisVehicleHash,"VIVCargoID",_vehicleVIVCargoID] call CBA_fnc_hashSet;
    [_thisVehicleHash,"CargoID",_vehicleCargoID] call CBA_fnc_hashSet;
    [_thisVehicleHash,"animationSources",_vehicleAnimSources] call CBA_fnc_hashSet;
    [_thisVehicleHash,"CargoEnabled",_vehicleCargoMode] call CBA_fnc_hashSet;
    [_thisVehicleHash,"SlingEnabled",_vehicleSlingMode] call CBA_fnc_hashSet;
    [_thisVehicleHash,"lockedCrew",_lockedCrew] call CBA_fnc_hashSet;
    [_thisVehicleHash,"hiddenSelections",_vehicleCamo] call CBA_fnc_hashSet;


    private _thisVehicleVars = [_allVehicleVariableClasses,_thisVehicle] call FUNC(saveObjectVars);
    [_thisVehicleHash,"vars",_thisVehicleVars] call CBA_fnc_hashSet;

    _vehiclesData pushBack _thisVehicleHash;
} forEach _allVehicles;

// all _foundVehiclesVarnames that were not saved must have been removed or killed --> add to killedVarNames array
private _killedVarnames = [_missionTag + "_killedVarnames"] call FUNC(getSaveData);
private _killedVehiclesVarnames = _killedVarnames param [1,[]];
_killedVehiclesVarnames append _foundVehiclesVarnames;
_killedVehiclesVarnames arrayIntersect _killedVehiclesVarnames;
_killedVarnames set [1,_killedVehiclesVarnames];


saveProfileNamespace;
