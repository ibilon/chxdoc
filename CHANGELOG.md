# CHXDOC CHANGELOG

## v1.3.0
	* Haxe 3 compatibility

## v1.2.0
	* --templateDir directive is now split into --templatesDir and --template to
		allow for a base path then template name
	* XML configuration added. Will now pull template from haxelib, if it can find it
	* --macroFile changed to --macros
	* All references to meta. in templates replaced with .webmeta to avoid
		confusion with class and member meta for haxe metadata support
	* --file added, no longer will command line blindly accept flash.xml,flash,remap syntax
	* -f which was for 'filter' was redundant syntax for --exclude. Both removed.
	* -f changed to shortcut for --file
	* --includeOnly removed for new filtering
	* New filtering engine created
	* Added --allow and --deny for filtering
	* Changed --generateTodoFile to --generateTodo
	* Added --mergeMeta which takes any haxe metadata tag that has a simalr name, and adds it to the
		the regular tags. Basically this makes @author("Russell Weir") function blah() {} the same
		as the "/** @author Russell Weir */" style.
	* --ignoreRoot removed. Use the --deny=/ syntax.
	* Added %HAXELIB% and %HAXELIBVER% to template and templatesDir paths

## v1.1.4
	* Haxe 2.10 compatibility
	* temploc embedded

## v1.1.2
	* @private tags supported and fix to inherited vars

## v1.0.2
	* Fixed Run.hx overwriting Settings.hx 

## v1.0.1
	* Fixed remapping

## v1.0.0
	* Updated installer
	* fixed class types not shown on default template
	* installs custom chxtemploc compiler
	* fix template installed when bad cmd args passed
	* change default temp directory to "__chxdoctmp"
	* change default output directory to "docs"
	* change command line --templateDir to just --template (--templateDir deprecated, still works)

## v0.9.2
	* Updated for current haxe compiler

## v0.9.1
	* Fixed methods showing as vars bug
	* Completed method inheritance

## v0.9
	* Updated for newer haxe compiler
	* --installTemplate now defaults to true

## v0.8
	* ADDED @since and @version
	* FIXED Path bug in Utils.hx
	* ADDED --includeOnly param, which takes packages as package.* or full
		paths to classes (mypackage.MyClass). Once activated, all other
		packages/classes are ignored
	* ADDED --ignoreRoot to supress generation of [root types] html

## v0.7.3
	* FIXED: Populating ClassCtx.superClasses
	* CHANGE: Added show/hide inherited to member vars and member methods
	* FIXED: --writeWebConfig requiring template macro file to exist
	
## v0.7.2
	* FIXED : Tag detection EReg in DocProcessor
	
## v0.7.1
	* CHANGE: Copying required files to src/chx for

## v0.7 2009-01-19
	* ADDED MOD_NEKO support.
	* CHANGE Now requires caffeine-hx /ext2 in classpath
	* ADDED --xmlBasePath and --writeWebConfig
	* ADDED (476): -v verbose flag for output
	* CHANGE (476): 'platform' global now called config in .mtt
	* FIXED (476): package and type filtering
	* FIXED (474): Extensive work on sorting and displaying Typedefs
	* FIXED (474): Improper handling of --footerText embedded =

## v0.6 2009-01-14
	* FIXED: Constructors not getting docs.
	* FIXED: Template for typedefs showing wrong platforms
	* FIXED: Templates not showing platforms for members
	* ADDED: --footerText and --footerTextFile switches for adding raw html to Types pages
	* ADDED: --generateTodo flag for making /todo.html
	* ADDED: @author [raw]
	* ADDED: @requires tag for Type or Function requirements (ie. specific neko ndll, etc)
	* ADDED: @see [path]
	* ADDED: @todo tag and todo.html file generation
	* ADDED: @type [name] [description] for type params (ie function blah<T>)

	* CHANGE: Moved Root Types to top of packages in all_packages.mtt
	* CHANGE: Improved tag detection in method/var/class documentation
	* The current available tags are:
		@author
		@deprecated
		@param
		@requires
		@return (or @returns)
		@see
		@throws
		@todo
		@type


## v0.5 2009-01-12
	* Added --installTemplate switch to copy all images and stylesheet from template dir
	* Added --developer switch to toggle all --showPrivate* flags
	* Added platform.developer Bool which is true if any showPrivate* flag is set
	* Added platforms list to platform
	* Fixed private type generation
