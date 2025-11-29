// Compiles a dart2wasm-generated main module from `source` which can then
// instantiatable via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
export async function compileStreaming(source) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(
      await WebAssembly.compileStreaming(source, builtins), builtins);
}

// Compiles a dart2wasm-generated wasm modules from `bytes` which is then
// instantiatable via the `instantiate` method.
export async function compile(bytes) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(await WebAssembly.compile(bytes, builtins), builtins);
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export async function instantiate(modulePromise, importObjectPromise) {
  var moduleOrCompiledApp = await modulePromise;
  if (!(moduleOrCompiledApp instanceof CompiledApp)) {
    moduleOrCompiledApp = new CompiledApp(moduleOrCompiledApp);
  }
  const instantiatedApp = await moduleOrCompiledApp.instantiate(await importObjectPromise);
  return instantiatedApp.instantiatedModule;
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export const invoke = (moduleInstance, ...args) => {
  moduleInstance.exports.$invokeMain(args);
}

class CompiledApp {
  constructor(module, builtins) {
    this.module = module;
    this.builtins = builtins;
  }

  // The second argument is an options object containing:
  // `loadDeferredWasm` is a JS function that takes a module name matching a
  //   wasm file produced by the dart2wasm compiler and returns the bytes to
  //   load the module. These bytes can be in either a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`.
  // `loadDynamicModule` is a JS function that takes two string names matching,
  //   in order, a wasm file produced by the dart2wasm compiler during dynamic
  //   module compilation and a corresponding js file produced by the same
  //   compilation. It should return a JS Array containing 2 elements. The first
  //   should be the bytes for the wasm module in a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`. The second
  //   should be the result of using the JS 'import' API on the js file path.
  async instantiate(additionalImports, {loadDeferredWasm, loadDynamicModule} = {}) {
    let dartInstance;

    // Prints to the console
    function printToConsole(value) {
      if (typeof dartPrint == "function") {
        dartPrint(value);
        return;
      }
      if (typeof console == "object" && typeof console.log != "undefined") {
        console.log(value);
        return;
      }
      if (typeof print == "function") {
        print(value);
        return;
      }

      throw "Unable to print message: " + value;
    }

    // A special symbol attached to functions that wrap Dart functions.
    const jsWrappedDartFunctionSymbol = Symbol("JSWrappedDartFunction");

    function finalizeWrapper(dartFunction, wrapped) {
      wrapped.dartFunction = dartFunction;
      wrapped[jsWrappedDartFunctionSymbol] = true;
      return wrapped;
    }

    // Imports
    const dart2wasm = {
            _3: (o, t) => typeof o === t,
      _4: (o, c) => o instanceof c,
      _7: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._7(f,arguments.length,x0) }),
      _8: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._8(f,arguments.length,x0,x1) }),
      _9: (o, a) => o + a,
      _19: (o, a) => o == a,
      _36: () => new Array(),
      _37: x0 => new Array(x0),
      _39: x0 => x0.length,
      _41: (x0,x1) => x0[x1],
      _42: (x0,x1,x2) => { x0[x1] = x2 },
      _43: x0 => new Promise(x0),
      _45: (x0,x1,x2) => new DataView(x0,x1,x2),
      _47: x0 => new Int8Array(x0),
      _48: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      _49: x0 => new Uint8Array(x0),
      _51: x0 => new Uint8ClampedArray(x0),
      _53: x0 => new Int16Array(x0),
      _55: x0 => new Uint16Array(x0),
      _57: x0 => new Int32Array(x0),
      _59: x0 => new Uint32Array(x0),
      _61: x0 => new Float32Array(x0),
      _63: x0 => new Float64Array(x0),
      _65: (x0,x1,x2) => x0.call(x1,x2),
      _67: (x0,x1) => x0.call(x1),
      _70: (decoder, codeUnits) => decoder.decode(codeUnits),
      _71: () => new TextDecoder("utf-8", {fatal: true}),
      _72: () => new TextDecoder("utf-8", {fatal: false}),
      _73: (s) => +s,
      _74: x0 => new Uint8Array(x0),
      _75: (x0,x1,x2) => x0.set(x1,x2),
      _76: (x0,x1) => x0.transferFromImageBitmap(x1),
      _77: x0 => x0.arrayBuffer(),
      _78: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._78(f,arguments.length,x0) }),
      _79: x0 => new window.FinalizationRegistry(x0),
      _80: (x0,x1,x2,x3) => x0.register(x1,x2,x3),
      _81: (x0,x1) => x0.unregister(x1),
      _82: (x0,x1,x2) => x0.slice(x1,x2),
      _83: (x0,x1) => x0.decode(x1),
      _84: (x0,x1) => x0.segment(x1),
      _85: () => new TextDecoder(),
      _86: (x0,x1) => x0.get(x1),
      _87: x0 => x0.click(),
      _88: x0 => x0.buffer,
      _89: x0 => x0.wasmMemory,
      _90: () => globalThis.window._flutter_skwasmInstance,
      _91: x0 => x0.rasterStartMilliseconds,
      _92: x0 => x0.rasterEndMilliseconds,
      _93: x0 => x0.imageBitmaps,
      _120: x0 => x0.remove(),
      _121: (x0,x1) => x0.append(x1),
      _122: (x0,x1,x2) => x0.insertBefore(x1,x2),
      _123: (x0,x1) => x0.querySelector(x1),
      _125: (x0,x1) => x0.removeChild(x1),
      _203: x0 => x0.stopPropagation(),
      _204: x0 => x0.preventDefault(),
      _206: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      _251: x0 => x0.unlock(),
      _252: x0 => x0.getReader(),
      _253: (x0,x1,x2) => x0.addEventListener(x1,x2),
      _254: (x0,x1,x2) => x0.removeEventListener(x1,x2),
      _255: (x0,x1) => x0.item(x1),
      _256: x0 => x0.next(),
      _257: x0 => x0.now(),
      _258: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._258(f,arguments.length,x0) }),
      _259: (x0,x1) => x0.addListener(x1),
      _260: (x0,x1) => x0.removeListener(x1),
      _261: (x0,x1) => x0.matchMedia(x1),
      _262: (x0,x1) => x0.revokeObjectURL(x1),
      _263: x0 => x0.close(),
      _264: (x0,x1,x2,x3,x4) => ({type: x0,data: x1,premultiplyAlpha: x2,colorSpaceConversion: x3,preferAnimation: x4}),
      _265: x0 => new window.ImageDecoder(x0),
      _266: x0 => ({frameIndex: x0}),
      _267: (x0,x1) => x0.decode(x1),
      _268: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._268(f,arguments.length,x0) }),
      _269: (x0,x1) => x0.getModifierState(x1),
      _270: (x0,x1) => x0.removeProperty(x1),
      _271: (x0,x1) => x0.prepend(x1),
      _272: x0 => x0.disconnect(),
      _273: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._273(f,arguments.length,x0) }),
      _274: (x0,x1) => x0.getAttribute(x1),
      _275: (x0,x1) => x0.contains(x1),
      _276: x0 => x0.blur(),
      _277: x0 => x0.hasFocus(),
      _278: (x0,x1) => x0.hasAttribute(x1),
      _279: (x0,x1) => x0.getModifierState(x1),
      _280: (x0,x1) => x0.appendChild(x1),
      _281: (x0,x1) => x0.createTextNode(x1),
      _282: (x0,x1) => x0.removeAttribute(x1),
      _283: x0 => x0.getBoundingClientRect(),
      _284: (x0,x1) => x0.observe(x1),
      _285: x0 => x0.disconnect(),
      _286: (x0,x1) => x0.closest(x1),
      _696: () => globalThis.window.flutterConfiguration,
      _697: x0 => x0.assetBase,
      _703: x0 => x0.debugShowSemanticsNodes,
      _704: x0 => x0.hostElement,
      _705: x0 => x0.multiViewEnabled,
      _706: x0 => x0.nonce,
      _708: x0 => x0.fontFallbackBaseUrl,
      _712: x0 => x0.console,
      _713: x0 => x0.devicePixelRatio,
      _714: x0 => x0.document,
      _715: x0 => x0.history,
      _716: x0 => x0.innerHeight,
      _717: x0 => x0.innerWidth,
      _718: x0 => x0.location,
      _719: x0 => x0.navigator,
      _720: x0 => x0.visualViewport,
      _721: x0 => x0.performance,
      _723: x0 => x0.URL,
      _725: (x0,x1) => x0.getComputedStyle(x1),
      _726: x0 => x0.screen,
      _727: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._727(f,arguments.length,x0) }),
      _728: (x0,x1) => x0.requestAnimationFrame(x1),
      _733: (x0,x1) => x0.warn(x1),
      _735: (x0,x1) => x0.debug(x1),
      _736: x0 => globalThis.parseFloat(x0),
      _737: () => globalThis.window,
      _738: () => globalThis.Intl,
      _739: () => globalThis.Symbol,
      _740: (x0,x1,x2,x3,x4) => globalThis.createImageBitmap(x0,x1,x2,x3,x4),
      _742: x0 => x0.clipboard,
      _743: x0 => x0.maxTouchPoints,
      _744: x0 => x0.vendor,
      _745: x0 => x0.language,
      _746: x0 => x0.platform,
      _747: x0 => x0.userAgent,
      _748: (x0,x1) => x0.vibrate(x1),
      _749: x0 => x0.languages,
      _750: x0 => x0.documentElement,
      _751: (x0,x1) => x0.querySelector(x1),
      _754: (x0,x1) => x0.createElement(x1),
      _757: (x0,x1) => x0.createEvent(x1),
      _758: x0 => x0.activeElement,
      _761: x0 => x0.head,
      _762: x0 => x0.body,
      _764: (x0,x1) => { x0.title = x1 },
      _767: x0 => x0.visibilityState,
      _768: () => globalThis.document,
      _769: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._769(f,arguments.length,x0) }),
      _770: (x0,x1) => x0.dispatchEvent(x1),
      _778: x0 => x0.target,
      _780: x0 => x0.timeStamp,
      _781: x0 => x0.type,
      _783: (x0,x1,x2,x3) => x0.initEvent(x1,x2,x3),
      _790: x0 => x0.firstChild,
      _794: x0 => x0.parentElement,
      _796: (x0,x1) => { x0.textContent = x1 },
      _797: x0 => x0.parentNode,
      _799: x0 => x0.isConnected,
      _803: x0 => x0.firstElementChild,
      _805: x0 => x0.nextElementSibling,
      _806: x0 => x0.clientHeight,
      _807: x0 => x0.clientWidth,
      _808: x0 => x0.offsetHeight,
      _809: x0 => x0.offsetWidth,
      _810: x0 => x0.id,
      _811: (x0,x1) => { x0.id = x1 },
      _814: (x0,x1) => { x0.spellcheck = x1 },
      _815: x0 => x0.tagName,
      _816: x0 => x0.style,
      _818: (x0,x1) => x0.querySelectorAll(x1),
      _819: (x0,x1,x2) => x0.setAttribute(x1,x2),
      _820: x0 => x0.tabIndex,
      _821: (x0,x1) => { x0.tabIndex = x1 },
      _822: (x0,x1) => x0.focus(x1),
      _823: x0 => x0.scrollTop,
      _824: (x0,x1) => { x0.scrollTop = x1 },
      _825: x0 => x0.scrollLeft,
      _826: (x0,x1) => { x0.scrollLeft = x1 },
      _827: x0 => x0.classList,
      _829: (x0,x1) => { x0.className = x1 },
      _831: (x0,x1) => x0.getElementsByClassName(x1),
      _832: (x0,x1) => x0.attachShadow(x1),
      _835: x0 => x0.computedStyleMap(),
      _836: (x0,x1) => x0.get(x1),
      _842: (x0,x1) => x0.getPropertyValue(x1),
      _843: (x0,x1,x2,x3) => x0.setProperty(x1,x2,x3),
      _844: x0 => x0.offsetLeft,
      _845: x0 => x0.offsetTop,
      _846: x0 => x0.offsetParent,
      _848: (x0,x1) => { x0.name = x1 },
      _849: x0 => x0.content,
      _850: (x0,x1) => { x0.content = x1 },
      _854: (x0,x1) => { x0.src = x1 },
      _855: x0 => x0.naturalWidth,
      _856: x0 => x0.naturalHeight,
      _860: (x0,x1) => { x0.crossOrigin = x1 },
      _862: (x0,x1) => { x0.decoding = x1 },
      _863: x0 => x0.decode(),
      _868: (x0,x1) => { x0.nonce = x1 },
      _873: (x0,x1) => { x0.width = x1 },
      _875: (x0,x1) => { x0.height = x1 },
      _878: (x0,x1) => x0.getContext(x1),
      _937: x0 => x0.width,
      _938: x0 => x0.height,
      _940: (x0,x1) => x0.fetch(x1),
      _941: x0 => x0.status,
      _942: x0 => x0.headers,
      _943: x0 => x0.body,
      _944: x0 => x0.arrayBuffer(),
      _947: x0 => x0.read(),
      _948: x0 => x0.value,
      _949: x0 => x0.done,
      _951: x0 => x0.name,
      _952: x0 => x0.x,
      _953: x0 => x0.y,
      _956: x0 => x0.top,
      _957: x0 => x0.right,
      _958: x0 => x0.bottom,
      _959: x0 => x0.left,
      _971: x0 => x0.height,
      _972: x0 => x0.width,
      _973: x0 => x0.scale,
      _974: (x0,x1) => { x0.value = x1 },
      _977: (x0,x1) => { x0.placeholder = x1 },
      _979: (x0,x1) => { x0.name = x1 },
      _980: x0 => x0.selectionDirection,
      _981: x0 => x0.selectionStart,
      _982: x0 => x0.selectionEnd,
      _985: x0 => x0.value,
      _987: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      _988: x0 => x0.readText(),
      _989: (x0,x1) => x0.writeText(x1),
      _991: x0 => x0.altKey,
      _992: x0 => x0.code,
      _993: x0 => x0.ctrlKey,
      _994: x0 => x0.key,
      _995: x0 => x0.keyCode,
      _996: x0 => x0.location,
      _997: x0 => x0.metaKey,
      _998: x0 => x0.repeat,
      _999: x0 => x0.shiftKey,
      _1000: x0 => x0.isComposing,
      _1002: x0 => x0.state,
      _1003: (x0,x1) => x0.go(x1),
      _1005: (x0,x1,x2,x3) => x0.pushState(x1,x2,x3),
      _1006: (x0,x1,x2,x3) => x0.replaceState(x1,x2,x3),
      _1007: x0 => x0.pathname,
      _1008: x0 => x0.search,
      _1009: x0 => x0.hash,
      _1013: x0 => x0.state,
      _1016: (x0,x1) => x0.createObjectURL(x1),
      _1018: x0 => new Blob(x0),
      _1020: x0 => new MutationObserver(x0),
      _1021: (x0,x1,x2) => x0.observe(x1,x2),
      _1022: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1022(f,arguments.length,x0,x1) }),
      _1025: x0 => x0.attributeName,
      _1026: x0 => x0.type,
      _1027: x0 => x0.matches,
      _1028: x0 => x0.matches,
      _1032: x0 => x0.relatedTarget,
      _1034: x0 => x0.clientX,
      _1035: x0 => x0.clientY,
      _1036: x0 => x0.offsetX,
      _1037: x0 => x0.offsetY,
      _1040: x0 => x0.button,
      _1041: x0 => x0.buttons,
      _1042: x0 => x0.ctrlKey,
      _1046: x0 => x0.pointerId,
      _1047: x0 => x0.pointerType,
      _1048: x0 => x0.pressure,
      _1049: x0 => x0.tiltX,
      _1050: x0 => x0.tiltY,
      _1051: x0 => x0.getCoalescedEvents(),
      _1054: x0 => x0.deltaX,
      _1055: x0 => x0.deltaY,
      _1056: x0 => x0.wheelDeltaX,
      _1057: x0 => x0.wheelDeltaY,
      _1058: x0 => x0.deltaMode,
      _1065: x0 => x0.changedTouches,
      _1068: x0 => x0.clientX,
      _1069: x0 => x0.clientY,
      _1072: x0 => x0.data,
      _1075: (x0,x1) => { x0.disabled = x1 },
      _1077: (x0,x1) => { x0.type = x1 },
      _1078: (x0,x1) => { x0.max = x1 },
      _1079: (x0,x1) => { x0.min = x1 },
      _1080: x0 => x0.value,
      _1081: (x0,x1) => { x0.value = x1 },
      _1082: x0 => x0.disabled,
      _1083: (x0,x1) => { x0.disabled = x1 },
      _1085: (x0,x1) => { x0.placeholder = x1 },
      _1087: (x0,x1) => { x0.name = x1 },
      _1089: (x0,x1) => { x0.autocomplete = x1 },
      _1090: x0 => x0.selectionDirection,
      _1092: x0 => x0.selectionStart,
      _1093: x0 => x0.selectionEnd,
      _1096: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      _1097: (x0,x1) => x0.add(x1),
      _1100: (x0,x1) => { x0.noValidate = x1 },
      _1101: (x0,x1) => { x0.method = x1 },
      _1102: (x0,x1) => { x0.action = x1 },
      _1103: (x0,x1) => new OffscreenCanvas(x0,x1),
      _1109: (x0,x1) => x0.getContext(x1),
      _1111: x0 => x0.convertToBlob(),
      _1128: x0 => x0.orientation,
      _1129: x0 => x0.width,
      _1130: x0 => x0.height,
      _1131: (x0,x1) => x0.lock(x1),
      _1150: x0 => new ResizeObserver(x0),
      _1153: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1153(f,arguments.length,x0,x1) }),
      _1161: x0 => x0.length,
      _1162: x0 => x0.iterator,
      _1163: x0 => x0.Segmenter,
      _1164: x0 => x0.v8BreakIterator,
      _1165: (x0,x1) => new Intl.Segmenter(x0,x1),
      _1166: x0 => x0.done,
      _1167: x0 => x0.value,
      _1168: x0 => x0.index,
      _1172: (x0,x1) => new Intl.v8BreakIterator(x0,x1),
      _1173: (x0,x1) => x0.adoptText(x1),
      _1174: x0 => x0.first(),
      _1175: x0 => x0.next(),
      _1176: x0 => x0.current(),
      _1182: x0 => x0.hostElement,
      _1183: x0 => x0.viewConstraints,
      _1186: x0 => x0.maxHeight,
      _1187: x0 => x0.maxWidth,
      _1188: x0 => x0.minHeight,
      _1189: x0 => x0.minWidth,
      _1190: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1190(f,arguments.length,x0) }),
      _1191: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1191(f,arguments.length,x0) }),
      _1192: (x0,x1) => ({addView: x0,removeView: x1}),
      _1193: x0 => x0.loader,
      _1194: () => globalThis._flutter,
      _1195: (x0,x1) => x0.didCreateEngineInitializer(x1),
      _1196: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1196(f,arguments.length,x0) }),
      _1197: f => finalizeWrapper(f, function() { return dartInstance.exports._1197(f,arguments.length) }),
      _1198: (x0,x1) => ({initializeEngine: x0,autoStart: x1}),
      _1199: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1199(f,arguments.length,x0) }),
      _1200: x0 => ({runApp: x0}),
      _1201: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1201(f,arguments.length,x0,x1) }),
      _1202: x0 => x0.length,
      _1203: () => globalThis.window.ImageDecoder,
      _1204: x0 => x0.tracks,
      _1206: x0 => x0.completed,
      _1208: x0 => x0.image,
      _1214: x0 => x0.displayWidth,
      _1215: x0 => x0.displayHeight,
      _1216: x0 => x0.duration,
      _1219: x0 => x0.ready,
      _1220: x0 => x0.selectedTrack,
      _1221: x0 => x0.repetitionCount,
      _1222: x0 => x0.frameCount,
      _1265: x0 => x0.createRange(),
      _1266: (x0,x1) => x0.selectNode(x1),
      _1267: x0 => x0.getSelection(),
      _1268: x0 => x0.removeAllRanges(),
      _1269: (x0,x1) => x0.addRange(x1),
      _1270: (x0,x1) => x0.createElement(x1),
      _1271: (x0,x1) => x0.append(x1),
      _1272: (x0,x1,x2) => x0.insertRule(x1,x2),
      _1273: (x0,x1) => x0.add(x1),
      _1274: x0 => x0.preventDefault(),
      _1275: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1275(f,arguments.length,x0) }),
      _1276: (x0,x1,x2) => x0.addEventListener(x1,x2),
      _1277: () => globalThis.window.navigator.userAgent,
      _1278: x0 => ({type: x0}),
      _1279: (x0,x1) => new Blob(x0,x1),
      _1280: x0 => globalThis.URL.createObjectURL(x0),
      _1281: x0 => x0.click(),
      _1282: x0 => globalThis.URL.revokeObjectURL(x0),
      _1289: (x0,x1) => x0.append(x1),
      _1290: (x0,x1,x2) => x0.setAttribute(x1,x2),
      _1305: (x0,x1,x2) => x0.addEventListener(x1,x2),
      _1309: (x0,x1,x2) => x0.removeEventListener(x1,x2),
      _1324: x0 => x0.call(),
      _1325: x0 => x0.preventDefault(),
      _1326: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      _1327: (x0,x1,x2,x3) => x0.removeEventListener(x1,x2,x3),
      _1328: (x0,x1) => x0.createElement(x1),
      _1330: (x0,x1) => x0.getAttribute(x1),
      _1334: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      _1335: x0 => x0.remove(),
      _1339: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1339(f,arguments.length,x0) }),
      _1340: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1340(f,arguments.length,x0) }),
      _1341: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1341(f,arguments.length,x0) }),
      _1342: (x0,x1) => x0.querySelector(x1),
      _1343: (x0,x1) => x0.replaceChildren(x1),
      _1344: x0 => x0.disconnect(),
      _1345: x0 => x0.disconnect(),
      _1346: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1346(f,arguments.length,x0,x1) }),
      _1347: x0 => new ResizeObserver(x0),
      _1348: (x0,x1) => x0.observe(x1),
      _1349: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1349(f,arguments.length,x0,x1) }),
      _1350: x0 => new MutationObserver(x0),
      _1351: x0 => ({childList: x0}),
      _1352: (x0,x1,x2) => x0.observe(x1,x2),
      _1353: (x0,x1) => x0.item(x1),
      _1354: x0 => x0.decode(),
      _1355: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      _1356: (x0,x1,x2) => x0.setRequestHeader(x1,x2),
      _1357: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1357(f,arguments.length,x0) }),
      _1358: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1358(f,arguments.length,x0) }),
      _1359: x0 => x0.send(),
      _1360: () => new XMLHttpRequest(),
      _1362: (x0,x1) => x0.getContext(x1),
      _1376: () => ({}),
      _1377: x0 => globalThis.pdfjsLib.getDocument(x0),
      _1378: (x0,x1) => x0.getPage(x1),
      _1379: (x0,x1) => x0.getViewport(x1),
      _1380: (x0,x1) => x0.render(x1),
      _1381: (x0,x1,x2,x3,x4) => x0.getImageData(x1,x2,x3,x4),
      _1382: x0 => x0.destroy(),
      _1383: x0 => ({scale: x0}),
      _1384: (x0,x1) => x0.getItem(x1),
      _1385: (x0,x1) => x0.removeItem(x1),
      _1386: (x0,x1,x2) => x0.setItem(x1,x2),
      _1387: (x0,x1) => x0.item(x1),
      _1388: () => new FileReader(),
      _1390: (x0,x1) => x0.readAsArrayBuffer(x1),
      _1391: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1391(f,arguments.length,x0) }),
      _1392: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1392(f,arguments.length,x0) }),
      _1393: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1393(f,arguments.length,x0) }),
      _1394: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1394(f,arguments.length,x0) }),
      _1395: (x0,x1) => x0.removeChild(x1),
      _1398: x0 => x0.deviceMemory,
      _1399: () => new SpeechSynthesisUtterance(),
      _1400: x0 => x0.pause(),
      _1401: x0 => x0.resume(),
      _1402: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1402(f,arguments.length,x0) }),
      _1403: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1403(f,arguments.length,x0) }),
      _1404: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1404(f,arguments.length,x0) }),
      _1405: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1405(f,arguments.length,x0) }),
      _1406: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1406(f,arguments.length,x0) }),
      _1407: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1407(f,arguments.length,x0) }),
      _1408: (x0,x1) => x0.speak(x1),
      _1409: x0 => x0.cancel(),
      _1410: x0 => x0.getVoices(),
      _1412: (x0,x1) => x0.initialize(x1),
      _1413: (x0,x1) => x0.initTokenClient(x1),
      _1416: x0 => x0.disableAutoSelect(),
      _1417: Date.now,
      _1419: s => new Date(s * 1000).getTimezoneOffset() * 60,
      _1420: s => {
        if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(s)) {
          return NaN;
        }
        return parseFloat(s);
      },
      _1421: () => {
        let stackString = new Error().stack.toString();
        let frames = stackString.split('\n');
        let drop = 2;
        if (frames[0] === 'Error') {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      _1422: () => typeof dartUseDateNowForTicks !== "undefined",
      _1423: () => 1000 * performance.now(),
      _1424: () => Date.now(),
      _1425: () => {
        // On browsers return `globalThis.location.href`
        if (globalThis.location != null) {
          return globalThis.location.href;
        }
        return null;
      },
      _1426: () => {
        return typeof process != "undefined" &&
               Object.prototype.toString.call(process) == "[object process]" &&
               process.platform == "win32"
      },
      _1427: () => new WeakMap(),
      _1428: (map, o) => map.get(o),
      _1429: (map, o, v) => map.set(o, v),
      _1430: x0 => new WeakRef(x0),
      _1431: x0 => x0.deref(),
      _1432: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1432(f,arguments.length,x0) }),
      _1433: x0 => new FinalizationRegistry(x0),
      _1434: (x0,x1,x2,x3) => x0.register(x1,x2,x3),
      _1436: (x0,x1) => x0.unregister(x1),
      _1438: () => globalThis.WeakRef,
      _1439: () => globalThis.FinalizationRegistry,
      _1441: s => JSON.stringify(s),
      _1442: s => printToConsole(s),
      _1443: (o, p, r) => o.replaceAll(p, () => r),
      _1444: (o, p, r) => o.replace(p, () => r),
      _1445: Function.prototype.call.bind(String.prototype.toLowerCase),
      _1446: s => s.toUpperCase(),
      _1447: s => s.trim(),
      _1448: s => s.trimLeft(),
      _1449: s => s.trimRight(),
      _1450: (string, times) => string.repeat(times),
      _1451: Function.prototype.call.bind(String.prototype.indexOf),
      _1452: (s, p, i) => s.lastIndexOf(p, i),
      _1453: (string, token) => string.split(token),
      _1454: Object.is,
      _1455: o => o instanceof Array,
      _1456: (a, i) => a.push(i),
      _1457: (a, i) => a.splice(i, 1)[0],
      _1459: (a, l) => a.length = l,
      _1460: a => a.pop(),
      _1461: (a, i) => a.splice(i, 1),
      _1462: (a, s) => a.join(s),
      _1463: (a, s, e) => a.slice(s, e),
      _1464: (a, s, e) => a.splice(s, e),
      _1465: (a, b) => a == b ? 0 : (a > b ? 1 : -1),
      _1466: a => a.length,
      _1467: (a, l) => a.length = l,
      _1468: (a, i) => a[i],
      _1469: (a, i, v) => a[i] = v,
      _1471: o => {
        if (o instanceof ArrayBuffer) return 0;
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
          return 1;
        }
        return 2;
      },
      _1472: (o, offsetInBytes, lengthInBytes) => {
        var dst = new ArrayBuffer(lengthInBytes);
        new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
        return new DataView(dst);
      },
      _1473: o => o instanceof DataView,
      _1474: o => o instanceof Uint8Array,
      _1475: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      _1476: o => o instanceof Int8Array,
      _1477: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      _1478: o => o instanceof Uint8ClampedArray,
      _1479: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      _1480: o => o instanceof Uint16Array,
      _1481: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      _1482: o => o instanceof Int16Array,
      _1483: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      _1484: o => o instanceof Uint32Array,
      _1485: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      _1486: o => o instanceof Int32Array,
      _1487: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      _1489: (o, start, length) => new BigInt64Array(o.buffer, o.byteOffset + start, length),
      _1490: o => o instanceof Float32Array,
      _1491: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      _1492: o => o instanceof Float64Array,
      _1493: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      _1494: (t, s) => t.set(s),
      _1495: l => new DataView(new ArrayBuffer(l)),
      _1496: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      _1497: o => o.byteLength,
      _1498: o => o.buffer,
      _1499: o => o.byteOffset,
      _1500: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      _1501: (b, o) => new DataView(b, o),
      _1502: (b, o, l) => new DataView(b, o, l),
      _1503: Function.prototype.call.bind(DataView.prototype.getUint8),
      _1504: Function.prototype.call.bind(DataView.prototype.setUint8),
      _1505: Function.prototype.call.bind(DataView.prototype.getInt8),
      _1506: Function.prototype.call.bind(DataView.prototype.setInt8),
      _1507: Function.prototype.call.bind(DataView.prototype.getUint16),
      _1508: Function.prototype.call.bind(DataView.prototype.setUint16),
      _1509: Function.prototype.call.bind(DataView.prototype.getInt16),
      _1510: Function.prototype.call.bind(DataView.prototype.setInt16),
      _1511: Function.prototype.call.bind(DataView.prototype.getUint32),
      _1512: Function.prototype.call.bind(DataView.prototype.setUint32),
      _1513: Function.prototype.call.bind(DataView.prototype.getInt32),
      _1514: Function.prototype.call.bind(DataView.prototype.setInt32),
      _1517: Function.prototype.call.bind(DataView.prototype.getBigInt64),
      _1518: Function.prototype.call.bind(DataView.prototype.setBigInt64),
      _1519: Function.prototype.call.bind(DataView.prototype.getFloat32),
      _1520: Function.prototype.call.bind(DataView.prototype.setFloat32),
      _1521: Function.prototype.call.bind(DataView.prototype.getFloat64),
      _1522: Function.prototype.call.bind(DataView.prototype.setFloat64),
      _1535: (ms, c) =>
      setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
      _1536: (handle) => clearTimeout(handle),
      _1537: (ms, c) =>
      setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
      _1538: (handle) => clearInterval(handle),
      _1539: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      _1540: () => Date.now(),
      _1545: o => Object.keys(o),
      _1546: (x0,x1) => x0.postMessage(x1),
      _1548: x0 => new Worker(x0),
      _1550: x0 => x0.getDirectory(),
      _1551: x0 => ({create: x0}),
      _1552: (x0,x1,x2) => x0.getFileHandle(x1,x2),
      _1553: x0 => x0.createSyncAccessHandle(),
      _1554: x0 => x0.close(),
      _1557: x0 => x0.close(),
      _1560: (x0,x1,x2) => x0.open(x1,x2),
      _1566: x0 => x0.start(),
      _1567: x0 => x0.close(),
      _1568: x0 => x0.terminate(),
      _1569: (x0,x1) => new SharedWorker(x0,x1),
      _1570: (x0,x1,x2) => x0.postMessage(x1,x2),
      _1571: (x0,x1,x2) => x0.postMessage(x1,x2),
      _1572: () => new MessageChannel(),
      _1575: x0 => x0.arrayBuffer(),
      _1578: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1578(f,arguments.length,x0) }),
      _1579: (x0,x1) => new WebSocket(x0,x1),
      _1580: (x0,x1) => x0.send(x1),
      _1581: (x0,x1,x2) => x0.close(x1,x2),
      _1582: (x0,x1) => x0.close(x1),
      _1583: x0 => x0.close(),
      _1584: x0 => x0.continue(),
      _1585: () => globalThis.indexedDB,
      _1587: x0 => x0.sqlite3_initialize,
      _1589: (x0,x1,x2,x3,x4) => x0.sqlite3_open_v2(x1,x2,x3,x4),
      _1590: (x0,x1) => x0.sqlite3_close_v2(x1),
      _1591: (x0,x1,x2) => x0.sqlite3_extended_result_codes(x1,x2),
      _1592: (x0,x1) => x0.sqlite3_extended_errcode(x1),
      _1593: (x0,x1) => x0.sqlite3_errmsg(x1),
      _1594: (x0,x1) => x0.sqlite3_errstr(x1),
      _1595: x0 => x0.sqlite3_error_offset,
      _1599: (x0,x1) => x0.sqlite3_last_insert_rowid(x1),
      _1600: (x0,x1) => x0.sqlite3_changes(x1),
      _1601: (x0,x1,x2,x3,x4,x5) => x0.sqlite3_exec(x1,x2,x3,x4,x5),
      _1604: (x0,x1,x2,x3,x4,x5,x6) => x0.sqlite3_prepare_v3(x1,x2,x3,x4,x5,x6),
      _1605: (x0,x1) => x0.sqlite3_finalize(x1),
      _1606: (x0,x1) => x0.sqlite3_step(x1),
      _1607: (x0,x1) => x0.sqlite3_reset(x1),
      _1608: (x0,x1) => x0.sqlite3_stmt_isexplain(x1),
      _1610: (x0,x1) => x0.sqlite3_column_count(x1),
      _1611: (x0,x1) => x0.sqlite3_bind_parameter_count(x1),
      _1613: (x0,x1,x2) => x0.sqlite3_column_name(x1,x2),
      _1614: (x0,x1,x2,x3,x4,x5) => x0.sqlite3_bind_blob64(x1,x2,x3,x4,x5),
      _1615: (x0,x1,x2,x3) => x0.sqlite3_bind_double(x1,x2,x3),
      _1616: (x0,x1,x2,x3) => x0.sqlite3_bind_int64(x1,x2,x3),
      _1617: (x0,x1,x2) => x0.sqlite3_bind_null(x1,x2),
      _1618: (x0,x1,x2,x3,x4,x5) => x0.sqlite3_bind_text(x1,x2,x3,x4,x5),
      _1619: (x0,x1,x2) => x0.sqlite3_column_blob(x1,x2),
      _1620: (x0,x1,x2) => x0.sqlite3_column_double(x1,x2),
      _1621: (x0,x1,x2) => x0.sqlite3_column_int64(x1,x2),
      _1622: (x0,x1,x2) => x0.sqlite3_column_text(x1,x2),
      _1623: (x0,x1,x2) => x0.sqlite3_column_bytes(x1,x2),
      _1624: (x0,x1,x2) => x0.sqlite3_column_type(x1,x2),
      _1625: (x0,x1) => x0.sqlite3_value_blob(x1),
      _1626: (x0,x1) => x0.sqlite3_value_double(x1),
      _1627: (x0,x1) => x0.sqlite3_value_type(x1),
      _1628: (x0,x1) => x0.sqlite3_value_int64(x1),
      _1629: (x0,x1) => x0.sqlite3_value_text(x1),
      _1630: (x0,x1) => x0.sqlite3_value_bytes(x1),
      _1633: (x0,x1) => x0.sqlite3_user_data(x1),
      _1634: (x0,x1,x2,x3,x4) => x0.sqlite3_result_blob64(x1,x2,x3,x4),
      _1635: (x0,x1,x2) => x0.sqlite3_result_double(x1,x2),
      _1636: (x0,x1,x2,x3) => x0.sqlite3_result_error(x1,x2,x3),
      _1637: (x0,x1,x2) => x0.sqlite3_result_int64(x1,x2),
      _1638: (x0,x1) => x0.sqlite3_result_null(x1),
      _1639: (x0,x1,x2,x3,x4) => x0.sqlite3_result_text(x1,x2,x3,x4),
      _1640: x0 => x0.sqlite3_result_subtype,
      _1659: (x0,x1) => x0.dart_sqlite3_malloc(x1),
      _1660: (x0,x1) => x0.dart_sqlite3_free(x1),
      _1661: (x0,x1,x2,x3) => x0.dart_sqlite3_register_vfs(x1,x2,x3),
      _1662: (x0,x1,x2,x3,x4,x5) => x0.dart_sqlite3_create_scalar_function(x1,x2,x3,x4,x5),
      _1665: x0 => x0.dart_sqlite3_updates,
      _1666: x0 => x0.dart_sqlite3_commits,
      _1667: x0 => x0.dart_sqlite3_rollbacks,
      _1671: x0 => ({initial: x0}),
      _1672: x0 => new WebAssembly.Memory(x0),
      _1673: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1673(f,arguments.length,x0) }),
      _1674: f => finalizeWrapper(f, function(x0,x1,x2,x3,x4) { return dartInstance.exports._1674(f,arguments.length,x0,x1,x2,x3,x4) }),
      _1675: f => finalizeWrapper(f, function(x0,x1,x2) { return dartInstance.exports._1675(f,arguments.length,x0,x1,x2) }),
      _1676: f => finalizeWrapper(f, function(x0,x1,x2,x3) { return dartInstance.exports._1676(f,arguments.length,x0,x1,x2,x3) }),
      _1677: f => finalizeWrapper(f, function(x0,x1,x2,x3) { return dartInstance.exports._1677(f,arguments.length,x0,x1,x2,x3) }),
      _1678: f => finalizeWrapper(f, function(x0,x1,x2) { return dartInstance.exports._1678(f,arguments.length,x0,x1,x2) }),
      _1679: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1679(f,arguments.length,x0,x1) }),
      _1680: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1680(f,arguments.length,x0,x1) }),
      _1681: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1681(f,arguments.length,x0) }),
      _1682: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1682(f,arguments.length,x0) }),
      _1683: f => finalizeWrapper(f, function(x0,x1,x2,x3) { return dartInstance.exports._1683(f,arguments.length,x0,x1,x2,x3) }),
      _1684: f => finalizeWrapper(f, function(x0,x1,x2,x3) { return dartInstance.exports._1684(f,arguments.length,x0,x1,x2,x3) }),
      _1685: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1685(f,arguments.length,x0,x1) }),
      _1686: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1686(f,arguments.length,x0,x1) }),
      _1687: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1687(f,arguments.length,x0,x1) }),
      _1688: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1688(f,arguments.length,x0,x1) }),
      _1689: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1689(f,arguments.length,x0,x1) }),
      _1690: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1690(f,arguments.length,x0,x1) }),
      _1691: f => finalizeWrapper(f, function(x0,x1,x2) { return dartInstance.exports._1691(f,arguments.length,x0,x1,x2) }),
      _1692: f => finalizeWrapper(f, function(x0,x1,x2) { return dartInstance.exports._1692(f,arguments.length,x0,x1,x2) }),
      _1693: f => finalizeWrapper(f, function(x0,x1,x2) { return dartInstance.exports._1693(f,arguments.length,x0,x1,x2) }),
      _1694: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1694(f,arguments.length,x0) }),
      _1695: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1695(f,arguments.length,x0) }),
      _1696: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1696(f,arguments.length,x0) }),
      _1697: f => finalizeWrapper(f, function(x0,x1,x2,x3,x4) { return dartInstance.exports._1697(f,arguments.length,x0,x1,x2,x3,x4) }),
      _1698: f => finalizeWrapper(f, function(x0,x1,x2,x3,x4) { return dartInstance.exports._1698(f,arguments.length,x0,x1,x2,x3,x4) }),
      _1699: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1699(f,arguments.length,x0) }),
      _1700: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1700(f,arguments.length,x0) }),
      _1701: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1701(f,arguments.length,x0,x1) }),
      _1702: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1702(f,arguments.length,x0,x1) }),
      _1703: f => finalizeWrapper(f, function(x0,x1,x2) { return dartInstance.exports._1703(f,arguments.length,x0,x1,x2) }),
      _1705: (x0,x1,x2,x3) => x0.call(x1,x2,x3),
      _1710: x0 => new URL(x0),
      _1711: (x0,x1) => new URL(x0,x1),
      _1712: (x0,x1) => globalThis.fetch(x0,x1),
      _1714: (x0,x1) => ({i: x0,p: x1}),
      _1715: (x0,x1) => ({c: x0,r: x1}),
      _1716: x0 => x0.i,
      _1717: x0 => x0.p,
      _1718: x0 => x0.c,
      _1719: x0 => x0.r,
      _1720: x0 => new SharedArrayBuffer(x0),
      _1721: x0 => ({at: x0}),
      _1722: x0 => x0.getSize(),
      _1723: (x0,x1) => x0.truncate(x1),
      _1724: x0 => x0.flush(),
      _1727: x0 => x0.synchronizationBuffer,
      _1728: x0 => x0.communicationBuffer,
      _1729: (x0,x1,x2,x3) => ({clientVersion: x0,root: x1,synchronizationBuffer: x2,communicationBuffer: x3}),
      _1730: (x0,x1) => globalThis.IDBKeyRange.bound(x0,x1),
      _1731: x0 => ({autoIncrement: x0}),
      _1732: (x0,x1,x2) => x0.createObjectStore(x1,x2),
      _1733: x0 => ({unique: x0}),
      _1734: (x0,x1,x2,x3) => x0.createIndex(x1,x2,x3),
      _1735: (x0,x1) => x0.createObjectStore(x1),
      _1736: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1736(f,arguments.length,x0) }),
      _1737: (x0,x1,x2) => x0.transaction(x1,x2),
      _1738: (x0,x1) => x0.objectStore(x1),
      _1740: (x0,x1) => x0.index(x1),
      _1741: x0 => x0.openKeyCursor(),
      _1742: (x0,x1) => x0.getKey(x1),
      _1743: (x0,x1) => ({name: x0,length: x1}),
      _1744: (x0,x1) => x0.put(x1),
      _1745: (x0,x1) => x0.get(x1),
      _1746: (x0,x1) => x0.openCursor(x1),
      _1747: x0 => globalThis.IDBKeyRange.only(x0),
      _1748: (x0,x1,x2) => x0.put(x1,x2),
      _1749: (x0,x1) => x0.update(x1),
      _1750: (x0,x1) => x0.delete(x1),
      _1751: x0 => x0.name,
      _1752: x0 => x0.length,
      _1755: x0 => globalThis.BigInt(x0),
      _1756: x0 => globalThis.Number(x0),
      _1763: () => globalThis.navigator,
      _1764: (x0,x1) => x0.read(x1),
      _1765: (x0,x1,x2) => x0.read(x1,x2),
      _1766: (x0,x1) => x0.write(x1),
      _1767: (x0,x1,x2) => x0.write(x1,x2),
      _1768: x0 => ({create: x0}),
      _1769: (x0,x1,x2) => x0.getDirectoryHandle(x1,x2),
      _1770: x0 => new BroadcastChannel(x0),
      _1771: x0 => globalThis.Array.isArray(x0),
      _1772: (x0,x1) => x0.postMessage(x1),
      _1773: x0 => x0.close(),
      _1774: (x0,x1) => ({kind: x0,table: x1}),
      _1775: x0 => x0.kind,
      _1776: x0 => x0.table,
      _1777: () => new AbortController(),
      _1778: x0 => x0.abort(),
      _1779: (x0,x1,x2,x3,x4,x5) => ({method: x0,headers: x1,body: x2,credentials: x3,redirect: x4,signal: x5}),
      _1780: (x0,x1) => globalThis.fetch(x0,x1),
      _1781: (x0,x1) => x0.get(x1),
      _1782: f => finalizeWrapper(f, function(x0,x1,x2) { return dartInstance.exports._1782(f,arguments.length,x0,x1,x2) }),
      _1783: (x0,x1) => x0.forEach(x1),
      _1784: x0 => x0.getReader(),
      _1785: x0 => x0.read(),
      _1786: x0 => x0.cancel(),
      _1787: () => new XMLHttpRequest(),
      _1788: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      _1789: x0 => x0.send(),
      _1792: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1792(f,arguments.length,x0) }),
      _1797: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1797(f,arguments.length,x0) }),
      _1798: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1798(f,arguments.length,x0) }),
      _1803: x0 => x0.exports,
      _1804: (x0,x1) => globalThis.WebAssembly.instantiateStreaming(x0,x1),
      _1805: x0 => x0.instance,
      _1807: x0 => x0.buffer,
      _1810: (x0,x1) => x0.appendChild(x1),
      _1811: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1811(f,arguments.length,x0) }),
      _1812: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1812(f,arguments.length,x0) }),
      _1813: x0 => x0.trustedTypes,
      _1814: (x0,x1) => { x0.src = x1 },
      _1815: (x0,x1) => x0.createScriptURL(x1),
      _1816: x0 => x0.nonce,
      _1817: (x0,x1) => x0.debug(x1),
      _1818: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1818(f,arguments.length,x0) }),
      _1819: x0 => ({createScriptURL: x0}),
      _1820: (x0,x1,x2) => x0.createPolicy(x1,x2),
      _1821: (x0,x1) => x0.querySelectorAll(x1),
      _1837: (x0,x1) => { x0.data = x1 },
      _1838: (x0,x1) => { x0.scale = x1 },
      _1839: (x0,x1) => { x0.canvasContext = x1 },
      _1840: (x0,x1) => { x0.viewport = x1 },
      _1841: (x0,x1) => { x0.annotationMode = x1 },
      _1842: (x0,x1) => { x0.offsetX = x1 },
      _1843: (x0,x1) => { x0.offsetY = x1 },
      _1844: (x0,x1) => { x0.password = x1 },
      _1845: x0 => x0.promise,
      _1846: x0 => x0.numPages,
      _1849: x0 => x0.width,
      _1851: x0 => x0.promise,
      _1852: (x0,x1) => x0.key(x1),
      _1862: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      _1863: (x0,x1) => x0.exec(x1),
      _1864: (x0,x1) => x0.test(x1),
      _1865: x0 => x0.pop(),
      _1867: o => o === undefined,
      _1869: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      _1871: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      _1872: o => o instanceof RegExp,
      _1873: (l, r) => l === r,
      _1874: o => o,
      _1875: o => o,
      _1876: o => o,
      _1877: b => !!b,
      _1878: o => o.length,
      _1880: (o, i) => o[i],
      _1881: f => f.dartFunction,
      _1882: () => ({}),
      _1883: () => [],
      _1885: () => globalThis,
      _1886: (constructor, args) => {
        const factoryFunction = constructor.bind.apply(
            constructor, [null, ...args]);
        return new factoryFunction();
      },
      _1887: (o, p) => p in o,
      _1888: (o, p) => o[p],
      _1889: (o, p, v) => o[p] = v,
      _1890: (o, m, a) => o[m].apply(o, a),
      _1892: o => String(o),
      _1893: (p, s, f) => p.then(s, (e) => f(e, e === undefined)),
      _1894: o => {
        if (o === undefined) return 1;
        var type = typeof o;
        if (type === 'boolean') return 2;
        if (type === 'number') return 3;
        if (type === 'string') return 4;
        if (o instanceof Array) return 5;
        if (ArrayBuffer.isView(o)) {
          if (o instanceof Int8Array) return 6;
          if (o instanceof Uint8Array) return 7;
          if (o instanceof Uint8ClampedArray) return 8;
          if (o instanceof Int16Array) return 9;
          if (o instanceof Uint16Array) return 10;
          if (o instanceof Int32Array) return 11;
          if (o instanceof Uint32Array) return 12;
          if (o instanceof Float32Array) return 13;
          if (o instanceof Float64Array) return 14;
          if (o instanceof DataView) return 15;
        }
        if (o instanceof ArrayBuffer) return 16;
        // Feature check for `SharedArrayBuffer` before doing a type-check.
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
            return 17;
        }
        return 18;
      },
      _1895: o => [o],
      _1896: (o0, o1) => [o0, o1],
      _1897: (o0, o1, o2) => [o0, o1, o2],
      _1898: (o0, o1, o2, o3) => [o0, o1, o2, o3],
      _1899: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI8ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _1900: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI8ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _1901: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI16ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _1902: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI16ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _1903: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _1904: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _1905: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _1906: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _1907: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF64ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _1908: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF64ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _1909: x0 => new ArrayBuffer(x0),
      _1910: s => {
        if (/[[\]{}()*+?.\\^$|]/.test(s)) {
            s = s.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
        }
        return s;
      },
      _1911: x0 => x0.input,
      _1912: x0 => x0.index,
      _1913: x0 => x0.groups,
      _1914: x0 => x0.flags,
      _1915: x0 => x0.multiline,
      _1916: x0 => x0.ignoreCase,
      _1917: x0 => x0.unicode,
      _1918: x0 => x0.dotAll,
      _1919: (x0,x1) => { x0.lastIndex = x1 },
      _1920: (o, p) => p in o,
      _1921: (o, p) => o[p],
      _1922: (o, p, v) => o[p] = v,
      _1924: (x0,x1,x2) => globalThis.Atomics.wait(x0,x1,x2),
      _1926: (x0,x1,x2) => globalThis.Atomics.notify(x0,x1,x2),
      _1927: (x0,x1,x2) => globalThis.Atomics.store(x0,x1,x2),
      _1928: (x0,x1) => globalThis.Atomics.load(x0,x1),
      _1929: () => globalThis.Int32Array,
      _1931: () => globalThis.Uint8Array,
      _1933: () => globalThis.DataView,
      _1935: x0 => x0.byteLength,
      _1936: x0 => x0.random(),
      _1937: (x0,x1) => x0.getRandomValues(x1),
      _1938: () => globalThis.crypto,
      _1939: () => globalThis.Math,
      _1940: Function.prototype.call.bind(Number.prototype.toString),
      _1941: Function.prototype.call.bind(BigInt.prototype.toString),
      _1942: Function.prototype.call.bind(Number.prototype.toString),
      _1943: (d, digits) => d.toFixed(digits),
      _1945: (d, f) => d.toExponential(f),
      _1952: () => globalThis.document,
      _1953: () => globalThis.window,
      _1958: (x0,x1) => { x0.height = x1 },
      _1960: (x0,x1) => { x0.width = x1 },
      _1963: x0 => x0.head,
      _1964: x0 => x0.classList,
      _1968: (x0,x1) => { x0.innerText = x1 },
      _1969: x0 => x0.style,
      _1971: x0 => x0.sheet,
      _1972: x0 => x0.src,
      _1973: (x0,x1) => { x0.src = x1 },
      _1974: x0 => x0.naturalWidth,
      _1975: x0 => x0.naturalHeight,
      _1982: x0 => x0.offsetX,
      _1983: x0 => x0.offsetY,
      _1984: x0 => x0.button,
      _1991: x0 => x0.status,
      _1992: (x0,x1) => { x0.responseType = x1 },
      _1994: x0 => x0.response,
      _1995: () => globalThis.google.accounts.oauth2,
      _1996: (x0,x1,x2) => x0.hasGrantedAllScopes(x1,x2),
      _2009: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._2009(f,arguments.length,x0) }),
      _2010: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._2010(f,arguments.length,x0) }),
      _2011: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9,x10) => ({client_id: x0,callback: x1,scope: x2,include_granted_scopes: x3,prompt: x4,enable_granular_consent: x5,enable_serial_consent: x6,login_hint: x7,hd: x8,state: x9,error_callback: x10}),
      _2012: x0 => x0.requestAccessToken(),
      _2015: x0 => x0.access_token,
      _2016: x0 => x0.expires_in,
      _2022: x0 => x0.error,
      _2023: x0 => x0.error_description,
      _2025: x0 => x0.type,
      _2026: x0 => x0.message,
      _2030: () => globalThis.google.accounts.id,
      _2035: (x0,x1) => x0.renderButton(x1),
      _2036: (x0,x1,x2) => x0.renderButton(x1,x2),
      _2044: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._2044(f,arguments.length,x0) }),
      _2047: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16) => ({client_id: x0,auto_select: x1,callback: x2,login_uri: x3,native_callback: x4,cancel_on_tap_outside: x5,prompt_parent_id: x6,nonce: x7,context: x8,state_cookie_domain: x9,ux_mode: x10,allowed_parent_origin: x11,intermediate_iframe_close_callback: x12,itp_support: x13,login_hint: x14,hd: x15,use_fedcm_for_prompt: x16}),
      _2058: x0 => x0.error,
      _2060: x0 => x0.credential,
      _2063: (x0,x1,x2,x3,x4,x5,x6,x7,x8) => ({type: x0,theme: x1,size: x2,text: x3,shape: x4,logo_alignment: x5,width: x6,locale: x7,click_listener: x8}),
      _2071: x0 => { globalThis.onGoogleLibraryLoad = x0 },
      _2072: f => finalizeWrapper(f, function() { return dartInstance.exports._2072(f,arguments.length) }),
      _2121: (x0,x1) => { x0.responseType = x1 },
      _2122: x0 => x0.response,
      _2182: (x0,x1) => { x0.draggable = x1 },
      _2198: x0 => x0.style,
      _2211: (x0,x1) => { x0.oncancel = x1 },
      _2217: (x0,x1) => { x0.onchange = x1 },
      _2257: (x0,x1) => { x0.onerror = x1 },
      _2397: (x0,x1) => { x0.nonce = x1 },
      _2557: (x0,x1) => { x0.download = x1 },
      _2582: (x0,x1) => { x0.href = x1 },
      _3124: (x0,x1) => { x0.accept = x1 },
      _3138: x0 => x0.files,
      _3164: (x0,x1) => { x0.multiple = x1 },
      _3182: (x0,x1) => { x0.type = x1 },
      _3432: (x0,x1) => { x0.src = x1 },
      _3438: (x0,x1) => { x0.async = x1 },
      _3440: (x0,x1) => { x0.defer = x1 },
      _3477: (x0,x1) => { x0.width = x1 },
      _3479: (x0,x1) => { x0.height = x1 },
      _3605: x0 => x0.data,
      _3898: () => globalThis.window,
      _3938: x0 => x0.document,
      _3941: x0 => x0.location,
      _3960: x0 => x0.navigator,
      _4222: x0 => x0.trustedTypes,
      _4224: x0 => x0.localStorage,
      _4232: x0 => x0.href,
      _4336: x0 => x0.maxTouchPoints,
      _4343: x0 => x0.appCodeName,
      _4344: x0 => x0.appName,
      _4345: x0 => x0.appVersion,
      _4346: x0 => x0.platform,
      _4347: x0 => x0.product,
      _4348: x0 => x0.productSub,
      _4349: x0 => x0.userAgent,
      _4350: x0 => x0.vendor,
      _4351: x0 => x0.vendorSub,
      _4353: x0 => x0.language,
      _4354: x0 => x0.languages,
      _4355: x0 => x0.onLine,
      _4360: x0 => x0.hardwareConcurrency,
      _4362: x0 => x0.storage,
      _4400: x0 => x0.data,
      _4430: x0 => x0.port1,
      _4431: x0 => x0.port2,
      _4433: (x0,x1) => { x0.onmessage = x1 },
      _4443: (x0,x1) => { x0.onmessage = x1 },
      _4511: x0 => x0.port,
      _4546: x0 => x0.length,
      _4763: x0 => x0.readyState,
      _4776: (x0,x1) => { x0.binaryType = x1 },
      _4779: x0 => x0.code,
      _4780: x0 => x0.reason,
      _6447: x0 => x0.type,
      _6448: x0 => x0.target,
      _6488: x0 => x0.signal,
      _6497: x0 => x0.length,
      _6518: x0 => x0.addedNodes,
      _6545: x0 => x0.firstChild,
      _6556: () => globalThis.document,
      _6637: x0 => x0.body,
      _6639: x0 => x0.head,
      _6968: (x0,x1) => { x0.id = x1 },
      _6995: x0 => x0.children,
      _7403: x0 => x0.ctrlKey,
      _7406: x0 => x0.metaKey,
      _7410: x0 => x0.keyCode,
      _8314: x0 => x0.value,
      _8316: x0 => x0.done,
      _8479: x0 => x0.size,
      _8480: x0 => x0.type,
      _8487: x0 => x0.name,
      _8488: x0 => x0.lastModified,
      _8493: x0 => x0.length,
      _8498: x0 => x0.result,
      _8989: x0 => x0.url,
      _8991: x0 => x0.status,
      _8993: x0 => x0.statusText,
      _8994: x0 => x0.headers,
      _8995: x0 => x0.body,
      _9352: x0 => x0.contentRect,
      _10439: x0 => x0.result,
      _10440: x0 => x0.error,
      _10451: (x0,x1) => { x0.onupgradeneeded = x1 },
      _10453: x0 => x0.oldVersion,
      _10532: x0 => x0.key,
      _10533: x0 => x0.primaryKey,
      _10535: x0 => x0.value,
      _11373: (x0,x1) => { x0.display = x1 },
      _12595: x0 => x0.name,
      _12926: x0 => x0.width,
      _12927: x0 => x0.height,
      _13311: () => globalThis.console,
      _13338: () => globalThis.speechSynthesis,
      _13339: (x0,x1) => { x0.lang = x1 },
      _13341: (x0,x1) => { x0.pitch = x1 },
      _13344: (x0,x1) => { x0.rate = x1 },
      _13346: (x0,x1) => { x0.text = x1 },
      _13347: (x0,x1) => { x0.voice = x1 },
      _13348: x0 => x0.voice,
      _13350: (x0,x1) => { x0.volume = x1 },
      _13351: (x0,x1) => { x0.onstart = x1 },
      _13352: (x0,x1) => { x0.onend = x1 },
      _13353: (x0,x1) => { x0.onpause = x1 },
      _13354: (x0,x1) => { x0.onresume = x1 },
      _13355: (x0,x1) => { x0.onerror = x1 },
      _13356: (x0,x1) => { x0.onboundary = x1 },
      _13358: x0 => x0.lang,
      _13359: x0 => x0.localService,
      _13360: x0 => x0.name,

    };

    const baseImports = {
      dart2wasm: dart2wasm,
      Math: Math,
      Date: Date,
      Object: Object,
      Array: Array,
      Reflect: Reflect,
      S: new Proxy({}, { get(_, prop) { return prop; } }),

    };

    const jsStringPolyfill = {
      "charCodeAt": (s, i) => s.charCodeAt(i),
      "compare": (s1, s2) => {
        if (s1 < s2) return -1;
        if (s1 > s2) return 1;
        return 0;
      },
      "concat": (s1, s2) => s1 + s2,
      "equals": (s1, s2) => s1 === s2,
      "fromCharCode": (i) => String.fromCharCode(i),
      "length": (s) => s.length,
      "substring": (s, a, b) => s.substring(a, b),
      "fromCharCodeArray": (a, start, end) => {
        if (end <= start) return '';

        const read = dartInstance.exports.$wasmI16ArrayGet;
        let result = '';
        let index = start;
        const chunkLength = Math.min(end - index, 500);
        let array = new Array(chunkLength);
        while (index < end) {
          const newChunkLength = Math.min(end - index, 500);
          for (let i = 0; i < newChunkLength; i++) {
            array[i] = read(a, index++);
          }
          if (newChunkLength < chunkLength) {
            array = array.slice(0, newChunkLength);
          }
          result += String.fromCharCode(...array);
        }
        return result;
      },
      "intoCharCodeArray": (s, a, start) => {
        if (s === '') return 0;

        const write = dartInstance.exports.$wasmI16ArraySet;
        for (var i = 0; i < s.length; ++i) {
          write(a, start++, s.charCodeAt(i));
        }
        return s.length;
      },
      "test": (s) => typeof s == "string",
    };


    

    dartInstance = await WebAssembly.instantiate(this.module, {
      ...baseImports,
      ...additionalImports,
      
      "wasm:js-string": jsStringPolyfill,
    });

    return new InstantiatedApp(this, dartInstance);
  }
}

class InstantiatedApp {
  constructor(compiledApp, instantiatedModule) {
    this.compiledApp = compiledApp;
    this.instantiatedModule = instantiatedModule;
  }

  // Call the main function with the given arguments.
  invokeMain(...args) {
    this.instantiatedModule.exports.$invokeMain(args);
  }
}
