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
local lfs = require( "lfs" )
local crypto = require( "crypto" )

-------- Functions used for converting tables to strings which is used for data integrity. Functions sourced from here - http://lua-users.org/wiki/TableUtils
function table.val_to_str ( v )
	if "string" == type( v ) then
		v = string.gsub( v, "\n", "\\n" )
		if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
			return "'" .. v .. "'"
		end
		return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
	else
		return "table" == type( v ) and table.tostring( v ) or tostring( v )
	end
end

function table.key_to_str ( k )
	if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
		return k
	else
		return "[" .. table.val_to_str( k ) .. "]"
	end
end

function table.tostring( tbl )
	local result, done = {}, {}
	for k, v in ipairs( tbl ) do
		table.insert( result, table.val_to_str( v ) )
		done[ k ] = true
	end
	for k, v in pairs( tbl ) do
		if not done[ k ] then
	  		table.insert( result,
			table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
		end
	end
	return "{" .. table.concat( result, "," ) .. "}"
end

local toString = function( value )
	if type( value ) == "table" then
		return table.tostring( value )
	else
		return tostring( value )
	end
end
-----------------------------------------------

--- Initiates a new GGData object.
-- @param id The name of the GGData to create or load ( if it already exists ).
-- @param path The path to the GGData. Optional, defaults to "boxes".
-- @param baseDir The base directory for the GGData. Optional, defaults to system.DocumentsDirectory.
-- @return The new object.
function GGData:new( id, path, baseDir )

    local self = {}

    setmetatable( self, GGData_mt )

    self.id = id
    self.path = path or "boxes"
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
	path = path or "boxes"

	-- Pre-declare the new GGData object
	local box

	-- If no id was passed in then assume we're working with a pre-loaded GGData object so use its id
	if not id then
		id = self.id
		box = self
	end

	local data = {}

	local path = system.pathForFile( path .. "/" .. id .. ".box", baseDir or system.DocumentsDirectory )

	local file = io.open( path, "r" )

	if not file then
		return
	end

	data = json.decode( file:read( "*a" ) )
	io.close( file )

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

	-- Don't want this key getting saved out
	local integrityKey = self.integrityKey
	self.integrityKey = nil

	local data = {}

	-- Copy across all the properties that can be saved.
	for k, v in pairs( self ) do
		if type( v ) ~= "function" and type( v ) ~= "userdata" then
			data[ k ] = v
		end
	end

	-- Check for and create if necessary the boxes directory.
	local path = system.pathForFile( "", system.DocumentsDirectory )
	local success = lfs.chdir( path )

	if success then
		lfs.mkdir( self.path )
		path = self.path
	else
		path = ""
	end

	data = json.encode( data )

	path = system.pathForFile( self.path .. "/" .. self.id .. ".box", system.DocumentsDirectory )
	local file = io.open( path, "w" )

	if not file then
		return
	end

	file:write( data )

	io.close( file )
	file = nil

	-- Set the key back again
	self.integrityKey = integrityKey

end

--- Sets a value in this GGData object.
-- @param name The name of the value to set.
-- @param value The value to set.
function GGData:set( name, value )
	self[ name ] = value
	self:storeIntegrityHash( name, value )
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
		self:storeIntegrityHash( name, value )
	end
end

--- Sets a value on this GGData object if it is higher than the current value.
-- @param name The name of the value to set.
-- @param value The value to set.
function GGData:setIfHigher( name, value )
	if self[ name ] and value > self[ name ] or not self[ name ] then
		self[ name ] = value
		self:storeIntegrityHash( name, value )
	end
end

--- Sets a value on this GGData object if it is lower than the current value.
-- @param name The name of the value to set.
-- @param value The value to set.
function GGData:setIfLower( name, value )
	if self[ name ] and value < self[ name ] or not self[ name ] then
		self[ name ] = value
		self:storeIntegrityHash( name, value )
	end
end

--- Increments a value in this GGData object.
-- @param name The name of the value to increment. Must be a number. If it doesn't exist it will be set to 0 and then incremented.
-- @param amount The amount to increment. Optional, defaults to 1.
function GGData:increment( name, amount )
	if not self[ name ] then
		self:set( name, 0 )
	end
	if self[ name ] and type( self[ name ] ) == "number" then
		self[ name ] = self[ name ] + ( amount or 1 )
		self:storeIntegrityHash( name, value )
	end
end

--- Decrements a value in this GGData object.
-- @param name The name of the value to decrement. Must be a number. If it doesn't exist it will be set to 0 and then decremented.
-- @param amount The amount to decrement. Optional, defaults to 1.
function GGData:decrement( name, amount )
	if not self[ name ] then
		self:set( name, 0 )
	end
	if self[ name ] and type( self[ name ] ) == "number" then
		self[ name ] = self[ name ] - ( amount or 1 )
		self:storeIntegrityHash( name, value )
	end
end

--- Clears this GGData object.
function GGData:clear()
	for k, v in pairs( self ) do
		if k ~= "integrityControlEnabled"
			and k ~= "integrityAlgorithm"
			and k ~= "integrityKey"
			and k ~= "id"
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

	local path = system.pathForFile( self.path, system.DocumentsDirectory )

	local success = lfs.chdir( path )

	os.remove( path .. "/" .. id .. ".box" )

	if not success then
		return
	end

end

--- Enables or disables the Syncing of this box.
-- @param enabled True if Sync should be enabled, false otherwise.
function GGData:setSync( enabled, id )

	-- If no id was passed in then assume we're working with a pre-loaded GGData object so use its id
	if not id then
		id = self.id
	end

	native.setSync( self.path .. "/" .. id .. ".box", { iCloudBackup = enabled } )

end

--- Checks if Syncing for this box is enabled or not.
-- @param enabled True if Sync is enabled, false otherwise.
function GGData:getSync( id )

	-- If no id was passed in then assume we're working with a pre-loaded GGData object so use its id
	if not id then
		id = self.id
	end

	return native.getSync( self.path .. "/" .. id .. ".box", { key = "iCloudBackup" } )

end

--- Enables integrity checking.
-- @param algorithm The hashing algorithm to use, see this page for possibles - http://docs.coronalabs.com/api/library/crypto/index.html
-- @param key The seed to use for the hashing algorithm.
function GGData:enableIntegrityControl( algorithm, key )
	self.integrityAlgorithm = algorithm
	self.integrityKey = key
	self.hash = self.hash or {}
	self.integrityControlEnabled = true
end

--- Disables integrity checking.
function GGData:disableIntegrityControl()
	self.integrityAlgorithm = nil
	self.integrityKey = nil
	self.hash = nil
	self.integrityControlEnabled = false
end

--- Verifies that the passed in value matches the stored hash.
-- @param name The name of the value to check.
-- @param value The value to check.
-- @return True if the value matches the hash false otherwise.
function GGData:verifyItemIntegrity( name, value )
	-- just hash the tostring() version and compare against that!
	if toString( value ) then
		local generatedHash = crypto.hmac( self.integrityAlgorithm, toString( value ), self.integrityKey, false )
		local storedHash = self.hash[ name ]
		return generatedHash == storedHash
	end
end

--- Stores the hash value of the given value to be used for integrity checks.
-- @param name The name of the value to set.
-- @param value The value to set. Optional, if not included will just pull the value from the name supplied.
function GGData:storeIntegrityHash( name, value )

	if not self.integrityControlEnabled then
		return
	end

	value = value or self[ name ]

	self.hash = self.hash or {}

	if value then
		self.hash[ name ] = crypto.hmac( self.integrityAlgorithm, toString( value ), self.integrityKey, false )
	end

end

--- Updates/sets the hash value of the all stored values.
function GGData:updateAllIntegrityHashes()

	for k, v in pairs( self ) do
		if k ~= "integrityControlEnabled"
			and k ~= "integrityAlgorithm"
			and k ~= "integrityKey"
			and k ~= "hash"
			and k ~= "id"
			and  toString( v ) then
				self:storeIntegrityHash( k, v )
		end
	end

end

--- Checks the hashed versions of all stored data. Will remove any values that don't match their hashes, i.e. they've been tampered with.
function GGData:verifyIntegrity()

	if not self.integrityControlEnabled then
		return
	end

	local corruptEntries = {}

	for k, v in pairs( self ) do
		if k ~= "integrityControlEnabled"
			and k ~= "integrityAlgorithm"
			and k ~= "integrityKey"
			and k ~= "hash"
			and k ~= "id"
			and toString( v ) then

				if not self:verifyItemIntegrity( k, v ) then
					corruptEntries[ #corruptEntries + 1 ] = { name = k, value = v }
					self[ k ] = nil
					self.hash[ k ] = nil
				end
		end
	end

	for k, v in pairs( self.hash ) do
		if not self[ k ] then
			corruptEntries[ #corruptEntries + 1 ] = { name = k, value = v }
			self[ k ] = nil
			self.hash[ k ] = nil
		end
	end

	return corruptEntries

end

--- Gets the path to the stored file. Useful if you want to upload it.
-- @return Two paramaters; the full path and then the relative path.
function GGData:getFilename()
	local relativePath = self.path .. "/" .. self.id .. ".box"
	local fullPath = system.pathForFile( relativePath, system.DocumentsDirectory )
	return fullPath, relativePath
end

--- Destroys this GGData object.
function GGData:destroy()
	self:clear()
	self = nil
end

return GGData
