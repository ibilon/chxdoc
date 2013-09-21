/*
 * Copyright (c) 2008-2009, The Caffeine-hx project contributors
 * Original author : Russell Weir
 * Contributors: Valentin Lemiere
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

import haxe.rtti.CType;
import chxdoc.Defines;
import chxdoc.Types;

class AbstractHandler extends TypeHandler<AbstractCtx> {
	public function new() {
		super();
	}

	public function pass1(c : Abstractdef) : AbstractCtx {
		return newAbstractCtx(c);
	}


	public function pass2(pkg : PackageContext, ctx : AbstractCtx) 
	{
		ctx.docs = DocProcessor.process(pkg, ctx, ctx.originalDoc, ctx.originalMeta);
		var me = this;
	}

	//Types	-> Resolve all super classes, inheritance, subclasses
	public function pass3(pkg : PackageContext, ctx : AbstractCtx) {
	}

	/**
	 * Remove all private methods before output
	 **/
	public function pass4(pkg : PackageContext, ctx : AbstractCtx) {
	}

	function newAbstractCtx(c : Abstractdef) : AbstractCtx {
		var ctx : AbstractCtx = null;
		var me = this;

		ctx = cast createCommon(c, "abstract");

		return ctx;
	}
}
