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

Features
-------------------------

* Unlimited storage boxes to allow for easy separation of data.
* Uses both Json and SQLite to obfuscate the data slightly.
* Easy score tracking.
* Simple API.

Update History
-------------------------

##### 0.1
Initial release

##### 0.1.1
Change to a local object as per Walther Luh's advice
Small typo fixes

##### 0.1.2
Renamed project to GGData