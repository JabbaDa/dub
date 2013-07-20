/**	A package supplier using the registry server.	Copyright: © 2012 Matthias Dondorff	License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.	Authors: Matthias Dondorff*/module dub.registry;import dub.dependency;import dub.internal.vibecompat.core.file;import dub.internal.vibecompat.core.log;import dub.internal.vibecompat.data.json;import dub.internal.vibecompat.inet.url;import dub.packagesupplier;import dub.utils;import std.conv;import std.exception;import std.file;private const string PackagesPath = "packages";/// Client PackageSupplier using the registry available via registerVpmRegistryclass RegistryPS : PackageSupplier {	this(Url registry) { m_registryUrl = registry; }	override string toString() { return "registry at "~m_registryUrl.toString(); }		void retrievePackage(const Path path, const string packageId, const Dependency dep) {		Json best = getBestPackage(packageId, dep);		auto url = m_registryUrl ~ Path("packages/"~packageId~"/"~best["version"].get!string~".zip");		logDiagnostic("Found download URL: '%s'", url);		download(url, path);	}		Json getPackageDescription(const string packageId, const Dependency dep) {		return getBestPackage(packageId, dep);	}		private {		Url m_registryUrl;		Json[string] m_allMetadata;	}		private Json getMetadata(const string packageId) {		if( auto json = packageId in m_allMetadata ) 			return *json;		auto url = m_registryUrl ~ Path(PackagesPath ~ "/" ~ packageId ~ ".json");				logDebug("Downloading metadata for %s", packageId);		logDebug("Getting from %s", url);		auto jsonData = cast(string)download(url);		Json json = parseJson(jsonData);		m_allMetadata[packageId] = json;		return json;	}		private Json getBestPackage(const string packageId, const Dependency dep) {		Json md = getMetadata(packageId);		Json best = null;		foreach(json; md["versions"]) {			auto cur = Version(cast(string)json["version"]);			if(dep.matches(cur) && (best == null || Version(cast(string)best["version"]) < cur))				best = json;		}		enforce(best != null, "No package candidate found for "~packageId~" "~dep.toString());		return best;	}}