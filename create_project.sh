#!/bin/bash

#create the project directory
clear
cat << 'EOF' 
  _____ _____ _____ _____ _____ _____  
=======================================
__  __                                
\ \/ /__ _ _ __ ___   __ _  ___ _ __  
 \  // _` | '_ ` _ \ / _` |/ _ \ '_ \ 
 /  \ (_| | | | | | | (_| |  __/ | | |
/_/\_\__,_|_| |_| |_|\__, |\___|_| |_|
                     |___/            
                                      
       Xamarin binding helper
  _____ _____ _____ _____ _____ _____  
=======================================


This will create the necessary scripts to automate the compilation of a dyilb, xamarin c# binding definitions, and xamarin .net dll

Please ensure you have Xcode, Xamarin.Mac, and ObjectiveSharpie installed.

You should run this script in the same location as your .h / .m source files

EOF

read -r -p "Continue? [y/N] " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo "Good choice.."
else
    return
fi
echo ""
read -r -p "Give your library a name (You can change this at any time by editing the content of lib_name) " lib_name

echo $lib_name > lib_name

cat <<'EOF' > gen.sh
	LIB_NAME=$(cat lib_name)
	echo "Checking for new header files.."
	for f in *.h
	do
		base_name=$(basename $f .h)
		if [ ! -f $base_name.ApiDefinitions.cs ]
			then
				NEW_H_FILES="$NEW_H_FILES $f"
		fi
	done

	if [ "$NEW_H_FILES" ]
		then
			TMP_BND=TmpBindings
			echo "New non-sharpified headers: $NEW_H_FILES"
			echo "Generating C# interface binding files"
			for f in $NEW_H_FILES
			do
				echo "Generating binding for $f"
				base_name=$(basename $f .h)
				rm -rf $TMP_BND/
				sharpie -tlm-do-not-submit bind --namespace=$LIB_NAME -s macosx10.11 $f -o $TMP_BND/ -c -arch x86_64
				echo "Moving $TMP_BND/ApiDefinitions.cs > $base_name.ApiDefinitions.cs"
				cp TmpBindings/ApiDefinitions.cs $base_name.ApiDefinitions.cs
				NEW_CS_FILES="$NEW_CS_FILES\n\t$base_name.ApiDefinitions.cs"
				if [ -f $TMP_BND/StructsAndEnums.cs ]
					then
						echo "Moving $TMP_BND/StructsAndEnums.cs > $base_name.StructsAndEnums.cs"
						cp $TMP_BND/StructsAndEnums.cs $base_name.StructsAndEnums.cs
						NEW_CS_FILES="$NEW_CS_FILES\n$base_name.ApiDefinitions.cs"
				fi
			done
			echo -e "\n\n"
			echo -e "\x1B[5m\x1B[1m\x1B[31mWarning: \x1B[25mNew objc > c# binding files have been generated:"
			echo -e "$NEW_CS_FILES"
			echo -e "\nYou really need to check these for accuracy! \x1B[0m"
			read -r -p ">> Press Enter to acknowledge <<" respose
		else
			echo -e "\nNo new header files were found, nothing to do here.\n"
			echo -e "\x1B[1m\x1B[31mNote:\x1B[0m compile.sh will not overwrite exiting *.ApiDefinitions.cs or *.EnumsAndStructs.cs files.\nPlease delete them manually and re-run compile.sh if you wish to regenerate them"
	fi
EOF

chmod +x gen.sh

cat <<'EOF' > compile.sh
	LIB_NAME=$(cat lib_name)
	echo "Making $LIB_NAME"
	echo -e "Getting .m files:\n"
	for f in *.m
	do
		echo -e "\t$f"
		M_FILES="$M_FILES $f"
	done
	echo -e "Getting c# binding files:\n"
	for f in *.cs
	do
		echo -e "\t$f"
		CS_FILES="$CS_FILES --api=$f"
	done 
	mkdir -p bin tmp

	echo -e "\nWriting makefile.."

	cat <<EOF2 > makefile
XM_PATH = /Library/Frameworks/Xamarin.Mac.framework/Versions/Current
  all:
	mkdir -p bin tmp
	clang -dynamiclib -std=gnu99 $M_FILES -fvisibility=hidden -arch x86_64 -framework Cocoa -o bin/$LIB_NAME.dylib
	MONO_PATH=\$(XM_PATH)/lib/mono/Xamarin.Mac \$(XM_PATH)/bin/bmac-mobile-mono \$(XM_PATH)/lib/bmac/bmac-full.exe -baselib:\$(XM_PATH)/lib/reference/mobile/Xamarin.Mac.dll $CS_FILES --compiler=mcs -o:bin/$LIB_NAME.dll --tmpdir=tmp --ns=Simple

  clean:

	rm -r ./bin
	rm -r ./tmp
EOF2
	echo -e "\nDone.\n"
EOF

chmod +x compile.sh

cat << 'EOF' > fullbuild.sh
	./gen.sh
	./compile.sh
	make clean && make
EOF

chmod +x fullbuild.sh

cat << 'EOF'
=============================================================

Project scripts have been created, follow these instructions:

1. Write your objective-c api (keeping all your .h and .m files in this directory)

2. Run ./gen.sh to create the xamarin binding interface definitions 
   and inspect any newly generated *.ApiDefinitions.cs and *.EnumsAndStructs.cs files for accuracy 
   (codegen.sh will not overwrite existing .cs files)

3. Run ./compile.sh - This will write your makefile for you

4. Run make to build your dylib and corresponding xamarin mac .Dll

5. You can now use your newly created .Dll and dylib 
   (remember you need to distribute the dylib inside the /MonoBundle/ dir of your .app)

6. Make the tea.

PS: If you're really lazy just run fullbuild.sh (but make sure to check any generated bindings!

=============================================================
EOF
