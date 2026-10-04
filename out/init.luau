local TS = _G[script]
local Jabby = TS.import(script, TS.getModule(script, "@rbxts", "jabby").out)

type SystemInfo = {
	category: string?,
	name: string,
	phase: any,
	system: (...any) -> ...any,
}

type HookArgs = {
	scheduler: any,
	system: SystemInfo,
	nextFn: (...any) -> ...any,
}

type SystemsAddRemove = {
	scheduler: any,
	system: SystemInfo,
}

type SystemsReplace = {
	scheduler: any,
	new: SystemInfo,
	old: SystemInfo,
}

local Plugin = {}
Plugin.__index = Plugin

local n = 0

local function containsPhase(dependency: any, phase: any): boolean
	if dependency == phase then return true end
	if type(dependency) ~= "table" or dependency._type ~= "pipeline" then return false end

	for _, child in dependency.dependencyGraph.nodes do
		if containsPhase(child, phase) then return true end
	end

	return false
end

local function resolveSchedules(scheduler: any, phase: any): {string}?
	local schedules = {}

	for identifier, dependencyGraph in scheduler._eventDependencyGraphs do
		local contains = false
		for _, dependency in dependencyGraph.nodes do
			if containsPhase(dependency, phase) then
				contains = true
				break
			end
		end

		if not contains then continue end
		local schedule = string.match(identifier, "@([^@]+)$")
		if schedule and not table.find(schedules, schedule) then
			table.insert(schedules, schedule)
		end
	end

	table.sort(schedules)
	return if #schedules > 0 then schedules else nil
end

local function toJabbyData(scheduler: any, systemInfo: SystemInfo)
	return {
		category = tostring(systemInfo.phase),
		subcategory = systemInfo.category,
		schedules = resolveSchedules(scheduler, systemInfo.phase),
		name = systemInfo.name,
	}
end

function Plugin:build(scheduler: any)
	n += 1

	local identifier = n > 1 and ` #{n}` or ""
	local name = `Planck{identifier}`

	local jabbyScheduler = Jabby.scheduler.create()
	local systemToId = {}
	local addSystem = scheduler.addSystem

	-- Planck 1.x keeps only its built-in fields in _systemInfo. Capture custom
	-- SystemTable metadata after registration and immediately refresh Jabby.
	scheduler.addSystem = function(self: any, system: any, phase: any)
		local result = addSystem(self, system, phase)

		if type(system) == "table" then
			local systemInfo = self._systemInfo[system.system]
			if systemInfo then
				systemInfo.category = system.category
				systemInfo.subcategory = system.subcategory

				local id = systemToId[system.system]
				if id then
					jabbyScheduler:set_system_data(id, toJabbyData(self, systemInfo))
				end
			end
		end

		return result
	end

	for systemFn, systemInfo in scheduler._systemInfo do
		local id = jabbyScheduler:register_system(toJabbyData(scheduler, systemInfo))
		systemToId[systemFn] = id
	end

	scheduler:_addHook(
		scheduler.Hooks.SystemAdd,
		function(info: SystemsAddRemove)
			local id = jabbyScheduler:register_system(toJabbyData(scheduler, info.system))
			systemToId[info.system.system] = id
		end
	)

	scheduler:_addHook(
		scheduler.Hooks.SystemRemove,
		function(info: SystemsAddRemove)
			jabbyScheduler:remove_system(systemToId[info.system.system])
			systemToId[info.system.system] = nil
		end
	)

	scheduler:_addHook(
		scheduler.Hooks.SystemReplace,
		function(info: SystemsReplace)
			local newSystem = info.new.system
			local oldSystem = info.old.system

			jabbyScheduler:remove_system(systemToId[oldSystem])
			systemToId[oldSystem] = nil

			local id = jabbyScheduler:register_system(toJabbyData(scheduler, info.new))
			systemToId[newSystem] = id
		end
	)

	local STARTUP_PHASES = { "PreStartup", "Startup", "PostStartup" }
	local startupSystems = {}

	scheduler:_addHook(scheduler.Hooks.SystemCall, function(args: HookArgs)
		local id = systemToId[args.system.system]

		return function()
			for startupId in startupSystems do
				jabbyScheduler:set_system_data(startupId, {
					paused = true,
				})
			end

			jabbyScheduler:run(id, function()
				args.nextFn()

				local phase = tostring(args.system.phase)
				if table.find(STARTUP_PHASES, phase) then
					startupSystems[id] = true
				end
			end)
		end
	end)

	Jabby.register({
		applet = Jabby.applets.scheduler,
		name = name,
		configuration = {
			scheduler = jabbyScheduler,
		},
	})
end

function Plugin.new()
	return setmetatable({}, Plugin)
end

type SchedulerLike<U...> = {
	addPlugin: (
		self: SchedulerLike<U...>,
		plugin: Plugin<U...>
	) -> SchedulerLike<U...>,
	new: (U...) -> SchedulerLike<U...>,
	[any]: any,
}

type Plugin<U...> = {
	build: (self: Plugin<U...>, scheduler: SchedulerLike<U...>) -> (),
	cleanup: ((self: Plugin<U...>) -> ())?,
	new: () -> Plugin<U...>,
}

return (Plugin :: any) :: Plugin<...any>
