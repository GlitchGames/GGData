GGData
============

GGData is a simple persistent data storage class for the Corona SDK.

Basic Usage
-------------------------

##### Require The Code
```lua
local GGData = require( "GGData" )
```
##### Create or load a box
```lua
local box = GGData:new( "sample" )
```

##### Set some values
```lua
box:set( "message", "hello, world" )
box.anotherValue = 10
```

##### Get some values
```lua
print( box:get( "anotherValue" ) ) -- prints 10
print( box.message ) -- prints 'hello, world'
```

##### Save the box
```lua
box:save()
```

##### Enable or disable iCloud backup
```lua
box:setSync( true )
box:setSync( false )
```

##### Check if iCloud is enabled or disabled
```lua
print( box:getSync() )
```

##### Enable integrity checking. This should be set BEFORE adding values and needs to be set on each run as the key is not stored ( as it would defeat the point ). 
```lua
local crypto = require( "crypto" )
box:enableIntegrityControl( crypto.sha512, "SECRET_KEY" )
```

##### If you decide to enable integrity checking after you have already set a bunch of values you will want to update all the hashes.
```lua
box1:enableIntegrityControl( crypto.sha512, "MONKEY" )
box1:updateAllIntegrityHashes()
```

##### When adding or editing values via any of the helper methods integrity data will be stored automatically but if you store the data manually you will also need to add this extra data.
```lua
box.newValue = "Hello, World!"
box:storeIntegrityHash( "newValue" )
```

##### Verify the integrity of all items. Any values that are detected as wrong will be nilled out. Remember to save after doing this :-)
```lua
local corruptEntries = box1:verifyIntegrity()
print( corruptEntries ) -- How many, if any, values were removed due to being different than expected.
```

Update History
-------------------------

##### 0.1
Initial release

##### 0.1.1
Change to a local object as per Walther Luh's advice

Small typo fixes

##### 0.1.2
Renamed project to GGData