const path = require('path');
const fs = require('fs');
const fsPromises = fs.promises;
const csvParse = require('csv-parse/lib/sync')
const HTMLParser = require('node-html-parser');
const { https } = require('follow-redirects');
const retry = require('async-retry')
const glob = require("glob-promise")


// https://github.com/google/licenseclassifier/blob/842c0d70d7027215932deb13801890992c9ba364/license_type.go#L323
const RECIPROCAL_LICENSE_TYPES = ["APSL-1.0", "APSL-1.1", "APSL-1.2", "APSL-2.0", "CDDL-1.0", "CDDL-1.1", "CPL-1.0", "EPL-1.0", "FreeImage", "IPL-1.0", "MPL-1.0", "MPL-1.1", "MPL-2.0", "Ruby"];
const typesCanBeMergedWithoutCopyRight = ['MIT'];

const sortByModule = (a, b) => a.module.localeCompare(b.module);

const doesRequireSourceLink = (licenseType) => {
    return RECIPROCAL_LICENSE_TYPES.findIndex((type) => licenseType.startsWith(type)) !== -1;
}

const isLicenseFuzzyMatch = (licenseA, linceseB) => {
    return licenseA.replace(/\s/g, '') === linceseB.replace(/\s/g, '');
}

const moduleTemplate = (mod) => {
    return `
** ${mod.moduleOverride ?? mod.module}; version ${mod.version} --
${mod.repository}
`;
}

const noticeTemplate = (mod) => {
    if (!mod.noticeContent) return '';

    return `
* For ${mod.module} see also this required NOTICE:
${mod.noticeContent}
`
}

const copyrightsTemplate = (mod) => {
    let value = '';
    mod.copyrights.forEach((copyright) => {
        value += `${copyright}\n`
    });
    return value;
}

const sourceCodeTemplate = (mod) => {
    return `
    * Package ${mod.module}'s source code may be found at:
    ${mod.repository}/tree/${mod.version} 
`
}

const extractCopyRights = (license) => {
    license = license.replace(/(The |^)MIT License.*$/m, '');
    const matches = license.match(/(Copyright \([cC]\).*)/g);
    if (matches) {
        matches.forEach((match) => {
            license = license.replace(match, '');
        });
    }
    license = license.replace(/^ +/gm, '').trim();
    return { licenseContent: license, copyrights: matches };
}

const parseRepoURL = (repo, stripHttps = false) => {
    const parts = repo.split(' ');
    let repoURL = parts[parts.length - 1];

    // remove https prefix
    if (stripHttps && repoURL.startsWith('https://')) {
        repoURL = repoURL.substring(8);
    }
    // remove trailing .git
    if (repoURL.endsWith('.git')) {
        repoURL = repoURL.substring(0, repoURL.length - 4);
    }

    return repoURL;
}

const generateDependencyAttribution = (dep) => {
    let attributionOutput = '';
    if (!dep.module) {
        console.log("NOTICE: Missing module", dep);
    }
    else if (!dep.repository) {
        console.log("NOTICE: Missing repository", dep);
    }
    else if (!dep.licenseContent) {
        console.log("NOTICE: Missing licenseContent", dep);
    }
    else {
        if (!dep.version) {
            console.log("NOTICE: Missing version, check it out", dep.module);
            dep.version = 'v0.0.0';
        }
        attributionOutput += moduleTemplate(dep);

        if (doesRequireSourceLink(dep.licenseType)) {
            attributionOutput += sourceCodeTemplate(dep);
        }

        if (dep.copyrights) {
            attributionOutput += copyrightsTemplate(dep);
        }
    }
    return attributionOutput;
}

const cleanLicense = (fileName, licenseType, content) => {
    if (fileName !== 'README.txt' || licenseType != 'BSD-3-Clause') {
        return content;
    }

    // Some packages do not have license files.  go-license correctly finds the license
    // in the readme, but there is additional content that does not need to be in the attribution file
    // strip that out here
    const match = content.match(/Copyright.*DAMAGE\./s);
    if (match.length) {
        return match[0];
    }

    console.log("NOTICE: readme.txt did not match expect license regex. Check it out");
}

const fixEmptyModule = (dependencies) => {
    // some root packages come in as empty string from go-licenses
    dependencies.forEach((dep) => {
        if (dep.module === '') {
            dep.modulePath = rootModuleName;
            dep.module = rootModuleName;
        }
    });
    return dependencies;
}

async function addGoLicense(dependencies) {
    // go-licenses excludes the stdlib when pulling deps, adding the golang license to all to cover for this
    const goLicensePath = `https://github.com/golang/go/blob/${goLangVersion}/LICENSE`;
    dependencies.push({
        "module": "golang.org/go",
        "licensePath": goLicensePath,
        "licenseType": "BSD-3-Clause",
        "version": `${goLangVersion}`,
        "modulePath": "golang.org/go",
        "repository": "https://github.com/golang/go",
        "licenseContent": await readLicenseFromUpstream(`${goLicensePath}?raw=true`)
    });
    return dependencies;
}

async function readLicenseFromUpstream(upstreamUrl) {
    let finalDoc = '';
    const options = await generateAuthorizationHeader()
    options.timeout = 15 * 1000
    return new Promise((resolve, reject) => {
        const req = https.get(upstreamUrl, options, res => {
            res.on('data', d => {
                finalDoc += d;
            })
            res.on('end', () => {
                resolve(finalDoc);
            });
        });

        req.on('error', (err) => {
            reject(err);
        });
        req.end();
    });
}


async function getPackageRepo(package) {
    let finalDoc = '';
    const url = `https://${package}?go-get=1`
    const options = await generateAuthorizationHeader()
    options.timeout = 15 * 1000
    return new Promise((resolve, reject) => {
        const req = https.get(url, options, res => {
            if (res.statusCode !== 200) {
                if (package.startsWith('github.com')) {
                    // This is probably happening because github doesnt seem to return the go-import for sub packages
                    return resolve(parseRepoURL(`https://${package}`));
                }
                console.log('NOTICE: request to get package url return invalid response', res.statusCode, url);
                resolve(`https://${package}`)
            }
            res.on('data', d => {
                finalDoc += d;
            })
            res.on('end', () => {
                const htmlDoc = HTMLParser.parse(finalDoc);
                const metaTag = htmlDoc.querySelector('head meta[name=go-import]')
                if (metaTag) {
                    resolve(parseRepoURL(metaTag.getAttribute('content')));
                }
                else {
                    resolve(`https://${package}`)
                }

            });
        })

        req.on('error', (err) => {
            reject(err);
        });
        req.end();
    });
}

async function readLicenseContent(dep, depLicensesDirPath) {
    const possiblePaths = [];

    if (dep.licensePath !== 'Unknown') {
        const licensePathFromGoLicenseOutput = path.join(depLicensesDirPath, path.basename(dep.licensePath));
        possiblePaths.push(licensePathFromGoLicenseOutput);
    }

    const files = await glob('LICEN+(S|C)E?(.md|.txt)', {cwd: depLicensesDirPath, nocase: true})
    
    files.forEach((file) => {
        possiblePaths.push(path.join(depLicensesDirPath, file));
    });

    for (let i = 0; i < possiblePaths.length; i++) {
        const possiblePath = possiblePaths[i];
        try {
            await fsPromises.access(possiblePath);
            const licenseText = await fsPromises.readFile(possiblePath, 'utf8');
            return cleanLicense(path.basename(possiblePath), dep.licenseType, licenseText);
        } catch { }
    }

    console.log('No license file for', dep);
    process.exit(1);
}

async function readNoticeFile(depLicensesDirPath) {
    const noticePath = path.join(depLicensesDirPath, 'NOTICE');
    try {
        await fsPromises.access(noticePath);
        return await fsPromises.readFile(noticePath, 'utf8');
    } catch { }
}

async function parseCSV() {
    const csvFilePath = path.join(projectAttributionDirectory, 'go-license.csv');
    const csvContent = await fsPromises.readFile(csvFilePath, 'utf8');
    const dependencies = csvParse(csvContent, {
        columns: ['module', 'licensePath', 'licenseType']
    });
    return dependencies;
}

async function populateVersionAndModuleFromDep(dependencies) {
    const goListDepFilePath = path.join(projectAttributionDirectory, 'go-deps.json');
    const goListDepFileContent = await fsPromises.readFile(goListDepFilePath, 'utf8');
    const goListDeps = JSON.parse(goListDepFileContent);

    const isModuleMatch = (dep, goListDep, allowPrefixMatch = false) => {
        if (!goListDep.Module) return false;
        return dep.module === goListDep.Module.Path ||
            dep.module === goListDep.ImportPath ||
            dep.module.startsWith(`${goListDep.Module.Path}/pkg`) ||
            (allowPrefixMatch && dep.module.startsWith(goListDep.Module.Path))
    }

    const getDepVersion = (goListDep) => {
        return goListDep.Module.Replace?.Version ?? goListDep.Module.Version;
    }

    const isVersionMismatch = (depVersion, goDepVersion) => {
        if (!depVersion || !goDepVersion) {
            return false;
        }
        return depVersion !== goDepVersion;
    }

    const isPathMismatch = (dep, goListDep) => {
        return dep.modulePath !== goListDep.Module.Path &&
            dep.modulePath !== goListDep.Module.Replace?.Path;
    }

    const isRelativePath = (path) => {
        if (!path) return false;
        return path.startsWith('./') || path.startsWith('../');
    }

    const useReplacePath = (goListDep) => {
        // some replace paths end up being local to the repo
        // and start with ./ in that case leave the module alone
        // otherwise the replace module path is more accurate
        return goListDep.Module.Replace?.Path &&
            !isRelativePath(goListDep.Module.Replace?.Path) &&
            goListDep.Module.Replace.Path !== goListDep.Module.Path;
    }

    const handleFound = (dep, goListDep, found) => {
        const goDepVersion = getDepVersion(goListDep);
        const bothVersionsUndef = dep.Version ?? goDepVersion;
        if (found &&
            (
                isVersionMismatch(dep.version, goDepVersion) ||
                isPathMismatch(dep, goListDep)
            )
        ) {
            console.log("NOTICE: Dep matched go list more than once.  Check it out", dep, goListDep)
        }
        dep.version ??= goDepVersion
        dep.modulePath = useReplacePath(goListDep) ? goListDep.Module.Replace.Path : goListDep.Module.Path;
        dep.moduleOverride = useReplacePath(goListDep) ? goListDep.Module.Replace.Path : goListDep.module;
    }

    const finalDeps = [];
    dependencies.forEach((dep) => {
        let found = false;
        if (dep.version) {
            // the package itself which was added using the GIT_TAG
            finalDeps.push(dep);
            return;
        }

        goListDeps.forEach((goListDep) => {
            if (isModuleMatch(dep, goListDep)) {
                handleFound(dep, goListDep, found);
                found = true;
            }
        });

        if (!found) {
            let match;
            goListDeps.forEach((goListDep) => {
                // these matches were found by the prefix match above
                // find the longest prefix and use that as our module
                if (isModuleMatch(dep, goListDep, true)) {
                    if (!match || goListDep.Module.Path.length > match.Module.Path.length) {
                        match = goListDep;
                    }                
                }
            });
            if (match) {
                handleFound(dep, match, found);
                found = true;
            }
        }

        if (!found) {
            console.log("ERROR: Dep from go-license.csv was not found. Check it out", dep);
            process.exit(1);
        }
        else {
            finalDeps.push(dep);
        }
    });
    return finalDeps;
}

async function generateAuthorizationHeader() {
    if (process.env.GITHUB_TOKEN) {
        return { headers: { 'Authorization': 'token ' + process.env.GITHUB_TOKEN } };
    }

    const githubTokenFile = "/secrets/github-secrets/token";
    try {
        await fsPromises.access(githubTokenFile);
        const githubToken = await fsPromises.readFile(githubTokenFile, 'utf8');
        const options = {
            headers: {
                'Authorization': 'token ' + githubToken
            }
        };
        return options;
    } catch {
        return {};
    }
}

async function populateRootComponentVersion(dependencies) {
    const version = await fsPromises.readFile(gitTagPath, 'utf8');
    dependencies.forEach((dep) => {
        if (dep.modulePath.startsWith(rootModuleName) && !dep.version) {
            dep.version = version.trim();
        }
    });
    return dependencies;
}

async function populateLicenseAndNoticeContent(dependencies) {
    // For the apache license we can hardcode this since it is supposed to be unedited
    const officialApacheLicensePath = path.join(__dirname, 'LICENSE-2.0.txt');
    const officialApacheLicense = await fsPromises.readFile(officialApacheLicensePath, 'utf-8');

    for (let i = 0; i < dependencies.length; i++) {
        const dep = dependencies[i];
        const depLicensesDirPath = path.join(projectLicensesDirectory, dep.module);

        if (!dep.modulePath) {
            console.log("Dep has no module path", dep);
            process.exit(1);
        }

        if (dep.licenseType === 'Apache-2.0') {
            dep.licenseContent = officialApacheLicense;
        } else {
            dep.licenseContent = await readLicenseContent(dep, depLicensesDirPath);
        }

        dep.noticeContent = await readNoticeFile(depLicensesDirPath);
    }

    return dependencies;
}

async function populateRepoURLs(dependencies) {
    for (let i = 0; i < dependencies.length; i++) {
        const dep = dependencies[i];
        try {
            dep.repository = await retry(getPackageRepo.bind(null, dep.modulePath), { retries: 5 });
        } catch (e) {
            console.log('NOTICE: error pulling package repo double check result for', dep.modulePath, e);
            dep.repository = `https://${dep.modulePath}`;
        }
    }
    return dependencies
}

async function groupByLicense(dependencies) {
    const uniqLicenses = {};
    const sortedDeps = dependencies.sort(sortByModule);
    sortedDeps.forEach(function (dep) {
        const canBeMerged = typesCanBeMergedWithoutCopyRight.indexOf(dep.licenseType) !== -1;
        if (canBeMerged) {
            // If the differnce in content is only the copyright we can merge them into the same group
            const { licenseContent, copyrights } = extractCopyRights(dep.licenseContent);
            dep.copyrights = copyrights;
            dep.licenseContent = licenseContent;
        }

        let uniqueLicense = Object.entries(uniqLicenses)
            .find(([licenseType, { licenseContent }]) => {
                return (canBeMerged && isLicenseFuzzyMatch(dep.licenseContent, licenseContent)) ||
                    (dep.licenseContent === licenseContent)
            });
        let type = uniqueLicense ? uniqueLicense[0] : dep.licenseType;
        if (!uniqueLicense) {
            if (uniqLicenses[type]) {
                // Same license type but different content, jsut add module name to type to factor in for sorting later
                type = `${dep.licenseType}+${dep.module}`
            }
            uniqLicenses[type] = { licenseContent: dep.licenseContent, deps: [] };
        }
        uniqLicenses[type].deps.push(dep);
    });

    return uniqLicenses;
}

async function generateAttribution(dependenciesByLicenseType) {
    let attributionOutput = '';
    let summaryOutput = '';

    const sortedLicenseTypes = Object.keys(dependenciesByLicenseType).sort((a, b) => a.localeCompare(b));
    sortedLicenseTypes.forEach((licenseType) => {
        const { deps, licenseContent } = dependenciesByLicenseType[licenseType];
        const sortedDeps = deps.sort(sortByModule);
        const requiresSourceCodeLink = doesRequireSourceLink(licenseType);

        sortedDeps.forEach(function (dep) {
            attributionOutput += generateDependencyAttribution(dep);
        });

        attributionOutput += "\n" + licenseContent + "\n";

        sortedDeps.forEach(function (dep) {
            attributionOutput += noticeTemplate(dep);
        });

        attributionOutput += "\------\n";
        summaryOutput += `${licenseType} => ${sortedDeps.length}\n`
    });

    await fsPromises.writeFile(path.join(projectAttributionDirectory, "summary.txt"), summaryOutput);
    return fsPromises.writeFile(path.join(projectAttributionDirectory, "ATTRIBUTION.txt"), attributionOutput);
}


async function execute() {

    parseCSV()
        .then(fixEmptyModule)
        .then(populateVersionAndModuleFromDep)
        .then(populateRootComponentVersion)
        .then(populateLicenseAndNoticeContent)
        .then(populateRepoURLs)
        .then(addGoLicense)
        .then(groupByLicense)
        .then(generateAttribution)
}

const rootModuleName = parseRepoURL(process.argv[2], true);
const projectDirectory = process.argv[3];
const goLangVersion = process.argv[4];
const projectOutputDirectory = process.argv[5];

const gitTagPath = path.join(projectDirectory, 'GIT_TAG');
const projectLicensesDirectory = path.join(projectOutputDirectory, "LICENSES");
const projectAttributionDirectory = path.join(projectOutputDirectory, "attribution");


execute();
