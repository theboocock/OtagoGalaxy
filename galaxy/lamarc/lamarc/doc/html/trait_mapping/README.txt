Copying 'lam_conv' (or lam_conv.exe, depending on your system) into this 
directory, and running:

    ./lam_conv -b -c traitCmd.xml

should produce the file 'lamarc-trait-input.xml'.  You can also omit the
'-b' option to pull the data into the converter, and further manipulate it
with the GUI.

You can then copy 'lamarc' (or lamarc.exe) into this directory and run it on
the lamarc-trait-input.xml file.  The result should be similar to the file
'outfile.txt' (though not identical, due to lamarc's use of a random number
seed).
