--- Handles tasks and dependencies
-- @classmod howl.tasks.Runner

local Task = require "howl.tasks.task"
local Context = require "howl.tasks.context"
local Utils = require "howl.lib.utils"
local class = require "howl.lib.middleclass"
local mixin = require "howl.lib.mixin"

--- Handles a collection of tasks and running them
-- @type Runner
local Runner = class("howl.tasks.Runner"):include(mixin.sealed)

--- Create a task
-- @tparam string name The name of the task to create
-- @treturn function A builder for tasks
function Runner:Task(name)
	return function(dependencies, action) return self:AddTask(name, dependencies, action) end
end

--- Add a task to the collection
-- @tparam string name The name of the task to add
-- @tparam table dependencies A list of tasks this task requires
-- @tparam function action The action to run
-- @treturn Task The created task
function Runner:AddTask(name, dependencies, action)
	return self:InjectTask(Task.Task(name, dependencies, action))
end

--- Add a Task object to the collection
-- @tparam Task task The task to insert
-- @tparam string name The name of the task (optional)
-- @treturn Task The current task
function Runner:InjectTask(task, name)
	self.tasks[name or task.name] = task
	return task
end

--- Set the default task
-- @tparam ?|string|function task The task to run or the name of the task
-- @treturn Runner The current object for chaining
function Runner:Default(task)
	local defaultTask
	if task == nil then
		self.default = nil
	elseif type(task) == "string" then
		self.default = self.tasks[task]
		if not self.default then
			error("Cannot find task " .. task)
		end
	else
		self.default = Task.Task("<default>", {}, task)
	end

	return self
end

--- Run a task, and all its dependencies
-- @tparam string name Name of the task to run
-- @treturn Runner The current object for chaining
function Runner:Run(name)
	return self:RunMany({ name })
end

--- Run a task, and all its dependencies
-- @tparam table names Names of the tasks to run
-- @return The result of the last task
function Runner:RunMany(names)
	local oldTime = os.clock()
	local value

	local context = Context(self)
	if #names == 0 then
		context:Start()
	else
		for _, name in ipairs(names) do
			value = context:Start(name)
		end
	end

	if context.ShowTime then
		Utils.PrintColor(colors.orange, "Took " .. os.clock() - oldTime .. "s in total")
	end

	return value
end

--- Create a @{Runner} object
-- @tparam env env The current environment
-- @treturn Runner The created runner object
function Runner:initialize(env)
	self.tasks = {}
	self.default = nil
	self.env = env
end

return Runner