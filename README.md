# xamgen
Xamarin.Mac objective-c library binding scripts to make it (slightly) less painful to create c# bindings to your own objective-c libraries

Note: this assumes you already have [Xamarin.Mac] (https://developer.xamarin.com/guides/mac/) and [ObjectiveSharpie] (https://developer.xamarin.com/guides/ios/advanced_topics/binding_objective-c/objective_sharpie/) installed on your system

## Usage

**1. Clone this repo somewhere**

```
git clone git@github.com:l0hn/xamgen.git ~/repos/xamgen
```

**2. Change directory to the location of the objective-c source files for your library e.g:**

```
cd ~/Documents/xcode-projects/mylib/mylib
```

**3. Run the create_project.sh script and follow the on-screen instructions to initialize the helper scripts**

```
~/repos/xamgen/create_project.sh
```

**4. Once completed the following scripts will have been generated:**

* ./gen.sh        - Run this script to generate xamarin binding definitions for all of your .h files
* ./compile.sh    - Run this script to generate a makefile. 
                    After creating the makefile run 'make' to compile you're dylib and dll.
                    make will output the dylib and dll into the ./bin/ folder.
* ./fullbuild.sh  - This is just a shortcut script that will run the above scripts in order followed by make

Depending on the complexity of your library you will most likely need to adjust the generated xamarin definition files. Once you have adjusted the definitions you can re-run ./fullbuild.sh to rebuild the dylib + dll**
Any of the generated scripts can be rerun at any time.
