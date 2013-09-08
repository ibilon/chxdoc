/*
 * Copyright (c) 2008-2012, The Caffeine-hx project contributors
 * Original author : Russell Weir
 * Contributors: Niel Drummond
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE CAFFEINE-HX PROJECT CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE CAFFEINE-HX PROJECT CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

package chxdoc;

import chxdoc.Defines;
import chxdoc.Types;
import chxdoc.FilterPolicy;
import haxe.rtti.CType;
import sys.FileSystem;
import sys.io.File;
#if neko
import neko.Web;
#end

class ChxDocMain {
	static var proginfo : String;

	public static var buildData : BuildData;

	public static var config : Config =
	{
		versionMajor		: 1,
		versionMinor		: 3,
		versionRevision		: 0,
		buildNumber			: 752,
		verbose				: false,
		rootTypesPackage	: null,
		allPackages			: new Array(),
		allTypes			: new Array(),
		docBuildDate		: Date.now(),
		dateShort			: DateTools.format(Date.now(), "%Y-%m-%d"),
		dateLong			: DateTools.format(Date.now(), "%a %b %d %H:%M:%S %Z %Y"),
		mergeMeta			: true,
		showAuthorTags		: false,
		showMeta			: false,
		showPrivateClasses	: false,
		showPrivateTypedefs	: false,
		showPrivateEnums	: false,
		showPrivateMethods	: false,
		showPrivateVars		: false,
		showTodoTags		: false,
		template			: "default",
		templatesDir		: "",
		tmpDir				: "./__chxdoctmp/",
		macros				: "macros.mtt",
		htmlFileExtension	: ".html",

		stylesheet			: "stylesheet.css",

		output				: "./docs/",
		packageDirectory	: "./docs/packages/",
		typeDirectory		: "./docs/types/",

		noPrompt			: false, // not implemented
		installImagesDir	: true,
		installCssFile		: true,

		title 				: "Haxe Application",
		subtitle			: "http://www.haxe.org/",
		developer			: false,
		platforms			: new List(),
		footerText			: null,
		headerText			: null,
		generateTodo		: false,
		todoLines			: new Array(),
		todoFile			: "todo.html",

		xmlBasePath			: "",
		files				: new Array(),
		webPassword			: null,
		ignoreRoot			: false,
	};

	static var parser = new haxe.rtti.XmlParser();

	/** the one instance of PackageHandler that crawls the TypeTree **/
	static var packageHandler	: PackageHandler;

	/**
		all package contexts below the root,
		before being transformed into config in stage3
	**/
	static var packageContexts : Array<PackageContext>;


	// These are only used during pass1, and are invalid after
	/** Current package being processed, dotted form **/
	public static var currentPackageDots : String;
	/** Path to ascend to base index directory **/
	public static var baseRelPath		: String;


	public static var println 			: Dynamic->Void;
	public static var print				: Dynamic->Void;

	static var webConfigFile			: String	= ".chxdoc.hsd";
	public static var writeWebConfig	: Bool		= false;
	static var createConfig				: Bool		= false;

	//////////////////////////////////////////////
	//               Pass 1                     //
	//////////////////////////////////////////////
	static function pass1(list: Array<TypeTree>) {
		for( entry in list ) {
			switch(entry) {
			case TPackage(name, full, subs):
				var ocpd = currentPackageDots;
				var obrp = baseRelPath;
				//path += name + "/";
				if(name != "root") {
					currentPackageDots = full;
					baseRelPath = "../" + baseRelPath;
				} else {
					currentPackageDots = "";
					baseRelPath = "";
				}
				var ctx = packageHandler.pass1(name, full, subs);
				if(name == "root")
					config.rootTypesPackage = ctx;
				else
					packageContexts.push(ctx);

				pass1(subs);

				baseRelPath = obrp;
				currentPackageDots = ocpd;
			// the rest are handled by packageHandler
			default:
			}
		}
	}

	//////////////////////////////////////////////
	//               Pass 2                     //
	//////////////////////////////////////////////
	/**
		<pre>
		Types -> create documentation
		Package -> Make directories
		</pre>
	**/
	static function pass2() {
		packageContexts.sort(PackageHandler.sorter);
		packageHandler.pass2(config.rootTypesPackage);
		for(i in packageContexts)
			packageHandler.pass2(i);
		// these were added in reverse order since DocProcessor does it that way
		config.todoLines.reverse();
	}


	//////////////////////////////////////////////
	//               Pass 3                     //
	//////////////////////////////////////////////
	/**
		<pre>
		Types	-> Resolve all super classes, inheritance, subclasses
		Package -> Prune filtered types
				-> Sort classes
				-> Add all types to main types
		</pre>
	**/
	static function pass3() {
		if( !config.ignoreRoot )
			packageHandler.pass3(config.rootTypesPackage);

		for(i in packageContexts)
			packageHandler.pass3(i);

		config.allTypes.sort(function(a,b) {
			return Utils.stringSorter(a.path, b.path);
		});
		config.allPackages.sort(function(a,b) {
			return Utils.stringSorter(a.full, b.full);
		});

		packageContexts = null;
	}

	public static function registerType(ctx : Ctx) : Void
	{
		config.allTypes.push(ctx);
	}

	public static function registerPackage(pkg : PackageContext) : Void
	{
		if(pkg.full == "root types") {
			config.rootTypesPackage = pkg;
			return;
		}
		else {
			config.allPackages.push(pkg);
		}
	}

	public static function registerTodo(pkg:PackageContext, ctx:Ctx, msg: String) {
		if(!config.generateTodo)
			return;
		var parentCtx = CtxApi.getParent(ctx, true);
		var childCtx = ctx;

		if(parentCtx == null) {
			parentCtx = ctx;
			childCtx = null;
		}

		var dots = parentCtx.packageDots;
		if(dots == null)
			dots = pkg.full;

		var href = "types/" +
				Utils.addSubdirTrailingSlash(dots.split(".").join("/")) +
				parentCtx.name +
				config.htmlFileExtension +
				CtxApi.makeAnchor(childCtx);

		var linkText = parentCtx.nameDots;

		config.todoLines.push({
			link: Utils.makeLink(
					href,
					linkText,
					"todoLine"
				),
			message: msg,
		});
	}

	//////////////////////////////////////////////
	//               Pass 4                     //
	//////////////////////////////////////////////
	/**
		Write everything
	**/
	static function pass4() {
		if( !config.ignoreRoot )
			packageHandler.pass4(config.rootTypesPackage);
		for(i in config.allPackages)
			packageHandler.pass4(i);


		var a = ["index", "overview", "all_packages", "all_classes"];
		if(config.generateTodo)
			a.push("todo");

		for(i in a) {
			if( config.ignoreRoot ) config.rootTypesPackage = null;
			Utils.writeFileContents(
				config.output + i + config.htmlFileExtension,
				execBaseTemplate(i)
			);
		}
	}

	static function execBaseTemplate(s : String, ?cfg:Dynamic) : String {
		if(!isBaseTemplate(s))
			fatal(s + " is not a valid file");
		var c : Dynamic = config;
		if(cfg != null)
			c = cfg;
		var t = new mtwin.templo.Loader(s+".mtt");
		var webMetaData = {
			date : config.dateShort,
			keywords : new Array<String>(),
			stylesheet : config.stylesheet,
		};
		webMetaData.keywords.push("");
		var context : IndexContext = {
			webmeta		: webMetaData,
			build 		: buildData,
			config		: c,
		};
		return t.execute(context);
	}

	/**
		Returns true if the provided name is a valid base directory
		templated
		@param s Base file name without any extension (ie. 'index' not 'index.mtt' or 'index.html')
		@return true if s is a valid name.
	**/
	static function isBaseTemplate(s : String) : Bool {
		switch(s) {
		case "index":
		case "overview":
		case "all_packages":
		case "all_classes":
		case "todo":
		case "config":
		default:
			return false;
		}
		return true;
	}


	//////////////////////////////////////////////
	//               Utilities                  //
	//////////////////////////////////////////////
	/**
		Locate a type context from it's full path in all
		packages. Can not be used until after pass 1.
		@throws String when type not found
	**/
	public static function findType( path : String ) : Ctx {
		var parts = path.split(".");
		var name = parts.pop();
		var pkgPath = parts.join(".");

		var pkg : PackageContext = findPackage(pkgPath);
		if(pkg == null)
			throw "Unable to locate package " + pkgPath + " for "+ path;

		for(ctx in pkg.types) {
			if(ctx.path == path)
				return ctx;
		}
		throw "Could not find type " + path;
	}

	/**
		Find a package by it's full path. Do not include a Type name.
		@param path Package path
		@returns null or PackageContext
	**/
	public static function findPackage(path : String) : PackageContext {
		if(path == "" || path == "root types")
			return config.rootTypesPackage;
		var p = config.allPackages;
		// before stage3, we have to look in unfiltered packages
		if(packageContexts != null && packageContexts.length > 0)
			p = packageContexts;
		if(p == null)
			return null;
		for(i in p) {
			if(i.full == path)
				return i;
		}
		return null;
	}


	//////////////////////////////////////////////
	//              Main                        //
	//////////////////////////////////////////////
	public static function main() {
		chx.Log.redirectTraces(true);

		#if neko
		if( Web.isModNeko )
			setNullPrinter();
		else
		#end
			setDefaultPrinter();

		proginfo = "ChxDoc Generator "+
			makeVersion() +
			" - (c) 2008-2012 Russell Weir";

		buildData = {
			date: config.dateShort,
			number: Std.string(config.buildNumber),
			comment: "<!-- Generated by chxdoc (build "+config.buildNumber+") on "+config.dateShort+" -->",
		};

		print(proginfo + "\n");
		initDefaultPaths();

		Setup.setup();
		parseArgs();

		initTemplo();

		#if neko
		if( Web.isModNeko ) {
			checkAllPaths();
			Web.cacheModule(webHandler);
			webHandler();
		}
		else {
		#end
			loadXmlFiles();
			checkAllPaths();
			generate();
			installTemplate();
		#if neko
		}
		#end
	}

	#if neko
	static function webHandler() : Void {
		if(config == null)
			fatal("Config is not set");

		var modPath = function(s) {
			if(s == null)
				s = "";
			if(s.charAt(0) != "/")
				return Web.getCwd() + s;
			return s;
		}
		var updatePaths = function() {
			config.template = modPath(config.template);
			config.tmpDir = modPath(config.tmpDir);
			initTemplo();
		}
		var updateXmlPaths = function() {
			config.xmlBasePath = null;
			for(i in config.files)
				i.name = modPath(i.name);
		}

		var params = Web.getParams();
		if( params.get("showconfig") != null) {
			setDefaultPrinter();
			if(config.webPassword != params.get("password")) {
				logError("Not authorized");
				return;
			}
			var cfg = makeViewableConfig();
			updatePaths();
			print(execBaseTemplate("config", cfg));
			return;
		}

		updatePaths();
		if( params.get("reload") != null ) {
			if(config.webPassword != params.get("password")) {
				logError("Not authorized");
				return;
			}
			updateXmlPaths();
			loadXmlFiles();
			writeWebConfig = true;
			generate();
		}
		setDefaultPrinter();

		var base = params.get("base");
		if(base == null || base == "")
			base = "index";
		// index, overview etc.
		if(isBaseTemplate(base)) {
			print(execBaseTemplate(base));
		}
		else {
			if(base == "types") {
				var path = params.get("path").split("/").join(".");
				try {
					var ctx : Ctx = findType(path);
					print(TypeHandler.execTemplate(ctx));
				} catch(e:String) {
					print("Unable to find type " + path);
				}
			}
			else if(base == "packages") {
				var parts = params.get("path").split("/");
				if(parts[parts.length-1] == "package")
					parts.pop();
				var path = parts.join(".");
				var pkg = findPackage(path);
				if(pkg != null)
					print(PackageHandler.execTemplate(pkg));
				else
					print("Could not find package " + path);
			}
			else
				print("File not found : " + base);
		}
	}
	#end

	static function generate() {
		packageHandler = new PackageHandler();
		packageContexts = new Array<PackageContext>();

		// These need to be reset for web regeneration
		config.rootTypesPackage = null;
		config.allPackages = new Array();
		config.allTypes = new Array();
		config.docBuildDate = Date.now();
		config.dateShort = DateTools.format(Date.now(), "%Y-%m-%d");
		config.dateLong = DateTools.format(Date.now(), "%a %b %d %H:%M:%S %Z %Y");
		config.todoLines = new Array();

		baseRelPath = "";
		pass1([TPackage("root", "root types", parser.root)]);
		print(".");
		pass2();
		print(".");
		pass3();
		print(".");
		if( #if neko !Web.isModNeko && #end !writeWebConfig)
			pass4();
		#if neko
		if(writeWebConfig) {
			var p = webConfigFile;
			if(Web.isModNeko)
				p = Web.getCwd() + webConfigFile;
			var f = File.write(p,false);
			var ser = new chx.Serializer(f);
			ser.preSerializeObject = function(o) {
				if(Reflect.hasField(o, "originalDoc")) {
					untyped o.originalDoc = null;
				}
				if(Reflect.hasField(o, "originalMeta")) {
					untyped o.originalMeta = null;
				}
			}
			ser.serialize(config);
			f.close();
		}
		#end
		print("\nComplete.\n");
	}


	static function initDefaultPaths() {
		config.output = Sys.getCwd() + "docs/";
		config.packageDirectory = config.output + "packages/";
		config.typeDirectory = config.output + "types/";
	}

	static function checkAllPaths() {
		initTemplo();

		// Add trailing slashes to all directory paths
		config.output = Utils.addSubdirTrailingSlash(config.output);
		config.packageDirectory = config.output + "packages/";
		config.typeDirectory = config.output + "types/";

		if( #if neko Web.isModNeko || #end writeWebConfig )
			return;

		Utils.createOutputDirectory(config.output);
		Utils.createOutputDirectory(config.packageDirectory);
		Utils.createOutputDirectory(config.typeDirectory);
	}

	static function installTemplate() {
		var targetImgDir = config.output + "images";
		/*
		if(!FileSystem.exists(targetImgDir)) {
			var copyImgDir = config.installImagesDir;
			var srcDir = config.template + "images";
			if(FileSystem.exists(srcDir)) {
				if(!copyImgDir && !config.noPrompt) {
					//copyImgDir = system.Terminal.promptYesNo("Install the images directory from the template?", true);
				}
			}
			if(copyImgDir) {
				// cp -R srcDir config.output
			}
		}
		*/

		if(config.installImagesDir) {
			Utils.createOutputDirectory(targetImgDir);
			var srcDir = config.templatesDir + config.template + "/images";
			if(FileSystem.exists(srcDir) && FileSystem.isDirectory(srcDir)) {
				targetImgDir += "/";
				var entries = FileSystem.readDirectory(srcDir);
				for(i in entries) {
					var p = srcDir + "/" + i;
					if(FileSystem.isDirectory(p))
						continue;
					if(config.verbose)
						println("Installing " + p + " to " + targetImgDir);
					File.copy(p, targetImgDir + i);
				}
			} else {
				if(config.verbose)
					logWarning("Template " + config.templatesDir + config.template + " has no 'images' directory");
			}
		}

		if(config.installCssFile) {
			var srcCssFile = config.templatesDir + config.template + "/stylesheet.css";
			if(FileSystem.exists(srcCssFile)) {
				var targetCssFile = config.output + config.stylesheet;
				if(config.verbose)
					println("Installing " + srcCssFile + " to " + targetCssFile);
				File.copy(srcCssFile, targetCssFile);
			} else {
				if(config.verbose)
					logWarning("Template " + config.templatesDir + config.template + " has no stylesheet.css");
			}

			var srcJsFile = config.templatesDir + config.template + "/chxdoc.js";
			if(FileSystem.exists(srcJsFile)) {
				var targetJsFile = config.output + "chxdoc.js";
				if(config.verbose)
					println("Installing " + srcJsFile + " to " + targetJsFile);
				File.copy(srcJsFile, targetJsFile);
			} else {
				if(config.verbose)
					logWarning("Template " + config.templatesDir + config.template + " has no chxdoc.js");
			}
		}
	}

	/**
		Initializes Templo, exiting if there is any error.
	**/
	static function initTemplo() {

		mtwin.templo.Loader.BASE_DIR =  Utils.addSubdirTrailingSlash(config.templatesDir + config.template);
		mtwin.templo.Loader.TMP_DIR = Utils.addSubdirTrailingSlash(config.tmpDir);
		mtwin.templo.Loader.MACROS = config.macros;

		if(! Web.isModNeko && ! writeWebConfig ) {
			var tmf =  Utils.addSubdirTrailingSlash(config.templatesDir + config.template) + config.macros;
			if(!FileSystem.exists(tmf))
				fatal("The macro file " + tmf + " does not exist.");
			Utils.createOutputDirectory(config.tmpDir);
		}
	}

	static function parseArgs() {
		#if neko
		if( Web.isModNeko ) {
			var data : String =
				try
					File.getContent(Web.getCwd()+webConfigFile)
				catch(e:Dynamic) {
					fatal("There is no configuration data. Please create one with --writeWebConfig");
					null;
				}
			var cfg : Dynamic =
				try
					chx.Unserializer.run ( data )
				catch( e : Dynamic ) {
					fatal("Error unserializing config data: " + Std.string(e));
					null;
				}
			config = cfg;
			return;
		}
		#end

		var args : Array<String> = Sys.args().copy();
		var nextArg = function(errMsg:String):String {
			if(args.length == 0)
				throw Std.string(errMsg);
			return args.shift();
		};

		while( args.length > 0) {
			var arg = nextArg("fatal");
			var r = ~/^\-\-([A-Za-z]+)=/;
			if(r.match(arg)) {
				var parts = arg.split("=");
				if(parts.length > 2) {
					var zero = parts.shift();
					var rest = parts.join("=");
					parts = [zero, rest];
				}
				if(parts[1].charAt(0) == "\"") {
					parts[1] = parts[1].substr(1);
					if(parts[1].charAt(parts[1].length-1) == "\"")
						parts[1] = parts[1].substr(0, parts[1].length-1);
				}
				arg = parts[0];
				args.unshift(parts[1]);
			}
			try {
				handleArg(arg, nextArg, false);
			} catch(e:String) {
				fatal("Error parsing command line: " +e);
			}
		}

		if(writeWebConfig && config.htmlFileExtension != "") {
			if(config.htmlFileExtension != "") {
				logWarning("Html file extension ignored for web configurations");
				config.htmlFileExtension = "";
			}
			if(config.installImagesDir || config.installCssFile) {
				logWarning("Install templates manually for web configurations");
			}
		}

		if(createConfig) {
			Sys.println("Creating chxdocConfig.xml");
			Setup.writeConfig("chxdocConfig.xml", true);
			Sys.exit(0);
		}
		
		if(config.htmlFileExtension == "")
			config.htmlFileExtension = ".html";
		if(config.htmlFileExtension.charAt(0) != ".")
			config.htmlFileExtension = "." + config.htmlFileExtension;
		config.todoFile = "todo" + config.htmlFileExtension;


		var hlp = Utils.getHaxelib();
		if(hlp != null) {
			hlp = hlp.substr(0, hlp.length-1);
			config.templatesDir = StringTools.replace(config.templatesDir, "%HAXELIB%", hlp);
			config.template = StringTools.replace(config.template, "%HAXELIB%", hlp);
		}
		var hlv = config.versionMajor+","+config.versionMinor+","+config.versionRevision;
		config.templatesDir = StringTools.replace(config.templatesDir, "%HAXELIBVER%", hlv);
		config.template = StringTools.replace(config.template, "%HAXELIBVER%", hlv);
		
		if(	config.showPrivateClasses ||
			config.showPrivateTypedefs ||
			config.showPrivateEnums ||
			config.showPrivateMethods ||
			config.showPrivateVars)
				config.developer = true;

		if( Filters.isFiltered("/", false) )
			config.ignoreRoot = true;
	}

	public static function handleArg(arg:String, nextArg:String->String, isXml:Bool) {
		var boolErr = function(s) { return "Expected true or false for --" + s; };
		var pathErr = function(s) { return "Expected path for --" +  s; };
		var fileErr = function(s) { return "Expected file name for --" + s; };
		var textErr = function(s) { return "Expected text for --" + s; };
		var dir = function(s) { return Utils.addSubdirTrailingSlash(s); };
		switch(arg) {
			case "--allow":
				var opts = nextArg("Expected list for --allow").split(",");
				for(p in opts) {
					p = StringTools.trim(p);
					Setup.addFilter(p, ALLOW);
				}
			case "--config":
				Setup.loadConfigFile(nextArg(fileErr("config")));
			case "--createConfig":
				if(isXml)
					throw "createConfig is not permitted in xml files";
				createConfig = true;
			case "--dateLong":
				config.dateLong = nextArg("Expected date format for --dateLong");
				Setup.writeVal("dateLong", config.dateLong);
			case "--dateShort":
				config.dateShort = nextArg("Expected date format for --dateShort");
				Setup.writeVal("dateShort", config.dateShort);
			case "--deny":
				var opts = nextArg("Expected list for --deny").split(",");
				for(p in opts) {
					p = StringTools.trim(p);
					Setup.addFilter(p, DENY);
				}
			case "--developer":
				var show = getBool(nextArg(boolErr("developer")));
				config.showAuthorTags = show;
				config.showMeta = show;
				config.showPrivateClasses = show;
				config.showPrivateTypedefs = show;
				config.showPrivateEnums = show;
				config.showPrivateMethods = show;
				config.showPrivateVars = show;
				config.showTodoTags = show;
				config.generateTodo = show;
				Setup.writeVal("showAuthorTags", config.showAuthorTags);
				Setup.writeVal("showMeta", config.showMeta);
				Setup.writeVal("showPrivateClasses", config.showPrivateClasses);
				Setup.writeVal("showPrivateTypedefs", config.showPrivateTypedefs);
				Setup.writeVal("showPrivateEnums", config.showPrivateEnums);
				Setup.writeVal("showPrivateMethods", config.showPrivateMethods);
				Setup.writeVal("showPrivateVars", config.showPrivateVars);
				Setup.writeVal("showTodoTags", config.showTodoTags);
				Setup.writeVal("generateTodo", config.generateTodo);
			case "-f", "--file":
				var f = nextArg("Xml file specification expected").split(",");
				//config.files.push({name:f[0], platform:f[1], remap:f[2]});
				Setup.addTarget(f[0], f[1], f[2]);
			case "--footerText":
				config.footerText = nextArg(textErr("footerText"));
				Setup.writeVal("footerText", config.footerText);
			case "--footerTextFile":
				var file = nextArg(fileErr("footerTextFile"));
				try {
					if(file != "") {
						Setup.deleteVal("footerText");
						Setup.writeVal("footerTextFile", file);
						config.footerText = File.getContent(file);
					}
				} catch(e : Dynamic) {
					fatal("Unable to load footer file " + file);
				}
			case "--generateTodo":
				config.generateTodo = getBool(nextArg(boolErr("generateTodo")));
				Setup.writeVal("generateTodo", config.generateTodo);
			case "--headerText":
				config.headerText = nextArg(textErr("headerText"));
				Setup.writeVal("headerText", config.headerText);
			case "--headerTextFile":
				var file = nextArg(fileErr("headerTextFile"));
				try {
					if(file != "") {
						Setup.deleteVal("headerText");
						Setup.writeVal("headerTextFile", file);
						config.headerText = File.getContent(file);
					}
				} catch(e : Dynamic) {
					fatal("Unable to load header file " + file);
				}
			case "--help","-help":
				usage(0);
			case "--htmlFileExtension":
				config.htmlFileExtension = nextArg("Expected file extension for html files");
				Setup.writeVal("htmlFileExtension", config.htmlFileExtension);
			case "--installCssFile":
				config.installImagesDir = getBool(nextArg(boolErr("installCssFile")));
				Setup.writeVal("installCssFile", config.installCssFile);
			case "--installImagesDir":
				config.installImagesDir = getBool(nextArg(boolErr("installImagesDir")));
				Setup.writeVal("installImagesDir", config.installImagesDir);
			case "--installTemplate":
				var i = getBool(nextArg(boolErr("installTemplate")));
				config.installImagesDir = i;
				config.installCssFile = i;
				Setup.writeVal("installCssFile", config.installCssFile);
				Setup.writeVal("installImagesDir", config.installImagesDir);
			case "--macros":
				config.macros = nextArg(fileErr("macros"));
				Setup.writeVal("macros", config.macros);
			case "--mergeMeta":
				config.mergeMeta = getBool(nextArg(boolErr("mergeMeta")));
				Setup.writeVal("mergeMeta", config.mergeMeta);
			case "-o","--output":
				config.output = nextArg("Expected output directory");
				config.output = StringTools.replace(config.output,"\\", "/");
				if(config.output.charAt(0) != "/") {
					config.output = Sys.getCwd() + config.output;
				}
				config.output = dir(config.output);
				Setup.writeVal("output", config.output);
			case "--policy":
				var policy = nextArg("Expected value for --policy");
				var p = switch(policy.toLowerCase()) {
					case "allow": ALLOW;
					case "deny": DENY;
					default: throw "Invalid default filter policy " + policy;
				}
				Setup.setFilterPolicy(p);
			case "--showAuthorTags":
				config.showAuthorTags = getBool(nextArg(boolErr("showAuthorTags")));
				Setup.writeVal("showAuthorTags", config.showAuthorTags);
			case "--showMeta":
				config.showMeta = getBool(nextArg(boolErr("showMeta")));
				Setup.writeVal("showMeta", config.showMeta);
			case "--showPrivateClasses":
				config.showPrivateClasses = getBool(nextArg(boolErr("showPrivateClasses")));
				Setup.writeVal("showPrivateClasses", config.showPrivateClasses);
			case "--showPrivateTypedefs":
				config.showPrivateTypedefs = getBool(nextArg(boolErr("showPrivateTypedefs")));
				Setup.writeVal("showPrivateTypedefs", config.showPrivateTypedefs);
			case "--showPrivateEnums":
				config.showPrivateEnums = getBool(nextArg(boolErr("showPrivateEnums")));
				Setup.writeVal("showPrivateEnums", config.showPrivateEnums);
			case "--showPrivateMethods":
				config.showPrivateMethods = getBool(nextArg(boolErr("showPrivateMethods")));
				Setup.writeVal("showPrivateMethods", config.showPrivateMethods);
			case "--showPrivateVars":
				config.showPrivateVars = getBool(nextArg(boolErr("showPrivateVars")));
				Setup.writeVal("showPrivateVars", config.showPrivateVars);
			case "--showTodoTags":
				config.showTodoTags = getBool(nextArg(boolErr("showTodoTags")));
				Setup.writeVal("showTodoTags", config.showTodoTags);
			case "--stylesheet":
				config.stylesheet = nextArg(fileErr("stylesheet"));
				Setup.writeVal("stylesheet", config.stylesheet);
			case "--subtitle":
				config.subtitle = nextArg(textErr("subtitle"));
				Setup.writeVal("subtitle", config.subtitle);
			case "--templatesDir":
				config.templatesDir = dir(nextArg(pathErr("templatesDir")));
				Setup.writeVal("templatesDir", config.templatesDir);
			case "--template":
				config.template = nextArg(pathErr("template"));
				Setup.writeVal("template", config.template);
				if(config.template.charAt(config.template.length-1) != "/")
					config.template = config.template + "/";
			case "--title":
				config.title = nextArg(textErr("title"));
				Setup.writeVal("title", config.title);
			case "--tmpDir":
				config.tmpDir = dir(nextArg(pathErr("tmpDir")));
				Setup.writeVal("tmpDir", config.tmpDir);
			case "-v":
				config.verbose = true;
				Setup.writeVal("verbose", config.verbose);
			case "--verbose":
				config.verbose = getBool(nextArg(boolErr("verbose")));
				Setup.writeVal("verbose", config.verbose);
			case "--webPassword":
				config.webPassword = nextArg(textErr("webPassword"));
				Setup.writeVal("webPassword", config.webPassword);
			case "--writeWebConfig":
				writeWebConfig = true;
			case "--xmlBasePath":
				config.xmlBasePath = dir(nextArg(pathErr("xmlBasePath")));
				Setup.writeVal("xmlBasePath", config.xmlBasePath);
			default:
				throw "Unknown option '" + arg + "'";
		}
	}

	static function getBool(s : String) : Bool {
		if(s == "1" || s == "true" || s == "yes")
			return true;
		return false;
	}

	static function usage(exitVal : Int) {
		println(" Usage : chxdoc [options] [xml files]");
		println(" Options:");
		println("\t--allow=[class[,orPkg[,Paths]]] Allow rule for filter chain");
		println("\t--config=[xmlfile] Load config file (can be multiple)");
		println("\t--createConfig Will write a default xml config file named chxdocConfig.xml and exit");
		println("\t--dateLong=\"[format]\" Format for long dates");
		println("\t--dateShort=\"[format]\" Format for short dates");
		println("\t--deny=[class[,orPkg[,Paths]]] Deny rule for filter chain");
		println("\t--developer=[true|false] Shortcut to showing all privates, if true");
		println("\t-f, --file=name,platform,remap Input xml files. See below");
		println("\t--footerText=\"text\" Text that will be added to footer of Type pages");
		println("\t--footerTextFile=/path/to/file Type pages footer text from file");
		println("\t--generateTodoFile=[true|false] Generate the todo.html file");
		println("\t--headerText=\"text\" Text that will be added to header of Type pages");
		println("\t--headerTextFile=/path/to/file Type pages header text from file");
		println("\t--help This usage list");
		println("\t--htmlFileExtension=html Extension for generated html files");
		println("\t--installCssFile=[true|false] Install stylesheet from template");
		println("\t--installImagesDir=[true|false] Install images from template");
		println("\t--installTemplate=[true|false] Install stylesheet and images from template");
		println("\t--macros=file.mtt Temploc macro file. (default macros.mtt)");
		println("\t--mergeMeta=[true|false] Merge metadata tags to @ tags for similar names");
		println("\t-o, --output=outputdir Sets the output directory (defaults to ./docs)");
		println("\t--policy=[allow|deny] Sets the default policy for the filter chain");
		println("\t--showAuthorTags=[true|false] Toggles showing @author contents");
		println("\t--showMeta=[true|false] Toggle showing metadata");
		println("\t--showPrivateClasses=[true|false] Toggle private classes display");
		println("\t--showPrivateTypedefs=[true|false] Toggle private typedef display");
		println("\t--showPrivateEnums=[true|false] Toggle private enum display");
		println("\t--showPrivateMethods=[true|false] Toggle private method display");
		println("\t--showPrivateVars=[true|false] Toggle private var display");
		println("\t--showTodoTags=[true|false] Toggle showing @todo tags in type documentation");
		println("\t--stylesheet=file Sets the stylesheet relative to the outputdir");
		println("\t--subtitle=string Set the package subtitle");
		println("\t--template=name Template name relative to --templatesDir (default is 'default')");
		println("\t--templatesDir=path Set the base directory for templates");
		println("\t--title=string Set the package title");
		println("\t--tmpDir=path Path for tempory file generation (default ./__chxdoctmp)");
		println("\t-v,--verbose=[true|false] Turns on verbose mode");
		println("\t--webPassword=[pass] Sets a web password for ?reload and ?showconfig");
		println("\t--writeWebConfig Parses everything, serializes and outputs "+ webConfigFile);
		println("\t--xmlBasePath=path Set a default path to xml files");
		
		println("");
		println(" XML Files:");
		println("\tinput.xml[,platform[,remap]");
		println("\tXml files are generated using the -xml option when compiling haxe projects. ");
		println("\tplatform - generate docs for a given platform" );
		println("\tremap - change all references of 'remap' to 'platform'");
		println("\n Sample usage:");
		println("\tchxdoc -f flash9.xml,flash,flash9 --file=php.xml,php");
		println("\t\tWill transform all references to flash.* to flash9.*");
		println("\tchxdoc -o Doc --policy=deny --allow=mypackage.*,Int --developer=true --generateTodoFile=true --showTodoTags=true -f neko.xml,neko");
		println("\t\tGenerates developer docs for mypackage.* and the Int class only, generating the TODO file as well as showing @todo\n\t\ttags in user docs. The output is built in the 'Doc' directory.");
		println("");
		#if neko
		if(Web.isModNeko )
			throw("");
		#end
		Sys.exit(exitVal);
	}

	static function loadXmlFiles() {
		config.platforms = new List();
		if(config.xmlBasePath == null)
			config.xmlBasePath = "";
		for(i in config.files) {
			loadFile(Utils.addSubdirTrailingSlash(config.xmlBasePath) + i.name, i.platform, i.remap);
		}
		parser.sort();
		if( parser.root.length == 0 ) {
			println("Error: no xml data loaded");
			usage(1);
		}
	}

	static function loadFile(file : String, platform:String, ?remap:String) {
		var data : String = null;
		try {
			data = File.getContent(Sys.getCwd()+file);
		} catch(e:Dynamic) {
			fatal("Unable to load platform xml file " + file);
		}
		var x = Xml.parse(data).firstElement();
		if( remap != null )
			transformPackage(x,remap,platform);

		parser.process(x,platform);
		if(platform != null)
			config.platforms.add(platform);
	}

	static function transformPackage( x : Xml, remap, platform ) {
		switch( x.nodeType ) {
		case Xml.Element:
			var p = x.get("path");
			if( p != null && p.length > platform.length && p.substr(0,platform.length) == platform )
				x.set("path", remap + "." + p.substr(platform.length+1));
			for( x in x.elements() )
				transformPackage(x, remap, platform);
		default:
		}
	}

	public static function logDebug(msg:String, ?pkg:PackageContext, ?ctx : Ctx, ?pos:haxe.PosInfos) {
		if( !config.verbose ) return;
		if(pkg != null) {
			msg += " in package " + pkg.full;
		}
		if(ctx != null) {
			msg += " in " + ctx.name;
		}
		msg += " ("+ pos.fileName+":"+pos.lineNumber+")";
		println("DEBUG: " + msg);
	}

	public static function logInfo(msg:String, ?pkg:PackageContext, ?ctx : Ctx, ?pos:haxe.PosInfos) {
		if( !config.verbose ) return;
		if(pkg != null) {
			msg += " in package " + pkg.full;
		}
		if(ctx != null) {
			msg += " in " + ctx.name;
		}
		println("INFO: " + msg);
	}

	/**
	@todo Ctx may be a function, so we need the parent ClassCtx. Requires adding
			'parent' to Ctx typedef
	**/
	public static function logWarning(msg:String, ?pkg:PackageContext, ?ctx : Ctx, ?pos:haxe.PosInfos) {
		if( !config.verbose ) return;
		setDefaultPrinter();
		if(pkg != null) {
			msg += " in package " + pkg.full;
		}
		if(ctx != null) {
			msg += " in " + ctx.name;
		}
		println("WARNING: " + msg);
	}

	public static function logError(msg:String, ?pkg:PackageContext, ?ctx : Ctx, ?pos:haxe.PosInfos) {
		setDefaultPrinter();
		if(pkg != null) {
			msg += " in package " + pkg.full;
		}
		if(ctx != null) {
			msg += " in " + ctx.name;
		}
		println("ERROR: " + msg);
	}

	public static function fatal(msg:String, exitVal:Int=0, ?pos:haxe.PosInfos) {
		setDefaultPrinter();
		if(exitVal == 0)
			exitVal = 1;
		println("FATAL: " + msg);
		#if neko
		if(Web.isModNeko )
			throw "";
		#end
		Sys.exit(exitVal);
	}

	/**
		Sets default print and println functions by platform
	**/
	static function setDefaultPrinter() {
		println = Sys.println;
		print = Sys.print;
		#if neko
		if( Web.isModNeko )
			println = function(v) { Sys.print(v); Sys.println("<BR />"); }
		#end
	}

	/**
		Sets null sink printing
	**/
	static function setNullPrinter() {
		print = function (v) {};
		println = function (v) {};
	}

	static function makeViewableConfig() : Array<{name:String, value: String}> {
		var rv = new Array();
		var addCfg = function(s:String) {
			rv.push({ name:s, value : Std.string(Reflect.field(config, s)) });
		}
		rv.push({ name: "ChxDoc", value: makeVersion() });
		rv.push({ name: "Generated", value: config.dateLong});
		for(i in [
			"stylesheet",
			"template",
			"tmpDir",
			"macros",
			"xmlBasePath"
			])
			addCfg(i);
		for(i in config.files) {
			var s :String = i.name + "," + i.platform + "," + i.remap;
			rv.push({ name: "XML file", value: s });
		}
		return rv;
	}

	/**
		Dot formatted version string
		@returns String formatted version number ie 1.3.1
	**/
	static function makeVersion() : String {
		return config.versionMajor+ "."+
			config.versionMinor + "."+
			config.versionRevision;
	}
}
