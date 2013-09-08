/*
 * Copyright (c) 2008-2012, The Caffeine-hx project contributors
 * Original author : Russell Weir
 * Contributors:
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

//import haxe.rtti.CType;

typedef Filter = {
	var path : String;
	var policy : FilterPolicy;
}

typedef FilterList = List<Filter>;

class Filters {
	static var defaultPolicy : FilterPolicy = ALLOW;
	static var rules : FilterList = new FilterList();

	/**
	 * Add a package or class that will be allowed
	 * in the generated documentation. Package paths should
	 * have a trailing . or use pkg.*
	 *
	 * @param path Package or class path
	 **/
	public static function allow(path:String) {
		rules.add({path : cleanPath(path), policy : ALLOW});
	}

	/**
	 * Clear the list of ignored paths
	 **/
	public static function clear() {
		rules = new FilterList();
	}
	
	/**
	 * Add a package or class that will be filtered out
	 * of the generated documentation. Package paths should
	 * have a trailing . or use pkg.*
	 * @param path Package or class path
	 **/
	public static function deny(path:String) {
		rules.add({path : cleanPath(path), policy : DENY });
	}

	/**
	 * Sets the policy if a package does not match any rules
	 *
	 * @param polval Either "allow" or "deny"
	 **/
	public static function setDefaultPolicy(p:FilterPolicy) {
		defaultPolicy = p;
	}

	static function cleanPath(path:String) : String {
		if(path.charAt(path.length-1) == "*")
			path = path.substr(0, path.length-1);
		if(path == "." || path == "")
			path = "/";
		return path;
	}
	
	/**
	* Checks if a package or class is filtered
	* @param path Package or class path in dotted format
	* @isPackage set to true if path is a package
	* @todo Could do some capitalization check here to determine if path is a package or not
	* @todo What were the paths ending with "__"?
	**/
	public static function isFiltered( path : String, isPackage : Bool ) {
		if( isPackage && path == "Remoting" )
			return true;
		if( StringTools.endsWith(path,"__") )
			return true;

		if(isPackage) {
			if(path.charAt(path.length-1) != ".")
				path += ".";
		}
		for(r in rules) {
			if(matches(path, r)) {
				return switch(r.policy) {
					case ALLOW : false;
					case DENY : true;
				}
			}
		}
		return switch(defaultPolicy) {
			case DENY : true;
			case ALLOW : false;
		}
	}

	static function matches(path:String, rule:Filter) {
		if( path == rule.path )
			return true;
		// "root types" is set on pass1 in ChxDocMain and tested PackageHandler.pass4
		// and used in the templates
		if( rule.path == "/" && (path == "/" || path.indexOf(".") < 0 || StringTools.startsWith(path,"root types")) ) {
			return true;
		}
		if( rule.path.charAt(rule.path.length-1) == "." ) {
			if(StringTools.startsWith(path,rule.path))
				return true;
		}
		return false;
	}

}
