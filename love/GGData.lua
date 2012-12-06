-- Project: GGData
--
-- Date: August 31, 2012
--
-- File name: GGData.lua
--
-- Author: Graham Ranson of Glitch Games - www.glitchgames.co.uk
--
-- Comments: 
--
--		Many people have used Ice however as of late it seems to be experiencing weird 
--		issues. GGData is a trimmed down version to allow for better stability.
--
-- Copyright (C) 2012 Graham Ranson, Glitch Games Ltd.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this 
-- software and associated documentation files (the "Software"), to deal in the Software 
-- without restriction, including without limitation the rights to use, copy, modify, merge, 
-- publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
-- to whom the Software is furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all copies or 
-- substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
-- PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
-- DEALINGS IN THE SOFTWARE.
--
----------------------------------------------------------------------------------------------------

local GGData = {}
local GGData_mt = { __index = GGData }

local json = require( "json" )

--- Initiates a new GGData object.
-- @param id The name of the GGData to create or load ( if it already exists ).
-- @param path The path to the GGData. Optional, defaults to "boxes".
-- @param baseDir The base directory for the GGData. Optional, defaults to system.DocumentsDirectory.
-- @return The new object.
function GGData:new( id, path, baseDir )
    
    local self = {}
    
    setmetatable( self, GGData_mt )
    
    self.id = id
    self.path = path
    self.baseDir = baseDir
    
    if self.id then
    	self:load()
    end
    		
    return self
    
end

--- Loads, or reloads, this GGData object from disk.
-- @param id The id of the GGData object.
-- @param path The path to the GGData. Optional, defaults to "boxes".
-- @param baseDir The base directory for the GGData. Optional, defaults to system.DocumentsDirectory.
function GGData:load( id, path, baseDir )
	
	-- Set up the path
	path = path or "boxes/"
	
	-- Pre-declare the new GGData object
	local box
	
	-- If no id was passed in then assume we're working with a pre-loaded GGData object so use its id
	if not id then
		id = self.id
		box = self
	end
	
	local data = {}

	if not love.filesystem.isFile( path .. id .. ".box" ) then
		return
	end
	
	local contents, size = love.filesystem.read( path .. id .. ".box" )
	
	data = json.decode( contents )

	-- If no GGData exists then we are acting on a Class function i.e. not a pre-loaded GGData object.
	if not box then
		-- Create the new GGData object.
		box = GGData:new()
	end
	
	-- Copy all the properties across.
	for k, v in pairs( data ) do
		box[ k ] = v
	end
	
	return box
	
end

--- Saves this GGData object to disk.
function GGData:save()

	local data = {}
	
	-- Copy across all the properties that can be saved.
	for k, v in pairs( self ) do
		if type( v ) ~= "function" and type( v ) ~= "userdata" then
			data[ k ] = v
		end
	end
		
	data = json.encode( data )
	
	local path = "/boxes"
	
	local isDir = love.filesystem.isDirectory( path )
	local success
	
	if not isDir then
		success = love.filesystem.mkdir( path )
	end
	
	path = path .. "/" .. self.id .. ".box"
	
	love.filesystem.write( path, data )
	
end

--- Sets a value in this GGData object.
-- @param name The name of the value to set.
-- @param value The value to set.
function GGData:set( name, value )
	self[ name ] = value
end

--- Gets a value from this GGData object.
-- @param name The name of the value to get.
-- @return The value.
function GGData:get( name )
	return self[ name ]
end

--- Checks whether a value of this GGData object is higher than another value.
-- @param name The name of the first value to check.
-- @param otherValue The name of the other value to check. Can also be a number.
-- @return True if the first value is higher, false otherwise.
function GGData:isValueHigher( name, otherValue )
	if type( otherValue ) == "string" then
		otherValue = self:get( otherValue )
	end
	return self[ name ] > otherValue
end

--- Checks whether a value of this GGData object is lower than another value.
-- @param name The name of the first value to check.
-- @param otherValue The name of the other value to check. Can also be a number.
-- @return True if the first value is lower, false otherwise.
function GGData:isValueLower( name, otherValue )
	if type( otherValue ) == "string" then
		otherValue = self:get( otherValue )
	end
	return self[ name ] < otherValue
end

--- Checks whether a value of this GGData object is equal to another value.
-- @param name The name of the first value to check.
-- @param otherValue The name of the other value to check. Can also be a number.
-- @return True if the first value is equal, false otherwise.
function GGData:isValueEqual( name, otherValue )
	if type( otherValue ) == "string" then
		otherValue = self:get( otherValue )
	end
	return self[ name ] == otherValue
end

--- Checks whether this GGData object has a specific property or not.
-- @param name The name of the value to check.
-- @return True if the value exists and isn't nil, false otherwise.
function GGData:hasValue( name )
	return self[ name ] ~= nil and true or false
end

--- Sets a value on this GGData object if it is new.
-- @param name The name of the value to set.
-- @param value The value to set.
function GGData:setIfNew( name, value )
	if self[ name ] == nil then
		self[ name ] = value
	end
end

--- Sets a value on this GGData object if it is higher than the current value.
-- @param name The name of the value to set.
-- @param value The value to set.
function GGData:setIfHigher( name, value )
	if self[ name ] and value > self[ name ] or not self[ name ] then
		self[ name ] = value
	end
end

--- Sets a value on this GGData object if it is lower than the current value.
-- @param name The name of the value to set.
-- @param value The value to set.
function GGData:setIfLower( name, value )
	if self[ name ] and value < self[ name ] or not self[ name ] then
		self[ name ] = value
	end
end

--- Increments a value in this GGData object.
-- @param name The name of the value to increment. Must be a number.
-- @param amount The amount to increment. Optional, defaults to 1.
function GGData:increment( name, amount )
	if self[ name ] and type( self[ name ] ) == "number" then
		self[ name ] = self[ name ] + ( amount or 1 )
	end
end

--- Decrements a value in this GGData object.
-- @param name The name of the value to decrement. Must be a number.
-- @param amount The amount to decrement. Optional, defaults to 1.
function GGData:decrement( name, amount )
	if self[ name ] and type( self[ name ] ) == "number" then
		self[ name ] = self[ name ] - ( amount or 1 )
	end
end

--- Clears this GGData object.
function GGData:clear()
	for k, v in pairs( self ) do
		if k ~= "id" 
			and type( k ) ~= "function" then
				self[ k ] = nil
		end
	end
end

--- Deletes this GGData object from disk. 
-- @param id The id of the GGData to delete. Optional, only required if calling on a non-loaded object.
function GGData:delete( id )
	
	-- If no id was passed in then assume we're working with a pre-loaded GGData object so use its id
	if not id then
		id = self.id
	end
	
	love.filesystem.remove( "boxes/" .. id .. ".box" )
	
	if not success then
		return
	end
	
end

--- Gets the path to the stored file. Useful if you want to upload it.
-- @return Two paramaters; the full path and then the relative path.
function GGData:getFilename()
	local relativePath = "boxes/" .. self.id .. ".box"
	local fullPath = love.filesystem.getSaveDirectory() .. "/" .. relativePath
	return fullPath, relativePath
end

--- Destroys this GGData object.
function GGData:destroy()
	self:clear()
	self = nil
end

return GGData