import sys.FileSystem;

class Run {

	static var system:String = Sys.systemName();
	static var installdir:String;
	static var builddir:String;
	static var curdir:String;
	static var print:Dynamic->Void = neko.Lib.print;
	static var println:Dynamic->Void = neko.Lib.println;

	static function main() {
		var args = Sys.args().slice(0);
		//trace(args);
		installdir = args.pop();
		curdir = installdir;
		var cmd = args.shift();
		builddir = makePath(Sys.getCwd());
		//trace("cmd: " + cmd);
		//trace("installdir: '"+installdir+"'");
		//trace("build dir: '"+builddir+"'");
		//trace("Environment:");
		//trace(neko.Sys.environment());
		switch(cmd) {
		case "--help":
			usage();
		case "compile":
			compile();
		case "install":
			var p = args.shift();
			if(p != null) {
				installdir = makePath(p);
				if(installdir.substr(0,1) != "/")
					installdir = curdir + installdir;
			}
			try {
				installdir = makePath(installdir);
				compile();
				makeExe("chxdoc");
			} catch(e:Dynamic) {
				Sys.setCwd(curdir);
				neko.Lib.rethrow(e);
			}
			Sys.setCwd(curdir);
		default:
			usage();
		}
	}

	static function usage() {
		println("haxelib run chxdoc [compile | install [installpath]]");
		println("compile - will just run the compile target");
		println("install - will compile and install to the current directory");
		println("          or to the provided installpath");
	}

	static function makePath(p:String) : String {
		var s = StringTools.replace(p, "\\", "/");
		if(s.length == 0)
			s = "/";
		if(s.substr(-1,1) != "/")
			s += "/";
		return s;
	}

	static function compile() {
		Sys.setCwd(builddir);

		print(">> Compiling in " + Sys.getCwd() + "...");
		var p = new sys.io.Process("haxe",["build.hxml"]);
		var code = p.exitCode();
		Sys.setCwd(installdir);
		if( code != 0 )  {
			trace(p.stderr.readAll());
			throw "Error while compiling. Check that haxe is installed.";
		}
		println(" complete");
	}		

	static function makeExe(name:String) {
		var exe = if( system == "Windows" ) name+".exe" else name;
		var nekoname = name + ".n";
		println(">> Installing "+exe+" into " + installdir);
		Sys.setCwd(installdir);
		sys.io.File.copy(builddir+nekoname, installdir+nekoname);
		var p = new sys.io.Process("nekotools",["boot", nekoname]);
		
		var code = p.exitCode();
		if( code != 0 ) {
			throw "!! Error while creating " + name + " executable";
		}

		FileSystem.deleteFile(nekoname);

		if( system != "Windows" )
			Sys.command("chmod a+x " + installdir + exe);
		neko.Lib.println("   "+exe+" is now installed");
	}


}
