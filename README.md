# chxdoc

## Introduction

This is a Haxe 3 Port of chxdoc, a command line source code documentation system for the Haxe programming language. 
It is released under a BSD style license.

## Features

* Complete and clean documentation for releases or developer targets
* Comment tags like @param, @return and @throws
* Ability to generate docs for private vars, methods, typedefs, classes and enums
* Templated html file generation

## Installation

`haxelib install chxdoc`

Or using the github version

`haxelib git chxdoc https://github.com/ibilon/chxdoc`

CHXDOC uses a modified version of temploc, the template compiler system by Nicolas Cannasse.

## Usage

You may want to start by running chxdoc with the --help switch, which will give you
the most up to date switches.

To generate documentation for a haxe project, an xml file for the project must be
created. To create one, simply add "-xml myproject.xml" to your haxe command
parameters. This will generate the file that chxdoc requires.

The most common usage of chxdoc would be something like:

```
haxelib run chxdoc -o docs_dev --developer=true -f myproject.xml
haxelib run chxdoc -o docs --templatesDir=/chxdoc/templates --template=default -f myproject.xml
```

Two versions of the documentation would be created, one with all the private data
documented (in docs_dev), and a public release of the documentation in docs.
All the images and css files from the template will be copied to both directories.

If you are documenting the haxe std library, you need to generate xml files using
the "all.hxml" file in the base directory of your installed standard lib. Once
the xml files are generated, you could generate flash9, neko and js targets
using a command similar to

```
haxelib run chxdoc -o docs --tmpDir=_chxdoctmp --templateDir=../chxdoc/templates/default --installTemplate=true --developer=true flash9.xml,flash9,flash neko.xml,neko js.xml,js
```

## Configuration

Configuration of chxdoc is done using xml files. When run for the first time, chxdoc
will create a file _.chxdoc_ in your home directory. This file is always loaded when
chxdoc is run. A custom chxdoc config xml file can be created then specified by the
_--config=mycfg.xml_ command line switch.

Xml config settings are chained, so multiple _--config_ switches can be specified.
The first file loaded is your home .chxdoc file. After that, anything that is
specified on the command line overrides current settings, which allows for
sourcing multiple xml files and overriding any setting by using command line switches.

The order is

* Your home .chxdoc file is loaded and parsed
* Command line arguments from left to right

For example {{{chxdoc -o docs --mergeMeta=true -f flash9.xml --config=project.chxdoc }}}
will load the home .chxdoc file, parse it, then set output to _docs_, then set _mergeMeta_
to true, then load the xml config file _project.chxdoc_. If that last file sets _mergeMeta_
to false, that will override the settings in _project.chxdoc_, the command line _--mergeMeta_,
and the default setting in your home .chxdoc.

## Options

Most xml configuration items can be specified on the command line using the element name and value.
For example {{{<developer value="true">}}} is specified as _--developer=true_ on the command line.
When using switches on the command line, the equals sign is optional, but is shown here for clarity.

--allow={{{[class[,orPkg[,Paths]]]]}}}
	Allow rule for filter chain

--config=xmlfile
	Loads a chxdoc configuration file. This option can be specified multiple times,
	allowing configuration overlays processed in the order on the command line. See
	'createConfig'.

--createConfig (not available in xml files)
	This option writes a default chxdoc config file as chxdocConfig.xml.

--dateLong="%a %b %d %H:%M:%S %Z %Y"
	Format for long dates

--dateShort="%Y-%m-%d"
	Format for short dates

--deny={{{[class[,orPkg[,Paths]]]}}}
	Deny rule for filter chain

--developer=[true|false]
	This tag is a shortcut to setting the following switches:
	--showAuthorTags=bool;
	--showPrivateClasses=bool;
	--showPrivateTypedefs=bool;
	--showPrivateEnums=bool;
	--showPrivateMethods=bool;
	--showPrivateVars=bool;
	--showTodoTags=bool;
	--generateTodoFile=bool;
	Since arguments are parsed in order, you could selectively turn off showAuthorTags
	in a developer build with:
	--developer=true --showAuthorTags=false

-f, --file=name{{{[,platform[,remap]]}}}
	Input xml files. _platform_ and _remap_ are optional. If remap is specified, all package
	references that match _remap_ are translated to _platform_.

--footerText="text"
	Text that will be added to footer of Type pages

--footerTextFile=/path/to/file
	Type pages footer text from file

--generateTodoFile=[true|false]
	Generate the todo html file

--headerText="text"
	Text that will be added to header of Type pages

--headerTextFile=/path/to/file
	Type pages header text from file

--help (not available in xml)
	Command line reference

--htmlFileExtension=html
	Extension for generated html files

--installCssFile=[true|false]
	Install stylesheet from template to output directory

--installImagesDir=[true|false]
	Install images from template to output directory

--installTemplate=[true|false]
	Install stylesheet and images from template to output directory

--macros=file.mtt
	Temploc macro file. (default macros.mtt)

--mergeMeta=[true|false]
	Merge metadata tags to doc tags for similar names. If --showMeta is off, this will
	have no effect

-o, --output=outputdir
	Sets the output directory (defaults to ./docs)

--policy={{{[allow|deny]}}}
	Sets the default policy for the filter chain

--showAuthorTags=[true|false]
	Toggles showing @author contents

--showMeta=[true|false]
	Toggle showing haxe metadata

--showPrivateClasses=[true|false]
	Toggle private classes display

--showPrivateTypedefs=[true|false]
	Toggle private typedef display

--showPrivateEnums=[true|false]
	Toggle private enum display

--showPrivateMethods=[true|false]
	Toggle private method display

--showPrivateVars=[true|false]
	Toggle private var display

--showTodoTags=[true|false]
	Toggle showing @todo tags in type documentation

--stylesheet=file
	Sets the stylesheet relative to the outputdir

--subtitle=string
	Set the package subtitle

--template=name
	Template name relative to --templatesDir (default is 'default')

--templatesDir=path
	Set the base directory for templates. Two special variables are allow in the path.
	%HAXELIB% is replaced with the base path of the haxelib repository. %HAXELIBVER% is
	replaced with the chxdoc version directory (ie "1,2,0"). A complete path to chxdoc
	may look like "%HAXELIB%/chxdoc/%HAXELIBVER%/"

--title=string
	Set the package title

--tmpDir=path
	Path for tempory file generation (default ./__chxdoctmp)

-v,--verbose=[true|false]
	Turns on verbose mode

--webPassword=[pass]
	Sets a web password for ?reload and ?showconfig

--writeWebConfig
	Parses everything, serializes and outputs .chxdoc.hsd

--xmlBasePath=path
	Set a default path to xml files


## Using Tags

Chxdoc adds support for @ tags in your source code comments. To use them, they
must be the first non-whitespace character on a line.

```
/**
 *	This function does very little.
 *	@param a An integer greater than 0
 *	@param s A string
 *	@return True if s is null
 *	@throws haxe.io.Eof When a <= 0
 **/
public function myFunc(a : Int, s : String) : Bool 
{
	if(a <= 0)
		throw new haxe.io.Eof();
	return (s == null);
}
```

The current available tags, all of which except for @deprecated can be used multiple times
```
@author
@deprecated
@param
@private
@requires
@return (or @returns)
@see
@since
@throws
@todo
@type
@version
```

@author text
	Adds an author field

@deprecated Description
	Prints a deprecation warning. This tag is not currently in the
	provided template, but is parsed.

@param name Description
	Adds a notation about a method argument.

@private
	Marks a field as private, even if the access is public. This is often used to
	hide methods that are internal use only, as Haxe has no 'protected' modifier.

@requires Description
	Adds a description for requirements, like a required neko ndll file

@return Description
	Adds literal description to html. @returns is also accepted.

@see Description
	Adds description as a source to view

@since Date/Revision/Version
	A description of when the item was added to the project

@throws full_class_path Description
	Will link html documentation to the class path provided, so it
	must be a fully qualified class path. (haxe.io.Eof)

@todo Description
	For generating TODO files and html notes

@type Description
	For adding descriptions for anonymous types

@version Description
	A version number

## Package and Type filtering

Filtering is done with a series of rules that match either package paths or class paths. Each
filter has a policy, which is either to "allow" or "deny" building of documentation for the path.

In XML, the configuration looks like
```
<filters policy="allow">
  <filter policy="deny" path="haxe.rtti.CType"/>
  <filter policy="allow" path="sys.db.Mysql" />
  <filter policy="deny" path="sys.db.*" />
</filters>
```

Filters start with a default policy, which is seen in the top {{{<filters policy="allow">}}}
element, or specified on the command line by the _--policy=allow_ switch. This is the overall
default policy used when a package does not match any filter, so if the class path
goes through all the {{{<filter>}}} entries without matching, the default policy is applied. When
set to _allow_, by default the documentation will be generated. Conversely if it is set
to _deny_, and does not match any rule, no documentation for it will be created.

To create documentation for only a specific package... say chxdoc itself, it might look like this:

```
<filters policy="deny">
  <filter policy="allow" path="chxdoc.*" />
  <filter policy="allow" path="/" />
</filters>
```

A special path "/" matches any package in the root (like Int or Array), so in addition to allowing
classes in the chxdoc namespace, documentation for any root types used will be created.

The filters are applied in the order they appear in the xml configuration, or on the command line.
When using the --allow or --deny command line switches, the switch can take a list of values
seperated by commas, so the above example could be written on the command line as

```
chxdoc --allow=chxdoc.*,/
```

Beware though, the command line args are still parsed left to right, so the first example would
have to be written as

```
chxdoc --deny=haxe.rtti.CType --allow=sys.db.Mysql --deny=sys.db.*
```

## Planned

embedded tags like {@link } for things like @see {@link haxe.io.Bytes}

----

If you have any questions, visit #haxe on Freenode (Madrok), or
by gmail (damonsbane).

Any suggestions or contributions welcome! A special thanks goes to
Franco Ponticelli for the 'default' template.
