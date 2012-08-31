-- Project: GGStorageBox
--
-- Date: August 31, 2012
--
-- Version: 0.1.1
--
-- File name: GGStorageBox.lua
--
-- Author: Graham Ranson of Glitch Games - www.glitchgames.co.uk
--
-- Update History:
--
-- 0.1 - Initial release
--
-- 0.1.1 
-- 		Change to a local object as per Walther Luh's advice
-- 		Small typo fixes
--
-- Comments: 
--
--		Many people have used Ice however as of late it seems to be experiencing weird 
--		issues. GGStorageBox is a trimmed down version to allow for better stability.
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

local GGStorageBox = {}
local GGStorageBox_mt = { __index = GGStorageBox }

local json = require( "json" )
local lfs = require( "lfs" )
local sqlite3 = require( "sqlite3" )

--- Initiates a new GGStorageBox object.
-- @param id The name of the GGStorageBox to create or load ( if it already exists ).
-- @param path The path to the GGStorageBox. Optional, defaults to "boxes".
-- @param baseDir The base directory for the GGStorageBox. Optional, defaults to system.DocumentsDirectory.
-- @return The new object.
function GGStorageBox:new( id, path, baseDir )
    
    local self = {}
    
    setmetatable( self, GGStorageBox_mt )
    
    self.id = id
    self.path = path
    self.baseDir = baseDir
    
    if self.id then
    	self:load()
    end
    		
    return self
    
end

--- Opens an SQLite database from disk. Called internally.
-- @param path The path to the database.
function GGStorageBox:_openDatabase( path )

	if path then
		return sqlite3.open( path )
	end
	
end

--- Saves data to an SQLite database. Called internally.
-- @param database The SQLite database object.
-- @param data A table containing the data to save.
function GGStorageBox:_saveDatabase( database, data )

	if database then

		local query = [[CREATE TABLE IF NOT EXISTS box (id INTEGER PRIMARY KEY, value );]]
	
		database:exec( query )
		
		local query = [[INSERT INTO box VALUES (NULL, ']] .. ( data or {} ) .. [['); ]]

		database:exec( query )
		
		database:close()
		
	end
	
end

--- Loads data from an SQLite database. Called internally.
-- @param database The SQLite database object.
-- @return A table containing the data. Empty if no data found.
function GGStorageBox:_loadDatabase( database )

	local result = database:exec("SELECT * FROM box")
	local items = {}
	
	if database then
		if result == 0 then
			for row in database:nrows("SELECT * FROM box") do
				local encodedItems = row.value
				items = json.decode( encodedItems )				
			end
		end
	end

	return items
	
end

--- Loads, or reloads, this GGStorageBox object from disk.
-- @param id The id of the GGStorageBox object.
-- @param path The path to the GGStorageBox. Optional, defaults to "boxes".
-- @param path The base directory for the GGStorageBox. Optional, defaults to system.DocumentsDirectory.
function GGStorageBox:load( id, path, baseDir )
	
	-- Set up the path
	path = path or "boxes/"
	
	-- Pre-declare the new GGStorageBox object
	local box
	
	-- If no id was passed in then assume we're working with a pre-loaded GGStorageBox object so use its id
	if not id then
		id = self.id
		box = self
	end
	
	local data = {}
	
	if sqlite3 then
	
		local database = self:_openDatabase( path .. "/" .. id .. ".box" )
	
		if database then
			data = self:_loadDatabase( database, data )
		end
		
	else
	
		local path = system.pathForFile( path .. id .. ".box", baseDir or system.DocumentsDirectory )
		local file = io.open( path, "r" )
		
		if not file then
			return
		end
		
		data = json.decode( file:read( "*a" ) )
		io.close( file )
		
	end
	
	-- If no GGStorageBox exists then we are acting on a Class function i.e. not a pre-loaded GGStorageBox object.
	if not box then
		-- Create the new GGStorageBox object.
		box = GGStorageBox:new()
	end
	
	-- Copy all the properties across.
	for k, v in pairs( data ) do
		box[ k ] = v
	end
	
	return box
	
end

--- Saves this GGStorageBox object to disk.
function GGStorageBox:save()

	local data = {}
	
	-- Copy across all the properties that can be saved.
	for k, v in pairs( self ) do
		if type( v ) ~= "function" then
			data[ k ] = v
		end
	end
	
	-- Check for and create if necessary the boxes directory.
	local path = system.pathForFile( "", system.DocumentsDirectory )
	local success = lfs.chdir( path )
	
	if success then
		lfs.mkdir( "boxes" )
		path = "boxes"
	else
		path = ""
	end
	
	data = json.encode( data )
	
	if sqlite3 then
	
		local database = self:_openDatabase( path .. "/" .. self.id .. ".box" )
	
		if database then
			self:_saveDatabase( database, data )
		end
		
	else
	
		path = system.pathForFile( "boxes/" .. self.id .. ".box", system.DocumentsDirectory )
		local file = io.open( path, "w" )
		
		if not file then
			return
		end
		
		file:write( data )
		io.close( file )
		file = nil
		
	end
	
end

--- Sets a value in this GGStorageBox object.
-- @param name The name of the value to set.
-- @param value The value to set.
function GGStorageBox:set( name, value )
	self[ name ] = value
end

--- Gets a value from this GGStorageBox object.
-- @param name The name of the value to get.
-- @return The value.
function GGStorageBox:get( name )
	return self[ name ]
end

--- Sets a value on this GGStorageBox object if it is new.
-- @param name The name of the value to set.
-- @param value The value to set.
function GGStorageBox:setIfNew( name, value )
	if self[ name ] == nil then
		self[ name ] = value
	end
end

--- Sets a value on this GGStorageBox object if it is higher than the current value.
-- @param name The name of the value to set.
-- @param value The value to set.
function GGStorageBox:setIfHigher( name, value )
	if self[ name ] and value > self[ name ] then
		self[ name ] = value
	end
end

--- Sets a value on this GGStorageBox object if it is lower than the current value.
-- @param name The name of the value to set.
-- @param value The value to set.
function GGStorageBox:setIfLower( name, value )
	if self[ name ] and value < self[ name ] then
		self[ name ] = value
	end
end

--- Increments a value in this GGStorageBox object.
-- @param name The name of the value to increment. Must be a number.
-- @param amount The amount to increment. Optional, defaults to 1.
function GGStorageBox:increment( name, amount )
	if self[ name ] and type( self[ name ] ) == "number" then
		self[ name ] = self[ name ] + ( amount or 1 )
	end
end

--- Decrements a value in this GGStorageBox object.
-- @param name The name of the value to decrement. Must be a number.
-- @param amount The amount to decrement. Optional, defaults to 1.
function GGStorageBox:decrement( name, amount )
	if self[ name ] and type( self[ name ] ) == "number" then
		self[ name ] = self[ name ] - ( amount or 1 )
	end
end

--- Clears this GGStorageBox object.
function GGStorageBox:clear()
	for k, v in pairs( self ) do
		if k ~= "id" then
			self[ k ] = nil
		end
	end
end

--- Deletes this GGStorageBox object from disk. 
-- @param id The id of the GGStorageBox to delete. Optional, only required if calling on a non-loaded object.
function GGStorageBox:delete( id )
	
	-- If no id was passed in then assume we're working with a pre-loaded GGStorageBox object so use its id
	if not id then
		id = self.id
	end
	
	local path = system.pathForFile( "boxes", system.DocumentsDirectory )

	local success = lfs.chdir( path )
	
	os.remove( path .. "/" .. id .. ".box" )
	
	if not success then
		return
	end
	
end

--- Destroys this GGStorageBox object.
function GGStorageBox:destroy()
	self:clear()
	self = nil
end

return GGStorageBox