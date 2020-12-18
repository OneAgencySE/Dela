# Environment

After using the setup.sh script you'll have a config file: `/Dela_App/Shared/local.xcconfig` This script will be ignored, and you'll need to update the address

The values can't use '//' don't forget to escape

Each key needs to be added to each project where it's needed. Eg: 
`/Dela_App/iOS/Info.plist` like this:
```xml 
<key><NameFromConfigFile>)</key>
<string>$(<NameFromConfigFile>)</string>
```

Feel free the automate this to be run during build.