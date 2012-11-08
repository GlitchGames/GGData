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

Update History
-------------------------

##### 0.1
Initial release

##### 0.1.1
Change to a local object as per Walther Luh's advice

Small typo fixes

##### 0.1.2
Renamed project to GGData